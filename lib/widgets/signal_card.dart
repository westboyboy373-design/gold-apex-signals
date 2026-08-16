import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'blur_lock_overlay.dart';

class SignalCard extends StatelessWidget {
  final TradingSignal signal;
  final VoidCallback onTap;
  final VoidCallback onUnlockRequested;

  const SignalCard({
    super.key,
    required this.signal,
    required this.onTap,
    required this.onUnlockRequested,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final unlocked = app.isUnlocked(signal);
    final isBuy = signal.direction == SignalDirection.buy;
    final directionColor = isBuy ? AppColors.buy : AppColors.sell;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: directionColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isBuy ? 'BUY' : 'SELL',
                      style: TextStyle(color: directionColor, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(signal.pair, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const Spacer(),
                  _StatusChip(status: signal.status),
                ],
              ),
              const SizedBox(height: 12),
              BlurLockOverlay(
                locked: !unlocked,
                onUnlockTap: onUnlockRequested,
                child: Row(
                  children: [
                    _priceStat('Entry', signal.entry),
                    _priceStat('SL', signal.stopLoss),
                    _priceStat('TP', signal.takeProfit),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(signal.timeframe, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 14),
                  Icon(Icons.shield_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Risk: ${signal.riskLevel}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const Spacer(),
                  Text(timeAgo(signal.postedAt), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceStat(String label, double value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value.toStringAsFixed(value < 10 ? 4 : 2),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SignalStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String text;
    switch (status) {
      case SignalStatus.active:
        color = AppColors.gold;
        text = 'ACTIVE';
        break;
      case SignalStatus.hitTp:
        color = AppColors.buy;
        text = 'HIT TP';
        break;
      case SignalStatus.hitSl:
        color = AppColors.sell;
        text = 'HIT SL';
        break;
      case SignalStatus.closed:
        color = AppColors.textMuted;
        text = 'CLOSED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
