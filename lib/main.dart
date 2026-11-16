import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'store.dart';
import 'export.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => StoreData(), child: const StoreApp()));
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'متجر برو',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.amber, useMaterial3: true),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // الافتراضي المخزن
  String globalSearch = '';

  final List<Widget> _screens = [
    const ReportsScreen(),
    const RentsScreen(),
    const DebtsScreen(),
    const InventoryScreen(),
    const SalesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(175),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.amber, Colors.brown], begin: Alignment.topRight, end: Alignment.bottomLeft),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
              Text(store.storeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(width: 40),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(115),
            child: Column(
              children: [
                // الأزرار العلوية السريعة (إضافة صنف، إيجار جديد، دين جديد)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('إضافة صنف'),
                          onPressed: () => setState(() => _currentIndex = 3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade900),
                          icon: const Icon(Icons.store, size: 18),
                          label: const Text('إيجار جديد'),
                          onPressed: () => setState(() => _currentIndex = 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue.shade100, foregroundColor: Colors.indigo.shade900),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('دين جديد'),
                          onPressed: () => setState(() => _currentIndex = 2),
                        ),
                      ),
                    ],
                  ),
                ),
                // شريط البحث العام
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث عن صنف أو زبون...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => globalSearch = v.trim()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: globalSearch.isNotEmpty ? GlobalSearchResults(query: globalSearch) : _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.amber.shade800,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() { _currentIndex = i; globalSearch = ''; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
          BottomNavigationBarItem(icon: Icon(Icons.handyman), label: 'الإيجار'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'الديون'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'بيع'),
        ],
      ),
    );
  }
}

class GlobalSearchResults extends StatelessWidget {
  final String query;
  const GlobalSearchResults({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final items = store.items.where((e) => e.name.contains(query) || e.section.contains(query)).toList();
    final debts = store.debts.where((e) => e.name.contains(query) || e.date.contains(query)).toList();
    final rents = store.rents.where((e) => e.name.contains(query) || e.date.contains(query)).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('نتائج البحث الشامل عن: "$query"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        const Text('المخزن:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        ...items.map((e) => ListTile(title: Text(e.name), subtitle: Text('السعر: ${e.price} \vert{} القسم: ${e.section}'))),
        const Divider(),
        const Text('الديون:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        ...debts.map((e) => ListTile(title: Text(e.name), subtitle: Text('المبلغ: ${e.amount} \vert{} التاريخ: ${e.date}'))),
        const Divider(),
        const Text('الإيجار:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        ...rents.map((e) => ListTile(title: Text(e.name), subtitle: Text('المبلغ: ${e.amount} \vert{} التاريخ: ${e.date}'))),
      ],
    );
  }
}

// 1. قسم المخزن
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String search = '';
  String? sectionFilter;

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final filtered = store.items.where((i) {
      bool mSearch = i.name.contains(search) || i.section.contains(search);
      bool mSec = sectionFilter == null || sectionFilter == 'الكل' || i.section == sectionFilter;
      return mSearch && mSec;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8
