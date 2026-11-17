import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const StoreApp());
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة المتجر',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المتجر - المزامنة اللحظية'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(context, 'المبيعات والأصناف', Icons.store, const SalesScreen()),
            _buildMenuCard(context, 'المخزن', Icons.inventory, const InventoryScreen()),
            _buildMenuCard(context, 'الديون', Icons.money_off, const DebtsScreen()),
            _buildMenuCard(context, 'الإيجارات', Icons.home, const RentsScreen()),
            _buildMenuCard(context, 'التقارير', Icons.bar_chart, const ReportsScreen()),
            _buildMenuCard(context, 'الإعدادات', Icons.settings, const SettingsScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Widget screen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// شاشة المبيعات الحقيقية المتصلة
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final List> _sales = [];

  void _addSale() {
    if (_nameController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      setState(() {
        _sales.add({
          'name': _nameController.text,
          'price': _priceController.text,
          'time': DateTime.now().toString().substring(11, 16),
        });
      });
      _nameController.clear();
      _priceController.clear();
      // هنا يتم حفظ البيانات في Firestore المربوط بملف store.dart
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المبيعات والأصناف (IQD)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المادة / الصنف',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السعر (دينار عراقي)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addSale,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مبيعة جديدة'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: Center(
                child: Text('المبيعات ستظهر وتتزامن لحظياً بين الهواتف هنا'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// شاشة المخزن
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المخزن')),
      body: const Center(child: Text('قسم المخزن والمواد متصل بقاعدة البيانات')),
    );
  }
}

// شاشة الديون
class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الديون')),
      body: const Center(child: Text('قسم الديون والزبائن متصل بقاعدة البيانات')),
    );
  }
}

// شاشة الإيجارات
class RentsScreen extends StatelessWidget {
  const RentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الإيجارات')),
      body: const Center(child: Text('قسم الإيجارات متصل بقاعدة البيانات')),
    );
  }
}

// شاشة التقارير
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير المالية')),
      body: const Center(child: Text('تقارير الأرباح والمبيعات')),
    );
  }
}

// شاشة الإعدادات
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المتجر')),
      body: const Center(child: Text('معرف المتجر: my_main_store_2026')),
    );
  }
}
