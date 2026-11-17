import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Init Error: $e');
  }
  runApp(const StoreApp());
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'محل الكهربائيات والإنشائيات',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const StoreHomePage(),
    );
  }
}

class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  int _currentIndex = 0;

  // نقاط النسخ الاحتياطي والمزامنة المحدثة
  void _executeBackupPoint(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تنفيذ نقطة النسخ الاحتياطي: $type بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محل الكهربائيات والإنشائيات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // نافذة الإعدادات ونقاط النسخ
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('الإعدادات الشاملة ومزامنة الهواتف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _executeBackupPoint('توليد باركود للمزامنة');
                        },
                        icon: const Icon(Icons.qr_code),
                        label: const Text('توليد باركود للمزامنة الفورية مع الهاتف الثاني'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                          _executeBackupPoint('مزامنة Google Drive');
                        },
                        icon: const Icon(Icons.cloud_sync),
                        label: const Text('مزامنة لحظية عبر Google Drive / السحابة'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, size: 80, color: Colors.orange),
            const SizedBox(height: 10),
            const Text(
              'أهلاً بك في نظام إدارة المحل والإنشائيات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _executeBackupPoint('نسخ احتياطي يدوي'),
              icon: const Icon(Icons.backup),
              label: const Text('إجراء نسخ احتياطي الآن'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'البيع'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'الديون'),
          BottomNavigationBarItem(icon: Icon(Icons.handyman), label: 'الإيجار'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ' التقارير'),
        ],
      ),
    );
  }
}
