import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/food_db.dart';
import '../../core/l10n.dart';

/// يفتح ماسح الباركود ويرجّع صنف غذائى من Open Food Facts (أو null).
Future<FoodItem?> scanBarcodeForFood(BuildContext context) {
  return Navigator.push<FoodItem>(
    context,
    MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
  );
}

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  MobileScannerController? _controller;
  bool _busy = false;
  final _manual = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manual.dispose();
    super.dispose();
  }

  Future<void> _handle(String code) async {
    if (_busy) return;
    setState(() => _busy = true);
    final item = await lookupBarcode(code);
    if (!mounted) return;
    if (item != null) {
      Navigator.pop(context, item);
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('مش لاقيين المنتج ده — جرّب تكتبه يدوي',
              "Product not found — try adding it manually"))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('مسح باركود', 'Scan barcode'))),
      body: Column(
        children: [
          if (!kIsWeb && _controller != null)
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      for (final b in capture.barcodes) {
                        final v = b.rawValue;
                        if (v != null && v.isNotEmpty) {
                          _handle(v);
                          break;
                        }
                      }
                    },
                  ),
                  if (_busy) const CircularProgressIndicator(),
                  IgnorePointer(
                    child: Container(
                      width: 240,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white70, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                      tr('الكاميرا مش متاحة هنا — اكتب رقم الباركود تحت',
                          'Camera not available here — type the barcode below'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manual,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: tr('رقم الباركود يدوي', 'Barcode number'),
                        border: const OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () {
                          final c = _manual.text.trim();
                          if (c.isNotEmpty) _handle(c);
                        },
                  child: Text(tr('بحث', 'Look up')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
