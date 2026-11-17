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
        fontFamily: 'Cairo',
      ),
      home: const StoreMainScreen(),
    );
  }
}

class StoreMainScreen extends StatefulWidget {
  const StoreMainScreen({super.key});

  @override
  State<StoreMainScreen> createState() => _StoreMainScreenState();
}

class _StoreMainScreenState extends State<StoreMainScreen> {
  int _currentIndex = 0;
  final TextEditingController _globalSearchController = TextEditingController();

  // الأقسام بالترتيب المطلوب من اليمين: بيع، الديون، الإيجارات، المخزن، التقارير
  final List<Widget> _screens = const [
    SaleSectionScreen(),
    DebtsSectionScreen(),
    RentalsSectionScreen(),
    InventorySectionScreen(),
    ReportsSectionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('محل الكهربائيات والإنشائيات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: const Color(0xFFE65100),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsSectionScreen()));
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // اختصارات علوية (صنف جديد، إيجار جديد، دين جديد)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.orange[50],
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('صنف جديد', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      onPressed: () {},
                      icon: const Icon(Icons.handyman, size: 16),
                      label: const Text('إيجار جديد', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                      onPressed: () {},
                      icon: const Icon(Icons.money, size: 16),
                      label: const Text('دين جديد', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            // بحث عام في كل الأقسام
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _globalSearchController,
                decoration: InputDecoration(
                  hintText: 'بحث عام في (المخزن، الديون، الإيجار، المبيعات)...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                onChanged: (value) {
                  // منطق البحث العام اللحظي
                },
              ),
            ),
            // محتوى الشاشة الحالية
            Expanded(
              child: _screens[_currentIndex],
            ),
          ],
        ),
        // الأقسام من اليمين لليسار في الشريط السفلي
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFE65100),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'بيع'),
            BottomNavigationBarItem(icon: Icon(Icons.money), label: 'الديون'),
            BottomNavigationBarItem(icon: Icon(Icons.handyman), label: 'الإيجارات'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'المخزن'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
          ],
        ),
      ),
    );
  }
}

// 1. قسم البيع
class SaleSectionScreen extends StatelessWidget {
  const SaleSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          const Expanded(child: Center(child: Text('شاشة نقطة البيع وتسجيل الفواتير', style: TextStyle(color: Colors.grey)))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إجمالي الفاتورة: 0 د.ع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {},
                child: const Text('إتمام البيع'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 2. قسم الديون
class DebtsSectionScreen extends StatelessWidget {
  const DebtsSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(10)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('إجمالي الديون المستحقة\n0 د.ع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('المديونون: 0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Expanded(child: Center(child: Text('قائمة الديون والعملاء (تسجيل واستلام الدين)', style: TextStyle(color: Colors.grey)))),
        ],
      ),
    );
  }
}

// 3. قسم الإيجارات
class RentalsSectionScreen extends StatelessWidget {
  const RentalsSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          const Expanded(child: Center(child: Text('إدارة المعدات والإيجارات النشطة والمعلومات السابقة للمؤجرين', style: TextStyle(color: Colors.grey)))),
        ],
      ),
    );
  }
}

// 4. قسم المخزن
class InventorySectionScreen extends StatelessWidget {
  const InventorySectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          const Expanded(child: Center(child: Text('قائمة الأصناف والمخزن', style: TextStyle(color: Colors.grey)))),
        ],
      ),
    );
  }
}

// 5. قسم التقارير
class ReportsSectionScreen extends StatelessWidget {
  const ReportsSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('تقارير الأرباح والمبيعات', style: TextStyle(color: Colors.grey)),
    );
  }
}

// قسم الإعدادات والنسخ الاحتياطي والمزامنة والتحكم بالألوان
class SettingsSectionScreen extends StatelessWidget {
  const SettingsSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات والنسخ الاحتياطي والمزامنة', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFE65100),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text('المزامنة اللحظية بين الهواتف (Firebase)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
            const Text('البيانات تتزامن لحظياً بين الهاتف الأول والثاني عند الاتصال بالإنترنت.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 30),
            
            const Text('النسخ الاحتياطي والاستعادة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
            ListTile(
              leading: const Icon(Icons.cloud_sync, color: Colors.green),
              title: const Text('مزامنة وحفظ عبر Google Drive / السحابة'),
              subtitle: const Text('اختيار وتغيير حساب النسخ الاحتياطي'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.phone_android, color: Colors.orange),
              title: const Text('حفظ واستعادة النسخة الاحتياطية محلياً في الجهاز'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.purple),
              title: const Text('نسخ احتياطي واستعادة عبر الباركود (الكاميرا الأمامية/الخلفية)'),
              onTap: () {},
            ),
            const Divider(height: 30),

            const Text('التحكم بالواجهات والألوان', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
            const ListTile(
              title: Text('تحكم بألوان النصوص (الأسعار، التواريخ، الملاحظات، الديون)'),
              subtitle: Text('تخصيص كامل لألوان الواجهة حسب رغبتك'),
            ),
            ListTile(
              title: const Text('إدارة الأقسام (إضافة / حذف أقسام)'),
              trailing: const Icon(Icons.edit),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
