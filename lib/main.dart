import 'package:flutter/material.dart';

void main() {
  runApp(const ElectricalStoreApp());
}

class ElectricalStoreApp extends StatelessWidget {
  const ElectricalStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة متجر الكهربائية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        fontFamily: 'Roboto',
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'البيع'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'الديون'),
          BottomNavigationBarItem(icon: Icon(Icons.handyman), label: 'الإيجارات'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
        ],
      ),
    );
  }
}

// 1. شاشة المبيعات (POS)
class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نقطة البيع - POS'), backgroundColor: Colors.amber),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'بحث عن مادة أو باركود...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: const [
                  Card(child: ListTile(title: Text('واير كهربائي 2.5 مم'), subtitle: Text('السعر: 45,000 د.ع'), trailing: Icon(Icons.add_shopping_cart))),
                  Card(child: ListTile(title: Text('مفتاح إنارة مفرد'), subtitle: Text('السعر: 2,500 د.ع'), trailing: Icon(Icons.add_shopping_cart))),
                  Card(child: ListTile(title: Text('قاطع عورة 32 أمبير'), subtitle: Text('السعر: 15,000 د.ع'), trailing: Icon(Icons.add_shopping_cart))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.amber[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الإجمالي: 0 د.ع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800]),
                    onPressed: () {},
                    child: const Text('إتمام البيع', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// 2. شاشة المخزن
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المخزن'), backgroundColor: Colors.amber),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(title: Text('سلك نحاس'), subtitle: Text('الكمية: 10 لفة | السعر: 45,000 د.ع'), leading: Icon(Icons.electrical_services)),
          Divider(),
          ListTile(title: Text('بانل ليد 60×60'), subtitle: Text('الكمية: 25 قطعة | السعر: 12,000 د.ع'), leading: Icon(Icons.light)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

// 3. شاشة الديون
class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دفتر الديون'), backgroundColor: Colors.amber),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              title: Text('أحمد محمد'),
              subtitle: Text('المبلغ: 125,000 د.ع\nالتاريخ: 2026/04/10'),
              isThreeLine: true,
              trailing: Text('مطلوب', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// 4. شاشة الإيجارات
class RentalsScreen extends StatelessWidget {
  const RentalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إيجارات المعدات'), backgroundColor: Colors.amber),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              title: Text('مؤشر حفر (هيلتي)'),
              subtitle: Text('المستأجر: كرم | الحساب اليومي: 15,000 د.ع'),
              trailing: Chip(label: Text('مؤجر حالياً', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange),
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
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير والأرباح'), backgroundColor: Colors.amber),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: const [
                    Text('إجمالي مبيعات اليوم', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 10),
                    Text('350,000 د.ع', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
