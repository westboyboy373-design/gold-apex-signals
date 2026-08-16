import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/blur_lock_overlay.dart';

class SignalDetailScreen extends StatelessWidget {
  final TradingSignal signal;
  const SignalDetailScreen({super.key, required this.signal});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final unlocked = app.isUnlocked(signal);
    final isBuy = signal.direction == SignalDirection.buy;
    final directionColor = isBuy ? AppColors.buy : AppColors.sell;

    return Scaffold(
      appBar: AppBar(title: Text(signal.pair)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: directionColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(isBuy ? 'BUY' : 'SELL', style: TextStyle(color: directionColor, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Text('${signal.timeframe} · Risk: ${signal.riskLevel}', style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
          BlurLockOverlay(
            locked: !unlocked,
            label: 'Unlock full signal — 50 coins',
            onUnlockTap: () async {
              final ok = await context.read<AppState>().unlockSignal(signal);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Not enough coins — top up your wallet.')));
              }
            },
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        _statColumn('Entry', signal.entry),
                        _divider(),
                        _statColumn('Stop Loss', signal.stopLoss),
                        _divider(),
                        _statColumn('Take Profit', signal.takeProfit),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (signal.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: AppColors.surfaceElevated,
                        child: const Center(
                          child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 40),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Analysis', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gold)),
                        const SizedBox(height: 8),
                        Text(signal.analysis, style: const TextStyle(height: 1.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Posted by ${signal.postedByAdmin} · ${timeAgo(signal.postedAt)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statColumn(String label, double value) => Expanded(
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value.toStringAsFixed(value < 10 ? 4 : 2), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      );

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.border);
}
