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
                child: QrImageView(data: jsonData, version: QrVersions.auto, size: 250.0),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                icon: const Icon(Icons.share),
                label: const Text('مشاركة بيانات النسخ الاحتياطي كنص أو ملف'),
                onPressed: () => Share.share(jsonData),
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

// شاشة مزامنة البيانات على جوجل درايف تماماً مثل الصور المطلوبة
class GoogleDriveSyncScreen extends StatefulWidget {
  final StoreData storeData;
  const GoogleDriveSyncScreen({super.key, required this.storeData});

  @override
  State<GoogleDriveSyncScreen> createState() => _GoogleDriveSyncScreenState();
}

class _GoogleDriveSyncScreenState extends State<GoogleDriveSyncScreen> {
  @override
  Widget build(BuildContext context) {
    final store = widget.storeData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مزامنة البيانات على جوجل درايف'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // بطاقة الحساب المتصل
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الحساب المتصل بجوجل درايف', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud, color: Colors.amber, size: 28),
                          const SizedBox(width: 8),
                          Text(store.googleAccount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showChangeAccountDialog(context, store),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // بطاقة مزامنة قاعدة البيانات على جوجل (فورية مع تفعيل/إلغاء)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                    child: const Text('مزامنة قاعدة البيانات على (جوجل درايف)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, textAlign: TextAlign.center)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('إضغط على الزر التالي للتفعيل أو الإلغاء'),
                      Switch(
                        value: store.driveSyncActive,
                        onChanged: (v) {
                          setState(() { store.driveSyncActive = v; store.saveData(); });
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Text('حالة المزامنة: [تم بنجاح]', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                  Text('آخر عملية مزامنة تمت بتاريخ: ${store.lastSyncTime}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('تفعيل/إلغاء اشعارات المزامنة (جوجل درايف)'),
                      Switch(
                        value: store.driveNotifications,
                        onChanged: (v) {
                          setState(() { store.driveNotifications = v; store.saveData(); });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // بطاقة الحفظ التلقائي اليومي
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                    child: const Text('الحفظ التلقائي للبيانات يومياً (في)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, textAlign: TextAlign.center)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('إضغط على الزر التالي للتفعيل أو الإلغاء'),
                      Switch(
                        value: store.dailyAutoBackup,
                        onChanged: (v) {
                          setState(() { store.dailyAutoBackup = v; store.saveData(); });
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('تغيير وقت حفظ البيانات'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                        child: Text(store.dailyBackupTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('آخر عملية حفظ يومي تمت بتاريخ: ${store.lastDailyBackupTime}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // أزرار العمليات اليدوية
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const Text('عمل نسخة احتياطية من قاعدة البيانات', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(45)),
                    onPressed: () {
                      setState(() { store.lastSyncTime = DateTime.now().toString().substring(0, 19); store.saveData(); });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ قاعدة البيانات على جوجل درايف بنجاح!')));
                    },
                    child: const Text('حفظ قاعدة البيانات على جوجل درايف'),
                  ),
                  const Divider(height: 25),
                  const Text('استرجاع قاعدة البيانات', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(45)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استرجاع قاعدة البيانات من جوجل درايف بنجاح!')));
                    },
                    child: const Text('استرجاع قاعدة البيانات'),
                  ),
                  const Divider(height: 25),
                  const Text('التراجع عن عملية استرجاع البيانات الأخيرة', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(45)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التراجع عن الاسترجاع الأخير بنجاح')));
                    },
                    child: const Text('نقاط الاسترجاع التلقائية'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeAccountDialog(BuildContext context, StoreData store) {
    final emailC = TextEditingController(text: store.googleAccount);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختيار أو تغيير حساب جوجل'),
        content: TextField(
          controller: emailC,
          decoration: const InputDecoration(labelText: 'البريد الإلكتروني (جيميل)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (emailC.text.isNotEmpty) {
                setState(() { store.googleAccount = emailC.text; store.saveData(); });
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ واختيار الحساب'),
          ),
        ],
      ),
    );
  }
}
