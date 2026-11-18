import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'store.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @const
  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final jsonString = store.exportToJson();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مشاركة ونقل البيانات'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'امسح الرمز أدناه من جهاز آخر لنقل البيانات، أو استورد بيانات من باركود جاهز.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (jsonString.length < 2500)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: QrImageView(
                    data: jsonString,
                    version: QrVersions.auto,
                    size: 250.0,
                  ),
                ),
              )
            else
              const Card(
                color: Colors.orangeAccent,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'البيانات كبيرة جداً لتوليد باركود واحد. يفضل استخدام النسخ الاحتياطي المحلي أو ملفات JSON.',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.camera_alt),
              label: const Text('مسح باركود لاستيراد البيانات', style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScanScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class QRScanScreen extends StatelessWidget {
  const QRScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('مسح باركود البيانات')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final rawValue = barcode.rawValue;
            if (rawValue != null) {
              bool success = store.importFromJson(rawValue);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'تم استيراد البيانات بنجاح!' : 'فشل قراءة البيانات، الكود غير صالح.'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
              break;
            }
          }
        },
      ),
    );
  }
}
