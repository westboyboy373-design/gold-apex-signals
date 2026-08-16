import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class VerifyPaymentsTab extends StatelessWidget {
  const VerifyPaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pending = app.paymentRequests.where((p) => !p.approved).toList();
    final approved = app.paymentRequests.where((p) => p.approved).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Pending (${pending.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        if (pending.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No pending payments.', style: TextStyle(color: AppColors.textMuted)),
          ),
        ...pending.map((p) => _paymentCard(context, p)),
        const SizedBox(height: 24),
        Text('Approved (${approved.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        ...approved.map((p) => _paymentCard(context, p)),
      ],
    );
  }

  Widget _paymentCard(BuildContext context, PaymentRequest p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(p.referenceId, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold, letterSpacing: 0.5)),
                ),
                if (p.approved) const Icon(Icons.check_circle, color: AppColors.buy, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text('${p.username} · ${p.planType.label} · ${formatUgx(p.amountUgx)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text(timeAgo(p.createdAt), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            if (!p.approved) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await context.read<AppState>().rejectPayment(p);
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await context.read<AppState>().approvePayment(p);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('${p.referenceId} approved & activated.')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Approval failed: $e')));
                          }
                        }
                      },
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
