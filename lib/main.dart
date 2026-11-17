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

  @sbin
  State<StoreMainScreen> createState() => _StoreMainScreenState();
}

class _StoreMainScreenState extends State<StoreMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SaleScreen(),
    const InventoryScreen(),
    const DebtsScreen(),
    const RentalsScreen(),
    const ReportsScreen(),
  ];

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محل الكهربائيات والإنشائيات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFE65100),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: _screens[_currentIndex],
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
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'الديون'),
          BottomNavigationBarItem(icon: Icon(Icons.handyman), label: 'الإيجار'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
        ],
      ),
    );
  }
}

// 1. شاشة البيع (مطابقة تماماً للصور)
class SaleScreen extends StatelessWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFAB47BC)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.teal[800], elevation: 0),
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('إضافة صنف', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue[800], elevation: 0),
                        onPressed: () {},
                        icon: const Icon(Icons.handyman, size: 18),
                        label: const Text('إيجار جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.purple[800], elevation: 0),
                        onPressed: () {},
                        icon: const Icon(Icons.money, size: 18),
                        label: const Text('دين جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث عام في المخزن، الديون، الإيجار...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'ابحث عن صنف (مثل: مصباح)...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 180),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black54),
                onPressed: () {},
                icon: const Icon(Icons.check),
                label: const Text('إتمام البيع'),
              ),
              const Text(
                'إجمالي الفاتورة: 0 د.ع',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 2. شاشة المخزن
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: ['الكل', 'كهربائيات', 'إنشائيات', 'أخرى'].map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Chip(
                  label: Text(category),
                  backgroundColor: category == 'الكل' ? Colors.orange[150] : Colors.white,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomLeft,
            child: FloatingActionButton(
              backgroundColor: Colors.teal,
              onPressed: () {},
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// 3. شاشة الديون
class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('إجمالي الديون المستحقة\n100,000 د.ع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('المديونون\n1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'بحث عن عميل مدين...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
              title: const Text('علي عدنان', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('الهاتف: لا يوجد'),
              trailing: const Text('100,000 د.ع', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// 4. شاشة الإيجار
class RentalsScreen extends StatelessWidget {
  const RentalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('إيجار جديد'),
          ),
          const SizedBox(height: 10),
          const Text('قيد الإيجار (0)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('لا توجد إيجارات نشطة حالياً', style: TextStyle(color: Colors.grey))),
            ),
          ),
          const SizedBox(height: 15),
          const Text('المعدات المتاحة', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Card(
            child: ListTile(
              title: const Text('سقالة حديد', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('2,000 د.ع / يوم'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
                child: const Text('متاح 30 من 30', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('خلاطة كونكريت', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('15,000 د.ع / يوم'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
                child: const Text('متاح 3 من 3', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 5. شاشة التقارير
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('تقارير المبيعات والأرباح', style: TextStyle(fontSize: 16, color: Colors.grey)),
    );
  }
}

// 6. شاشة الإعدادات الشاملة ومزامنة الهواتف (مطابقة تماماً للصور)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات الشاملة ومزامنة الهواتف', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE65100),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('بيانات المحل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
          const TextField(decoration: InputDecoration(labelText: 'اسم المحل', hintText: 'محل الكهربائيات والإنشائيات')),
          const TextField(decoration: InputDecoration(labelText: 'رقم هاتف المحل')),
          const TextField(decoration: InputDecoration(labelText: 'العنوان')),
          const TextField(decoration: InputDecoration(labelText: 'العملة', hintText: 'د.ع')),
          const SizedBox(height: 20),
          const Text('تخصيص ألوان الواجهة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
          const ListTile(title: Text('لون الاسم (للعملاء والمعدات)'), subtitle: Text('أسود داكن')),
          const ListTile(title: Text('لون التاريخ وتفاصيل الإيجار'), subtitle: Text('رمادي')),
          const ListTile(title: Text('لون حالة الاستلام (مستلم)'), subtitle: Text('أخضر زاهي')),
          const SizedBox(height: 20),
          const Text('النسخ الاحتياطي والمزامنة بين الهواتف', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('توليد باركود للمزامنة الفورية')));
            },
            icon: const Icon(Icons.qr_code),
            label: const Text('توليد باركود للمزامنة الفورية مع الهاتف الثاني'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مسح باركود لاستعادة البيانات')));
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('مسح باركود لاستعادة ونقل البيانات للهاتف الحالي'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مزامنة لحظية عبر Google Drive')));
            },
            icon: const Icon(Icons.cloud_sync),
            label: const Text('مزامنة لحظية عبر Google Drive / السحابة'),
          ),
        ],
      ),
    );
  }
}
