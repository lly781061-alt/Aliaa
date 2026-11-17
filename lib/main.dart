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

  // الأقسام مرتبة من اليمين لليسار: بيع (0)، الديون (1)، الإيجار (2)، المخزن (3)، التقارير (4)
  final List<Widget> _screens = const [
    SaleSectionScreen(),
    DebtsSectionScreen(),
    RentalsSectionScreen(),
    InventorySectionScreen(),
    ReportsSectionScreen(),
  ];

  // نوافذ الحوار للاختصارات العلوية (إضافة صنف، إيجار جديد، دين جديد)
  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة صنف جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TextField(decoration: InputDecoration(labelText: 'اسم الصنف (مثل: مصباح 40 واط)')),
              TextField(decoration: InputDecoration(labelText: 'السعر (د.ع)')),
              TextField(decoration: InputDecoration(labelText: 'الكمية المتوفرة')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('حفظ')),
          ],
        ),
      ),
    );
  }

  void _showNewRentalDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إيجار جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TextField(decoration: InputDecoration(labelText: 'المعدة (سقالة حديد، خلاطة...)')),
              TextField(decoration: InputDecoration(labelText: 'العدد')),
              TextField(decoration: InputDecoration(labelText: 'اسم المستأجر')),
              TextField(decoration: InputDecoration(labelText: 'رقم هاتف المستأجر')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('تأكيد الإيجار')),
          ],
        ),
      ),
    );
  }

  void _showNewDebtDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('دين جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TextField(decoration: InputDecoration(labelText: 'اسم العميل')),
              TextField(decoration: InputDecoration(labelText: 'رقم الهاتف')),
              TextField(decoration: InputDecoration(labelText: 'المبلغ (د.ع)')),
              TextField(decoration: InputDecoration(labelText: 'ملاحظة')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('حفظ الدين')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('محل الكهربائيات والإنشائيات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: const Color(0xFFE65100),
          leading: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ),
        body: Column(
          children: [
            // شريط الاختصارات العلوية المطابق للصورة (إضافة صنف، إيجار جديد، دين جديد)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.purple.shade200, Colors.blue.shade200, Colors.teal.shade200]),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2), foregroundColor: Colors.white),
                      onPressed: _showNewDebtDialog,
                      icon: const Icon(Icons.money, size: 16),
                      label: const Text('دين جديد', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
                      onPressed: _showNewRentalDialog,
                      icon: const Icon(Icons.handyman, size: 16),
                      label: const Text('إيجار جديد', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
                      onPressed: _showAddItemDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة صنف', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            // محتوى القسم الحالي
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
        // الشريط السفلي للأقسام بالترتيب المطلوب من اليمين لليسار تماماً
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
            BottomNavigationBarItem(icon: Icon(Icons.handyman), label: 'الإيجار'),
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
          TextField(
            decoration: InputDecoration(
              hintText: 'بحث عام في (المخزن، الديون، الإيجار...)',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'ابحث عن صنف (مثل: مصباح)...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const Expanded(
            child: Center(child: Text('شاشة نقطة البيع وتسجيل الفواتير', style: TextStyle(color: Colors.grey))),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {},
                icon: const Icon(Icons.check),
                label: const Text('إتمام البيع'),
              ),
              const Text('إجمالي الفاتورة: 0 د.ع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          TextField(
            decoration: InputDecoration(
              hintText: 'بحث عن عميل مدين أو رقم الهاتف...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
              title: const Text('كرار', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('المتبقي: 23 د.ع'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DebtDetailScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}

// تفاصيل الدين للعميل (مطابق للصورة)
class DebtDetailScreen extends StatelessWidget {
  const DebtDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('كرار', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFE65100),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('المتبقي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('23 د.ع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.orange)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const TextField(decoration: InputDecoration(labelText: 'المبلغ (د.ع)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              const TextField(decoration: InputDecoration(labelText: 'ملاحظة', border: OutlineInputBorder())),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('دين جديد'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_downward),
                      label: const Text('استلام دفعة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. قسم الإيجار
class RentalsSectionScreen extends StatelessWidget {
  const RentalsSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('إيجار جديد'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.handyman),
                  label: const Text('إدارة المعدات'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('قيد الإيجار (1)', style: TextStyle(fontWeight: FontWeight.bold)),
          Card(
            child: ListTile(
              title: const Text('سقالة حديد × 1', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('العميل: كرار | الهاتف: لا يوجد\nالتاريخ: 17-11-2026'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () {},
                child: const Text('تسليم'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('المعدات المتاحة', style: TextStyle(fontWeight: FontWeight.bold)),
          Card(
            child: ListTile(
              title: const Text('سقالة حديد'),
              subtitle: const Text('2,000 د.ع / يوم'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(6)),
                child: const Text('متاح 29 من 30', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
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
          TextField(
            decoration: InputDecoration(
              hintText: 'ابحث عن صنف في المخزن...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const Expanded(child: Center(child: Text('قائمة أصناف المخزن والمواد', style: TextStyle(color: Colors.grey)))),
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
    return const Center(child: Text('تقارير المبيعات والأرباح', style: TextStyle(color: Colors.grey)));
  }
}

// شاشة الإعدادات والنسخ الاحتياطي ومزامنة Google Drive والباركود والألوان
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات والنسخ الاحتياطي', style: TextStyle(color: Colors.white)),
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
