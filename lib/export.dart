import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'store.dart';

class QRBackupScreen extends StatelessWidget {
  final StoreData storeData;
  const QRBackupScreen({super.key, required this.storeData});

  @override
  Widget build(BuildContext context) {
    String jsonData = storeData.exportToJson();
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي عبر الباركود')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('امسح الرمز باستخدام جهاز آخر لاستعادة البيانات أو احتفظ به كنسخة احتياطية', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                child: QrImageView(
                  data: jsonData,
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                icon: const Icon(Icons.share),
                label: const Text('مشاركة بيانات النسخ الاحتياطي كنص أو ملف'),
                onPressed: () {
                  Share.share(jsonData);
                },
              ),
            ],
          ),
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
      appBar: AppBar(title: const Text('مسح باركود الاستعادة')),
      body: MobileScanner(
        controller: MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates),
        onDetect: (capture) {
          if (scanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              scanned = true;
              bool success = widget.storeData.importFromJson(barcode.rawValue!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'تم استعادة البيانات ومزامنتها بنجاح!' : 'فشل قراءة البيانات من الباركود')),
              );
              Navigator.pop(context);
              break;
            }
          }
        },
      ),
    );
  }
}
