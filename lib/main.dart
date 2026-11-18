import 'package:flutter/material.dart';

void main() {
  runApp(const AlSunbulahApp());
}

class AlSunbulahApp extends StatelessWidget {
  const AlSunbulahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'السنبلة - كهربائيات وإنشائيات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B2A4A),
          primary: const Color(0xFF0B2A4A),
          secondary: const Color(0xFFF2B21B),
          tertiary: const Color(0xFFF26522),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        fontFamily: 'Roboto',
      ),
      home: const MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PosScreen(),
    const InventoryScreen(),
    const DebtsScreen(),
    const RentalsScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'البيع'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'المخزن'),
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'الديون'),
          NavigationDestination(icon: Icon(Icons.handyman_outlined), selectedIcon: Icon(Icons.handyman), label: 'الإيجارات'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'التقارير'),
        ],
      ),
    );
  }
}

// 1. شاشة الرئيسية
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محل السنبلة للكهربائيات والإنشائيات', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF0B2A4A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0B2A4A), Color(0xFF1B4F72)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إجمالي مبيعات اليوم', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 8),
                Text('450,000 د.ع', style: TextStyle(color: Color(0xFFF2B21B), fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('نظرة عامة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B2A4A))),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildSummaryCard('ديون غير مسددة', '1,250,000 د.ع', Icons.money_off, Colors.red),
              _buildSummaryCard('معدات مؤجرة', '4 معدات', Icons.handyman, const Color(0xFFF26522)),
              _buildSummaryCard('تنبيهات المخزن', '3 أصناف منخفضة', Icons.warning_amber, Colors.orange),
              _buildSummaryCard('أرباح اليوم', '120,000 د.ع', Icons.trending_up, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, spreadRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// 2. شاشة البيع (POS)
class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نقطة البيع (POS)', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF0B2A4A)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن المادة أو امسح الباركود...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0B2A4A)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  Card(child: ListTile(title: Text('واير تسليك 2.5 مم - سعودي'), subtitle: Text('السعر: 45,000 د.ع'), trailing: Icon(Icons.add_shopping_
