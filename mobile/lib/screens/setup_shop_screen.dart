import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class SetupShopScreen extends StatefulWidget {
  final Map<String, dynamic>? shop; // null = create, non-null = edit
  const SetupShopScreen({super.key, this.shop});
  @override
  State<SetupShopScreen> createState() => _SetupShopScreenState();
}

class _SetupShopScreenState extends State<SetupShopScreen> {
  final _nameCtrl = TextEditingController();
  final _occCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  int _seats = 2;
  int _slotTime = 30;
  TimeOfDay _open = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _close = const TimeOfDay(hour: 18, minute: 0);
  List<int> _days = [1, 2, 3, 4, 5, 6];
  bool _loading = false;

  bool get _isEdit => widget.shop != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final s = widget.shop!;
      _nameCtrl.text = s['name'] ?? '';
      _occCtrl.text = s['occupation'] ?? '';
      _descCtrl.text = s['description'] ?? '';
      _addrCtrl.text = s['address'] ?? '';
      _phoneCtrl.text = s['phone'] ?? '';
      _seats = s['totalSeats'] ?? 2;
      _slotTime = s['avgTimePerCustomer'] ?? 30;
      final op = (s['openTime'] ?? '09:00').split(':');
      _open = TimeOfDay(hour: int.parse(op[0]), minute: int.parse(op[1]));
      final cl = (s['closeTime'] ?? '18:00').split(':');
      _close = TimeOfDay(hour: int.parse(cl[0]), minute: int.parse(cl[1]));
      _days = List<int>.from(s['workingDays'] ?? [1, 2, 3, 4, 5, 6]);
    }
  }

  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _occCtrl.text.trim().isEmpty) { _snack('Name and service type required'); return; }
    setState(() => _loading = true);
    final data = {
      'name': _nameCtrl.text.trim(),
      'occupation': _occCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'address': _addrCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'totalSeats': _seats,
      'avgTimePerCustomer': _slotTime,
      'openTime': _fmtTime(_open),
      'closeTime': _fmtTime(_close),
      'workingDays': _days,
    };
    try {
      if (_isEdit) { await Api.updateShop(widget.shop!['_id'], data); }
      else { await Api.createShop(data); }
      if (mounted) { _snack(_isEdit ? 'Shop updated!' : 'Shop created!'); Navigator.pop(context); }
    } catch (e) { _snack('$e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  final _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Shop' : 'Setup Your Shop')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _section('Basic Info'),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Business Name', prefixIcon: Icon(Icons.store_outlined, color: AppTheme.primary))).animate().fadeIn(),
        const SizedBox(height: 12),
        TextField(controller: _occCtrl, decoration: const InputDecoration(hintText: 'Service Type (Barber, Clinic, Salon...)', prefixIcon: Icon(Icons.work_outline, color: AppTheme.primary))).animate().fadeIn(delay: 50.ms),
        const SizedBox(height: 12),
        TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Description (optional)', prefixIcon: Icon(Icons.description_outlined, color: AppTheme.primary))).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 12),
        TextField(controller: _addrCtrl, decoration: const InputDecoration(hintText: 'Address', prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primary))).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 12),
        TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Shop Phone (optional)', prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primary))).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 28),
        _section('Capacity & Timing'),
        const SizedBox(height: 8),
        _sliderRow('Seats / Stations', _seats, 1, 20, (v) => setState(() => _seats = v)),
        _sliderRow('Slot Duration (min)', _slotTime, 5, 120, (v) => setState(() => _slotTime = v)),

        const SizedBox(height: 28),
        _section('Working Hours'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _timePicker('Opens', _open, (t) => setState(() => _open = t))),
          const SizedBox(width: 16),
          Expanded(child: _timePicker('Closes', _close, (t) => setState(() => _close = t))),
        ]).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 20),
        _section('Working Days'),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: List.generate(7, (i) {
          final selected = _days.contains(i);
          return GestureDetector(
            onTap: () => setState(() { if (selected) _days.remove(i); else _days.add(i); }),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 44, height: 44,
              decoration: BoxDecoration(color: selected ? AppTheme.primary : AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppTheme.primary : Colors.transparent)),
              child: Center(child: Text(_dayNames[i], style: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)))),
          );
        })).animate().fadeIn(delay: 350.ms),

        const SizedBox(height: 36),
        FilledButton(onPressed: _loading ? null : _save,
          child: _loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(_isEdit ? 'Save Changes' : 'Create Shop')).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 40),
      ])),
    );
  }

  Widget _section(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)));

  Widget _sliderRow(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Text('$value', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))),
      ]),
      Slider(value: value.toDouble(), min: min.toDouble(), max: max.toDouble(), divisions: max - min, onChanged: (v) => onChanged(v.round()), activeColor: AppTheme.primary),
    ]);
  }

  Widget _timePicker(String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return GestureDetector(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time);
        if (t != null) onChanged(t);
      },
      child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.access_time, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            Text(_fmtTime(time), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
        ])),
    );
  }
}
