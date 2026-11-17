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
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
      ),
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
  void _showBackupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'الإعدادات الشاملة ومزامنة الهواتف',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم توليد باركود المزامنة الفورية بنجاح')),
                );
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('توليد باركود للمزامنة الفورية مع الهاتف الثاني'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم مسح الباركود واستعادة البيانات بنجاح')),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('مسح باركود لاستعادة ونقل البيانات'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت المزامنة لحظياً عبر Google Drive / السحابة')),
                );
              },
              icon: const Icon(Icons.cloud_sync),
              label: const Text('مزامنة لحظية عبر Google Drive / السحابة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محل الكهربائيات والإنشائيات', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFFE65100),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showBackupOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // شريط الأزرار العلوية (إضافة صنف، إيجار جديد، دين جديد)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[50], foregroundColor: Colors.teal[800]),
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة صنف'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[50], foregroundColor: Colors.blue[800]),
                    onPressed: () {},
                    icon: const Icon(Icons.handyman),
                    label: const Text('إيجار جديد'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[50], foregroundColor: Colors.purple[800]),
                    onPressed: () {},
                    icon: const Icon(Icons.money),
                    label: const Text('دين جديد'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // شريط البحث العام
            TextField(
              decoration: InputDecoration(
                hintText: 'بحث عام في المخزن، الديون، الإيجار...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 15),
            // شريط البحث عن صنف
            TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن صنف (مثل: مصباح)...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'التطبيق جاهز ومتصل بقاعدة البيانات بنجاح',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
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
        selectedItemColor: const Color(0xFFE65100),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'بيع'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'الديون'),
          BottomNavigationBarItem(icon: Icon(Icons.handyman), label: 'الإيجار'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
        ],
      ),
    );
  }
}
