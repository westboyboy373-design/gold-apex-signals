import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final winRatePct = (app.winRate * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(title: const Text('Track Record')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: _statCard('Win Rate', '$winRatePct%', AppColors.gold)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Closed Signals', '${app.totalClosedSignals}', AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Signal History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...app.signals.map((s) => _historyRow(s)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _historyRow(TradingSignal s) {
    late Color color;
    late String text;
    switch (s.status) {
      case SignalStatus.hitTp:
        color = AppColors.buy;
        text = 'WIN';
        break;
      case SignalStatus.hitSl:
        color = AppColors.sell;
        text = 'LOSS';
        break;
      case SignalStatus.active:
        color = AppColors.gold;
        text = 'ACTIVE';
        break;
      case SignalStatus.closed:
        color = AppColors.textMuted;
        text = 'CLOSED';
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(s.pair, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            child: Text(
              s.direction == SignalDirection.buy ? 'BUY' : 'SELL',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
