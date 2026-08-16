import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// The WhatsApp number payments/proof-of-payment are sent to.
/// TODO: move to a remote config value if this ever needs to change without
/// a fresh app release.
const String kWhatsAppNumber = '256761448094';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & Plans')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _WalletSummaryCard(app: app),
          const SizedBox(height: 24),
          const Text('Membership Plans', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Time-based plans unlock every signal automatically for the duration you pay for.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _PlanTile(plan: PlanType.fiveDay, highlight: false),
          _PlanTile(plan: PlanType.monthly, highlight: true),
          _PlanTile(plan: PlanType.threeMonth, highlight: false),
          _PlanTile(plan: PlanType.lifetime, highlight: false),
          const SizedBox(height: 20),
          const Text('Or Unlock a Single Signal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'No package needed — pay per signal and top up your coin balance directly.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _PlanTile(plan: PlanType.single, highlight: false),
          const SizedBox(height: 28),
          if (app.latestPendingReferenceId != null) _PendingBanner(refId: app.latestPendingReferenceId!),
        ],
      ),
    );
  }
}

class _WalletSummaryCard extends StatelessWidget {
  final AppState app;
  const _WalletSummaryCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on, color: AppColors.gold, size: 28),
                const SizedBox(width: 10),
                Text('${app.coinsBalance} coins', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              app.hasActivePlan
                  ? '${app.activePlan.label} active${app.activePlan == PlanType.lifetime ? '' : ' · expires ${_fmtDate(app.planExpiry!)}'}'
                  : 'No active plan — unlocking signals costs 50 coins each',
              style: TextStyle(color: app.hasActivePlan ? AppColors.gold : AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _PlanTile extends StatelessWidget {
  final PlanType plan;
  final bool highlight;
  const _PlanTile({required this.plan, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: highlight ? AppColors.gold : AppColors.border, width: highlight ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      if (highlight) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(4)),
                          child: const Text('POPULAR', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(formatUgx(plan.priceUgx), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _startPurchase(context, plan),
              child: const Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }

  void _startPurchase(BuildContext context, PlanType plan) async {
    final app = context.read<AppState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
    );

    try {
      await app.submitPaymentRequest(plan);
    } finally {
      if (context.mounted) Navigator.pop(context); // close the spinner
    }

    final refId = app.latestPendingReferenceId;
    if (refId == null || !context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentInstructionsSheet(plan: plan, referenceId: refId),
    );
  }
}

class _PaymentInstructionsSheet extends StatelessWidget {
  final PlanType plan;
  final String referenceId;
  const _PaymentInstructionsSheet({required this.plan, required this.referenceId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Complete Your Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('${plan.label} · ${formatUgx(plan.priceUgx)}', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Reference ID', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                Text(referenceId, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppColors.gold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Send your payment plus a screenshot of this Reference ID to our WhatsApp number below. '
            'Your account will be activated as soon as an admin verifies the payment.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.chat, size: 18),
              label: Text('Message WhatsApp ($kWhatsAppNumber)'),
              onPressed: () => _openWhatsApp(referenceId, plan),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(String refId, PlanType plan) async {
    final message = Uri.encodeComponent(
      'Hi, I want to activate my $kWhatsAppNumber wallet.\n'
      'Plan: ${plan.label}\n'
      'Amount: ${formatUgx(plan.priceUgx)}\n'
      'Reference ID: $refId\n'
      '(Payment screenshot attached)',
    );
    final uri = Uri.parse('https://wa.me/$kWhatsAppNumber?text=$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _PendingBanner extends StatelessWidget {
  final String refId;
  const _PendingBanner({required this.refId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Payment pending verification for reference $refId. This activates once an admin approves it.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
