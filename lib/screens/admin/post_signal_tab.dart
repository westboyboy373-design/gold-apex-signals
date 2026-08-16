import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class PostSignalTab extends StatefulWidget {
  const PostSignalTab({super.key});

  @override
  State<PostSignalTab> createState() => _PostSignalTabState();
}

class _PostSignalTabState extends State<PostSignalTab> {
  final _formKey = GlobalKey<FormState>();
  final _pairCtrl = TextEditingController(text: 'XAU/USD');
  final _entryCtrl = TextEditingController();
  final _slCtrl = TextEditingController();
  final _tpCtrl = TextEditingController();
  final _analysisCtrl = TextEditingController();
  String _timeframe = '1H';
  String _risk = 'Medium';
  SignalDirection _direction = SignalDirection.buy;
  bool _attachScreenshot = false;

  @override
  void dispose() {
    _pairCtrl.dispose();
    _entryCtrl.dispose();
    _slCtrl.dispose();
    _tpCtrl.dispose();
    _analysisCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _label('Pair'),
          TextFormField(controller: _pairCtrl, validator: _required),
          const SizedBox(height: 16),
          _label('Direction'),
          Row(
            children: [
              Expanded(
                child: _directionChip('BUY', SignalDirection.buy, AppColors.buy),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _directionChip('SELL', SignalDirection.sell, AppColors.sell),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _numberField('Entry', _entryCtrl)),
              const SizedBox(width: 10),
              Expanded(child: _numberField('Stop Loss', _slCtrl)),
              const SizedBox(width: 10),
              Expanded(child: _numberField('Take Profit', _tpCtrl)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _timeframe,
                  items: const ['5M', '15M', '1H', '4H', 'Daily']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _timeframe = v!),
                  decoration: const InputDecoration(labelText: 'Timeframe'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _risk,
                  items: const ['Low', 'Medium', 'High']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _risk = v!),
                  decoration: const InputDecoration(labelText: 'Risk Level'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Analysis / Notes'),
          TextFormField(
            controller: _analysisCtrl,
            maxLines: 4,
            validator: _required,
            decoration: const InputDecoration(hintText: 'Explain the setup for subscribers...'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.gold,
            title: const Text('Attach chart screenshot'),
            subtitle: const Text('Enable image upload for this signal', style: TextStyle(fontSize: 12)),
            value: _attachScreenshot,
            onChanged: (v) => setState(() => _attachScreenshot = v),
          ),
          if (_attachScreenshot)
            OutlinedButton.icon(
              onPressed: () {}, // TODO: wire to image_picker + Supabase Storage upload
              icon: const Icon(Icons.upload, size: 18),
              label: const Text('Choose Image'),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('POST SIGNAL'),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      );

  Widget _numberField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: _required,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _directionChip(String label, SignalDirection value, Color color) {
    final selected = _direction == value;
    return InkWell(
      onTap: () => setState(() => _direction = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Text(label, style: TextStyle(color: selected ? color : AppColors.textSecondary, fontWeight: FontWeight.w700)),
      ),
    );
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final app = context.read<AppState>();
    try {
      await app.postSignal(
        TradingSignal(
          id: '', // ignored on insert — Postgres generates the real id
          pair: _pairCtrl.text.trim(),
          direction: _direction,
          entry: double.tryParse(_entryCtrl.text) ?? 0,
          stopLoss: double.tryParse(_slCtrl.text) ?? 0,
          takeProfit: double.tryParse(_tpCtrl.text) ?? 0,
          timeframe: _timeframe,
          riskLevel: _risk,
          analysis: _analysisCtrl.text.trim(),
          imageUrl: _attachScreenshot ? 'placeholder' : null,
          postedByAdmin: app.currentUsername,
          postedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signal posted to the feed.')));
      _entryCtrl.clear();
      _slCtrl.clear();
      _tpCtrl.clear();
      _analysisCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post signal: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
