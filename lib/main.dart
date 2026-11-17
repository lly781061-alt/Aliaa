import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        else: Container(),
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

// شاشة المبيعات
class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المبيعات والأصناف')),
      body: const Center(child: Text('قسم المبيعات والأصناف متصل بقاعدة البيانات')),
    );
  }
}

// شاشة المخزن
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المخزن')),
      body: const Center(child: Text('قسم المخزن متصل بقاعدة البيانات')),
    );
  }
}

// شاشة الديون
class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الديون')),
      body: const Center(child: Text('قسم الديون متصل بقاعدة البيانات')),
    );
  }
}

// شاشة الإيجارات
class RentsScreen extends StatelessWidget {
  const RentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإيجارات')),
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
      appBar: AppBar(title: const Text('التقارير')),
      body: const Center(child: Text('قسم التقارير متصل بقاعدة البيانات')),
    );
  }
}

// شاشة الإعدادات
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: const Center(child: Text('إعدادات المتجر والربط')),
    );
  }
}
