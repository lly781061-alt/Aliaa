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
      appBar.new(title: const Text('مشاركة ونقل النسخة الاحتياطية عبر الباركود')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('توليد باركود لقاعدة البيانات لنقلها لهاتف آخر:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: QrImageView(
                    data: jsonString,
                    version: QrVersions.auto,
                    size: 250.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.camera_alt),
              label: const Text('قراءة باركود لاستعادة البيانات من هاتف آخر', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => QRScanScreen(storeData: storeData)));
              },
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
      appBar: AppBar(title: const Text('مسح باركود النسخة الاحتياطية')),
      body: MobileScanner(
        onDetect: (capture) {
          if (scanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              scanned = true;
              bool success = widget.storeData.importFromJson(barcode.rawValue!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'تمت استعادة البيانات بنجاح!' : 'فشل قراءة البيانات من الباركود')),
                );
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
