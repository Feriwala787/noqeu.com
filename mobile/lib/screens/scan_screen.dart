import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController? _controller;
  bool _hasPermission = false;
  bool _permissionDenied = false;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() { _hasPermission = true; });
      _controller = MobileScannerController(detectionSpeed: DetectionSpeed.normal, facing: CameraFacing.back);
    } else {
      setState(() { _permissionDenied = true; });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;
    final shopId = _extractShopId(raw);
    if (shopId != null) {
      _scanned = true;
      _controller?.stop();
      Navigator.pop(context, shopId);
    }
  }

  String? _extractShopId(String raw) {
    // Handle: noqeu://shop/<id>, https://noqeu.com/shop/<id>, or raw ID
    final uri = Uri.tryParse(raw);
    if (uri != null) {
      if (uri.scheme == 'noqeu' && uri.host == 'shop' && uri.pathSegments.isNotEmpty) return uri.pathSegments.first;
      if ((uri.host == 'noqeu.com' || uri.host == 'www.noqeu.com') && uri.pathSegments.length >= 2 && uri.pathSegments.first == 'shop') return uri.pathSegments[1];
    }
    // If it looks like a MongoDB ObjectId (24 hex chars)
    if (RegExp(r'^[a-f0-9]{24}$').hasMatch(raw)) return raw;
    return null;
  }

  Future<void> _manualEntry() async {
    final ctrl = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter Shop ID', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Ask the shop owner for their Shop ID', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Paste Shop ID or link', prefixIcon: Icon(Icons.link, color: AppTheme.primary))),
          const SizedBox(height: 14),
          FilledButton(onPressed: () {
            final text = ctrl.text.trim();
            final id = _extractShopId(text) ?? text;
            if (id.isNotEmpty) Navigator.pop(context, id);
          }, child: const Text('Connect to Shop')),
        ]),
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Shop QR'), actions: [
        TextButton.icon(onPressed: _manualEntry, icon: const Icon(Icons.keyboard, size: 18), label: const Text('Enter ID')),
      ]),
      body: _permissionDenied ? _permissionDeniedView() : _hasPermission ? _scannerView() : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _scannerView() {
    return Stack(
      children: [
        MobileScanner(controller: _controller!, onDetect: _onDetect),
        // Overlay
        Center(
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primary, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          bottom: 100, left: 0, right: 0,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: const Text('Point at shop QR code', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _manualEntry,
              icon: const Icon(Icons.keyboard_outlined, size: 18),
              label: const Text('Enter ID manually'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38)),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _permissionDeniedView() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.camera_alt_outlined, size: 64, color: AppTheme.textSecondary),
      const SizedBox(height: 16),
      Text('Camera Permission Required', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Allow camera access to scan shop QR codes', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
      const SizedBox(height: 24),
      FilledButton(onPressed: () => openAppSettings(), child: const Text('Open Settings')),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: _manualEntry, child: const Text('Enter Shop ID instead')),
    ])));
  }
}
