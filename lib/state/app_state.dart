import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/supabase_client.dart';

/// Single source of truth for the app, now backed by Supabase.
///
/// Call [initialize] once there's an authenticated session (see AuthGate),
/// and [dispose] handles tearing down the realtime subscription.
class AppState extends ChangeNotifier {
  String? currentUserId;
  String currentUsername = '';
  int coinsBalance = 0;
  PlanType activePlan = PlanType.none;
  DateTime? planExpiry;
  final Set<String> unlockedSignalIds = {};

  final List<TradingSignal> signals = [];
  final List<PaymentRequest> paymentRequests = [];
  final List<AdminAccount> admins = [];

  bool loading = false;

  final Random _rng = Random();
  StreamSubscription<List<Map<String, dynamic>>>? _signalsSub;

  bool get isAdmin => currentUserId != null && admins.any((a) => a.id == currentUserId);

  bool get hasActivePlan {
    if (activePlan == PlanType.none) return false;
    if (activePlan == PlanType.lifetime) return true;
    if (planExpiry == null) return false;
    return DateTime.now().isBefore(planExpiry!);
  }

  bool isUnlocked(TradingSignal s) => hasActivePlan || unlockedSignalIds.contains(s.id);

  // ---- Bootstrapping ----

  Future<void> initialize() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    currentUserId = user.id;

    loading = true;
    notifyListeners();

    await Future.wait([
      _loadProfile(),
      _loadAdmins(),
    ]);
    await Future.wait([
      _loadSignalsOnce(),
      _loadMyUnlocks(),
      _loadPaymentRequests(),
    ]);

    _subscribeToSignals();

