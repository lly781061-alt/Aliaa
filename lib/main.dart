import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'store.dart';
import 'export.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => StoreData(),
      child: const StoreApp(),
    ),
  );
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'متجر برو الشامل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
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
  int _currentIndex = 0;
  String globalSearchQuery = '';

  final List<Widget> _screens = [
    const InventoryScreen(),
    const DebtsScreen(),
    const RentsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المتجر الشاملة'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث عام (في المخزن، الديون، والإيجار)...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                setState(() {
                  globalSearchQuery = val.trim();
                });
              },
            ),
          ),
        ),
      ),
      body: globalSearchQuery.isNotEmpty
          ? GlobalSearchResults(query: globalSearchQuery)
          : _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            globalSearchQuery = '';
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory), label: 'المخزن'),
          NavigationDestination(icon: Icon(Icons.money), label: 'الديون'),
          NavigationDestination(icon: Icon(Icons.car_rental), label: 'الإيجار'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

// ---------------- GLOBAL SEARCH RESULTS ----------------
class GlobalSearchResults extends StatelessWidget {
  final String query;
  const GlobalSearchResults({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final matchedItems = store.items.where((e) => e.name.contains(query) || e.section.contains(query)).toList();
    final matchedDebts = store.debts.where((e) => e.name.contains(query)).toList();
    final matchedRents = store.rents.where((e) => e.name.contains(query)).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('نتائج البحث عن: "$query"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        const Text('المخزن:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        ...matchedItems.map((e) => ListTile(title: Text(e.name), subtitle: Text('السعر: ${e.price} \vert{} القسم: ${e.section}'))),
        const Divider(),
        const Text('الديون:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        ...matchedDebts.map((e) => ListTile(title: Text(e.name), subtitle: Text('المبلغ: ${e.amount} \vert{} التاريخ: ${e.date}'))),
        const Divider(),
        const Text('الإيجار:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        ...matchedRents.map((e) => ListTile(title: Text(e.name), subtitle: Text('المبلغ: ${e.amount} \vert{} التاريخ: ${e.date}'))),
      ],
    );
  }
}

// ---------------- 1. INVENTORY SCREEN ----------------
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String searchQuery = '';
  String? selectedSectionFilter;

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    
    var filteredItems = store.items.where((item) {
      final matchesSearch = item.name.contains(searchQuery) || item.section.contains(searchQuery);
      final matchesSection = selectedSectionFilter == null || selectedSectionFilter == 'الكل' || item.section == selectedSectionFilter;
      return matchesSearch && matchesSection;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'بحث في المخزن...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                    onChanged: (val) => setState(() => searchQuery = val),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedSectionFilter,
                  hint: const Text('كل الأقسام'),
                  items: ['الكل', ...store.customSections].map((sec) => DropdownMenuItem(value: sec, child: Text(sec))).toList(),
                  onChanged: (val) => setState(() => selectedSectionFilter = val),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                Color priceColor = Colors.blue;
                if (item.priceColor == 'red') priceColor = Colors.red;
                if (item.priceColor == 'green') priceColor = Colors.green;
                if (item.priceColor == 'orange') priceColor = Colors.orange;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: item.imagePath != null && File(item.imagePath!).existsSync()
                        ? Image.file(File(item.imagePath!), width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.inventory_2, size: 40),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('القسم: ${item.section.isEmpty ? "بدون قسم" : item.section} \vert{} الكمية: ${item.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${item.price}', style: TextStyle(color: priceColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showItemDialog(context, store, item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => store.removeItem(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(context, store),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showItemDialog(BuildContext context, StoreData store, {StoreItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    final qtyController = TextEditingController(text: item?.quantity.toString() ?? '1');
    String selectedSection = item?.section ?? (store.customSections.isNotEmpty ? store.customSections.first : '');
    String selectedColor = item?.priceColor ?? 'blue';
    String? imagePath = item?.imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(item == null ? 'إضافة صنف جديد' : 'ت
