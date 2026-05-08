import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/noqeu_service.dart';

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _seats = 2;
  int _avgTime = 30;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _occupationCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<NoQeuService>().createShop({
        'name': _nameCtrl.text.trim(),
        'occupation': _occupationCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'totalSeats': _seats,
        'avgTimePerCustomer': _avgTime,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop created!')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Shop')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shop Details', style: theme.textTheme.headlineSmall).animate().fadeIn(),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.store_outlined)),
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _occupationCtrl,
                  decoration: const InputDecoration(labelText: 'Service Type (e.g. Barber, Mechanic)', prefixIcon: Icon(Icons.work_outline)),
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address (optional)', prefixIcon: Icon(Icons.location_on_outlined)),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.description_outlined)),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 24),
                Text('Capacity', style: theme.textTheme.titleMedium).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Seats / Stations: $_seats', style: theme.textTheme.bodyMedium),
                          Slider(
                            value: _seats.toDouble(),
                            min: 1,
                            max: 20,
                            divisions: 19,
                            label: '$_seats',
                            onChanged: (v) => setState(() => _seats = v.round()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 350.ms),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Avg. time per customer: ${_avgTime}m', style: theme.textTheme.bodyMedium),
                          Slider(
                            value: _avgTime.toDouble(),
                            min: 5,
                            max: 120,
                            divisions: 23,
                            label: '${_avgTime}m',
                            onChanged: (v) => setState(() => _avgTime = v.round()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Shop'),
                ).animate().fadeIn(delay: 450.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
