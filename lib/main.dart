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

// 1. شاشة البيع
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
                  backgroundColor: category == 'الكل' ? Colors.orange[100] : Colors.white,
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
