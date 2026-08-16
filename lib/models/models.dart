enum SignalDirection { buy, sell }

enum SignalStatus { active, hitTp, hitSl, closed }

enum PlanType { none, single, fiveDay, monthly, threeMonth, lifetime }

extension PlanTypeX on PlanType {
  /// The reference-ID prefix the app generates for this plan, so the admin
  /// can identify what a customer paid for at a glance.
  String get idPrefix {
    switch (this) {
      case PlanType.fiveDay:
        return '5DAYS';
      case PlanType.monthly:
        return 'MONTHLY';
      case PlanType.threeMonth:
        return '3MONTHS';
      case PlanType.lifetime:
        return 'LIFETIME';
      case PlanType.single:
        return 'STRAIGHT';
      case PlanType.none:
        return 'NONE';
    }
  }

  String get label {
    switch (this) {
      case PlanType.fiveDay:
        return '5-Day Pass';
      case PlanType.monthly:
        return 'Monthly Pass';
      case PlanType.threeMonth:
        return '3-Month Pass';
      case PlanType.lifetime:
        return 'Lifetime Pass';
      case PlanType.single:
        return 'Single Signal Unlock';
      case PlanType.none:
        return 'No Active Plan';
    }
  }

  int get priceUgx {
    switch (this) {
      case PlanType.fiveDay:
        return 10000;
      case PlanType.monthly:
        return 28000;
      case PlanType.threeMonth:
        return 84000;
      case PlanType.lifetime:
        return 200000;
      case PlanType.single:
        return 2000;
      case PlanType.none:
        return 0;
    }
  }

  Duration? get duration {
    switch (this) {
      case PlanType.fiveDay:
        return const Duration(days: 5);
      case PlanType.monthly:
        return const Duration(days: 28);
      case PlanType.threeMonth:
        return const Duration(days: 90);
      case PlanType.lifetime:
        return null; // never expires
      case PlanType.single:
      case PlanType.none:
        return null;
    }
  }

  /// Matches the plain-text values stored in the `plan_type` / `active_plan`
  /// Postgres columns (see supabase/schema.sql).
  String get dbValue => name;

  static PlanType fromDb(String? value) {
    return PlanType.values.firstWhere((p) => p.name == value, orElse: () => PlanType.none);
  }
}

extension SignalDirectionX on SignalDirection {
  String get dbValue => name;
  static SignalDirection fromDb(String value) => value == 'sell' ? SignalDirection.sell : SignalDirection.buy;
}

extension SignalStatusX on SignalStatus {
  String get dbValue => name;
  static SignalStatus fromDb(String value) =>
      SignalStatus.values.firstWhere((s) => s.name == value, orElse: () => SignalStatus.active);
}

class TradingSignal {
  final String id;
  final String pair;
  final SignalDirection direction;
  final double entry;
  final double stopLoss;
  final double takeProfit;
  final String timeframe;
  final String riskLevel;
  final String analysis;
  final String? imageUrl;
  SignalStatus status;
  final String postedByAdmin;
  final DateTime postedAt;

  /// Fixed unlock cost in coins.
  static const int coinCost = 50;

  TradingSignal({
    required this.id,
    required this.pair,
    required this.direction,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit,
    required this.timeframe,
    required this.riskLevel,
    required this.analysis,
    this.imageUrl,
    this.status = SignalStatus.active,
    required this.postedByAdmin,
    required this.postedAt,
  });

  factory TradingSignal.fromRow(Map<String, dynamic> row, {String postedByUsername = 'admin'}) {
    return TradingSignal(
      id: row['id'] as String,
      pair: row['pair'] as String,
      direction: SignalDirectionX.fromDb(row['direction'] as String),
      entry: (row['entry'] as num).toDouble(),
      stopLoss: (row['stop_loss'] as num).toDouble(),
      takeProfit: (row['take_profit'] as num).toDouble(),
      timeframe: row['timeframe'] as String,
      riskLevel: row['risk_level'] as String,
      analysis: row['analysis'] as String,
      imageUrl: row['image_url'] as String?,
      status: SignalStatusX.fromDb(row['status'] as String),
      postedByAdmin: postedByUsername,
      postedAt: DateTime.parse(row['posted_at'] as String),
    );
  }

  Map<String, dynamic> toInsertRow({required String postedById}) {
    return {
      'pair': pair,
      'direction': direction.dbValue,
      'entry': entry,
      'stop_loss': stopLoss,
      'take_profit': takeProfit,
      'timeframe': timeframe,
      'risk_level': riskLevel,
      'analysis': analysis,
      'image_url': imageUrl,
      'status': status.dbValue,
      'posted_by': postedById,
    };
  }
}

class PaymentRequest {
  final String id;
  final String referenceId;
  final String userId;
  final String username;
  final PlanType planType;
  final int amountUgx;
  final DateTime createdAt;
  bool approved;
  final bool rejected;

  PaymentRequest({
    required this.id,
    required this.referenceId,
    required this.userId,
    required this.username,
    required this.planType,
    required this.amountUgx,
    required this.createdAt,
    this.approved = false,
    this.rejected = false,
  });

  factory PaymentRequest.fromRow(Map<String, dynamic> row, {String username = 'user'}) {
    return PaymentRequest(
      id: row['id'] as String,
      referenceId: row['reference_id'] as String,
      userId: row['user_id'] as String,
      username: username,
      planType: PlanTypeX.fromDb(row['plan_type'] as String),
      amountUgx: (row['amount_ugx'] as num).toInt(),
      createdAt: DateTime.parse(row['created_at'] as String),
      approved: row['status'] == 'approved',
      rejected: row['status'] == 'rejected',
    );
  }
}

class AdminAccount {
  final String id;
  final String username;
  final bool isPrimary;

  AdminAccount({required this.id, required this.username, this.isPrimary = false});
}
