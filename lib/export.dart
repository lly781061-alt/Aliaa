import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'store.dart';

class QRBackupScreen extends StatelessWidget {
  final StoreData storeData;
  const QRBackupScreen({super.key, required this.storeData});

  @override
  Widget build(BuildContext context) {
    final jsonString = storeData.exportToJson();
    return Scaffold(
      appBar: AppBar(title: const Text('مشاركة النسخة عبر الباركود')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('توليد باركود لنقل البيانات لهاتف آخر:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: QrImageView(data: jsonString, version: QrVersions.auto, size: 250.0, backgroundColor: Colors.white),
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.camera_alt),
              label: const Text('قراءة باركود لاستعادة البيانات'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRScanScreen(storeData: storeData))),
            ),
          ],
        ),
      ),
    );
  }
}

class QRScanScreen extends StatefulWidget {
  final StoreData storeData;
  const QRScanScreen({super.key, required this.storeData});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool scanned = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح الباركود')),
      body: MobileScanner(
        onDetect: (capture) {
          if (scanned) return;
          for (final barcode in capture.barcodes) {
            if (barcode.rawValue != null) {
              scanned = true;
              bool success = widget.storeData.importFromJson(barcode.rawValue!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'تمت الاستعادة بنجاح!' : 'فشل القراءة')));
                Navigator.pop(context);
                Navigator.pop(context);
              }
              break;
            }
          }
        },
      ),
    );
  }
}
