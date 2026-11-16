import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'store.dart';

class QRBackupScreen extends StatelessWidget {
  final StoreData storeData;
  const QRBackupScreen({super.key, required this.storeData});

  Future<void> _shareFile(BuildContext context) async {
    try {
      final jsonStr = storeData.exportToJson();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/store_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)], text: 'نسخة احتياطية لقاعدة بيانات المحل (Google Drive / Email)');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في مشاركة الملف: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final jsonString = storeData.exportToJson();
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي والمزامنة السحابية')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('باركود المزامنة السريعة بين الهواتف:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: QrImageView(data: jsonString, version: QrVersions.auto, size: 220.0, backgroundColor: Colors.white),
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.share),
              label: const Text('مشاركة عبر Google Drive أو الإيميل أو واتساب'),
              onPressed: () => _shareFile(context),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.teal, foregroundColor: Colors.white),
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
      appBar: AppBar(title: const Text('مسح الباركود للاستعادة')),
      body: MobileScanner(
        onDetect: (capture) {
          if (scanned) return;
          for (final barcode in capture.barcodes) {
            if (barcode.rawValue != null) {
              scanned = true;
              bool success = widget.storeData.importFromJson(barcode.rawValue!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'تمت استعادة البيانات بنجاح وتزامنت!' : 'فشل قراءة الباركود')));
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