    loading = false;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final row = await supabase.from('users').select().eq('id', currentUserId!).single();
    currentUsername = row['username'] as String;
    coinsBalance = (row['coins_balance'] as num).toInt();
    activePlan = PlanTypeX.fromDb(row['active_plan'] as String?);
    planExpiry = row['plan_expiry'] == null ? null : DateTime.parse(row['plan_expiry'] as String);
  }

  Future<void> _loadAdmins() async {
    final rows = await supabase.from('admins').select('user_id, is_primary, users(username)');
    admins
      ..clear()
      ..addAll(rows.map((r) => AdminAccount(
            id: r['user_id'] as String,
            username: (r['users']?['username'] as String?) ?? 'unknown',
            isPrimary: r['is_primary'] as bool? ?? false,
          )));
  }

  String _usernameFor(String? userId) {
    if (userId == null) return 'admin';
    final match = admins.where((a) => a.id == userId);
    if (match.isNotEmpty) return match.first.username;
    return userId == currentUserId ? currentUsername : 'admin';
  }

  Future<void> _loadSignalsOnce() async {
    final rows = await supabase.from('signals').select().order('posted_at', ascending: false);
    signals
      ..clear()
      ..addAll(rows.map((r) => TradingSignal.fromRow(r, postedByUsername: _usernameFor(r['posted_by'] as String?))));
  }

  void _subscribeToSignals() {
    _signalsSub?.cancel();
    _signalsSub = supabase
        .from('signals')
        .stream(primaryKey: ['id'])
        .order('posted_at', ascending: false)
        .listen((rows) {
      signals
        ..clear()
        ..addAll(rows.map((r) => TradingSignal.fromRow(r, postedByUsername: _usernameFor(r['posted_by'] as String?))));
      notifyListeners();
    });
  }

  Future<void> _loadMyUnlocks() async {
    final rows = await supabase.from('unlocks').select('signal_id').eq('user_id', currentUserId!);
    unlockedSignalIds
      ..clear()
      ..addAll(rows.map((r) => r['signal_id'] as String));
  }

  Future<void> _loadPaymentRequests() async {
    if (isAdmin) {
      final rows = await supabase.from('payment_requests').select('*, users(username)').order('created_at', ascending: false);
      paymentRequests
        ..clear()
        ..addAll(rows.map((r) => PaymentRequest.fromRow(r, username: (r['users']?['username'] as String?) ?? 'user')));
    } else {
      final rows = await supabase
          .from('payment_requests')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);
      paymentRequests
        ..clear()
        ..addAll(rows.map((r) => PaymentRequest.fromRow(r, username: currentUsername)));
    }
  }

  @override
  void dispose() {
    _signalsSub?.cancel();
    super.dispose();
  }

  // ---- Wallet / unlocking ----

  /// Returns true if unlock succeeded (had enough coins or an active plan).
  Future<bool> unlockSignal(TradingSignal signal) async {
    if (isUnlocked(signal)) return true;
    if (hasActivePlan) {
      unlockedSignalIds.add(signal.id);
      notifyListeners();
      await supabase.from('unlocks').insert({'user_id': currentUserId, 'signal_id': signal.id});
      return true;
    }
    if (coinsBalance < TradingSignal.coinCost) return false;

    // NOTE: for production, move this to a Postgres RPC (e.g. `unlock_signal`)
    // that decrements coins and inserts the unlock row atomically, to avoid
    // race conditions from concurrent taps. Fine for a single-user demo flow.
    coinsBalance -= TradingSignal.coinCost;
    unlockedSignalIds.add(signal.id);
    notifyListeners();

    await supabase.from('unlocks').insert({'user_id': currentUserId, 'signal_id': signal.id});
    await supabase.from('users').update({'coins_balance': coinsBalance}).eq('id', currentUserId!);
    return true;
  }

  /// Generates a reference ID like `5DAYS482913` for the given plan, tied to
  /// the current user, so an admin can identify the plan + payer at a glance.
  String generateReferenceId(PlanType plan) {
    final suffix = (100000 + _rng.nextInt(899999)).toString();
    return '${plan.idPrefix}$suffix';
  }

  Future<void> submitPaymentRequest(PlanType plan) async {
    final refId = generateReferenceId(plan);
    final row = await supabase
        .from('payment_requests')
        .insert({
          'user_id': currentUserId,
          'reference_id': refId,
          'plan_type': plan.dbValue,
          'amount_ugx': plan.priceUgx,
        })
        .select()
        .single();
    paymentRequests.insert(0, PaymentRequest.fromRow(row, username: currentUsername));
    notifyListeners();
  }

  String? get latestPendingReferenceId {
    final pending = paymentRequests.where((p) => !p.approved && !p.rejected && p.username == currentUsername);
    return pending.isEmpty ? null : pending.first.referenceId;
  }

  // ---- Admin actions ----

  Future<void> approvePayment(PaymentRequest request) async {
    await supabase.from('payment_requests').update({'status': 'approved'}).eq('id', request.id);

    final updates = <String, dynamic>{};
    if (request.planType == PlanType.single) {
      // credit the payer's coin balance
      final row = await supabase.from('users').select('coins_balance').eq('id', request.userId).single();
      final newBalance = (row['coins_balance'] as num).toInt() + TradingSignal.coinCost;
      updates['coins_balance'] = newBalance;
    } else {
      updates['active_plan'] = request.planType.dbValue;
      final d = request.planType.duration;
      updates['plan_expiry'] = d == null ? null : DateTime.now().add(d).toIso8601String();
    }
    await supabase.from('users').update(updates).eq('id', request.userId);

    request.approved = true;
    if (request.userId == currentUserId) {
      await _loadProfile();
    }
    notifyListeners();
  }

  Future<void> rejectPayment(PaymentRequest request) async {
    await supabase.from('payment_requests').update({'status': 'rejected'}).eq('id', request.id);
    paymentRequests.remove(request);
    notifyListeners();
  }

  Future<void> postSignal(TradingSignal signal) async {
    await supabase.from('signals').insert(signal.toInsertRow(postedById: currentUserId!));
    // Realtime subscription will push the new row in; no local insert needed.
  }

  Future<void> updateSignalStatus(TradingSignal signal, SignalStatus status) async {
    await supabase.from('signals').update({'status': status.dbValue}).eq('id', signal.id);
  }

  Future<void> deleteSignal(TradingSignal signal) async {
    await supabase.from('signals').delete().eq('id', signal.id);
  }

  Future<String?> addAdmin(String username) async {
    final matches = await supabase.from('users').select('id').eq('username', username).limit(1);
    if (matches.isEmpty) return 'No user found with username "$username".';
    final userId = matches.first['id'] as String;
    if (admins.any((a) => a.id == userId)) return '$username is already an admin.';

    await supabase.from('admins').insert({'user_id': userId, 'added_by': currentUserId});
    await supabase.from('users').update({'is_admin': true}).eq('id', userId);
    await _loadAdmins();
    notifyListeners();
    return null; // success
  }

  Future<void> removeAdmin(AdminAccount admin) async {
    if (admin.isPrimary) return; // primary admin can't be removed
    await supabase.from('admins').delete().eq('user_id', admin.id);
    await supabase.from('users').update({'is_admin': false}).eq('id', admin.id);
    admins.remove(admin);
    notifyListeners();
  }

  // ---- Performance stats (public track record) ----

  int get totalClosedSignals =>
      signals.where((s) => s.status == SignalStatus.hitTp || s.status == SignalStatus.hitSl).length;

  double get winRate {
    final closed = totalClosedSignals;
    if (closed == 0) return 0;
    final wins = signals.where((s) => s.status == SignalStatus.hitTp).length;
    return wins / closed;
  }
}
