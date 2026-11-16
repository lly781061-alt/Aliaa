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
                          onPressed: () => _openAddStore(context, store),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade900),
                          icon: const Icon(Icons.store, size: 18),
                          label: const Text('إيجار جديد'),
                          onPressed: () => _openAddRent(context, store),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue.shade100, foregroundColor: Colors.indigo.shade900),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('دين جديد'),
                          onPressed: () => _openAddDebt(context, store),
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

  void _openAddStore(BuildContext context, StoreData store) { setState(() => _currentIndex = 3); }
  void _openAddRent(BuildContext context, StoreData store) { setState(() => _currentIndex = 1); }
  void _openAddDebt(BuildContext context, StoreData store) { setState(() => _currentIndex = 2); }
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
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ChoiceChip(label: const Text('الكل'), selected: sectionFilter == null || sectionFilter == 'الكل', onSelected: (_) => setState(() => sectionFilter = 'الكل')),
                ...store.customSections.map((sec) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(label: Text(sec), selected: sectionFilter == sec, onSelected: (_) => setState(() => sectionFilter = sec)),
                )),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                Color pColor = Colors.blue;
                if (item.priceColor == 'red') pColor = Colors.red;
                if (item.priceColor == 'green') pColor = Colors.green;
                if (item.priceColor == 'orange') pColor = Colors.orange;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: item.imagePath != null && File(item.imagePath!).existsSync()
                        ? Image.file(File(item.imagePath!), width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.flash_on, color: Colors.orange, size: 40),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item.section.isEmpty ? "عام" : item.section} · المتوفر: ${item.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${item.price} د.ع', style: TextStyle(color: pColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showDialog(context, store, item: item)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => store.removeItem(item.id)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showDialog(context, store), child: const Icon(Icons.add)),
    );
  }

  void _showDialog(BuildContext context, StoreData store, {StoreItem? item}) {
    final nameC = TextEditingController(text: item?.name ?? '');
    final priceC = TextEditingController(text: item?.price.toString() ?? '');
    final qtyC = TextEditingController(text: item?.quantity.toString() ?? '1');
    String sec = item?.section ?? '';
    String color = item?.priceColor ?? 'blue';
    String? img = item?.imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: Text(item == null ? 'إضافة صنف جديد' : 'تعديل صنف'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'اسم الصنف')),
                TextField(controller: priceC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر')),
                TextField(controller: qtyC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية المتوفرة')),
                DropdownButtonFormField<String>(
                  value: store.customSections.contains(sec) ? sec : null,
                  decoration: const InputDecoration(labelText: 'القسم (اختياري)'),
                  items: store.customSections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setD(() => sec = v ?? ''),
                ),
                DropdownButtonFormField<String>(
                  value: color,
                  decoration: const InputDecoration(labelText: 'لون السعر'),
                  items: const [
                    DropdownMenuItem(value: 'blue', child: Text('أزرق')),
                    DropdownMenuItem(value: 'red', child: Text('أحمر')),
                    DropdownMenuItem(value: 'green', child: Text('أخضر')),
                    DropdownMenuItem(value: 'orange', child: Text('برتقالي')),
                  ],
                  onChanged: (v) => setD(() => color = v ?? 'blue'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('اختيار صورة الصنف'),
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (picked != null) setD(() => img = picked.path);
                  },
                ),
                if (img != null) Image.file(File(img!), height: 60, width: 60, fit: BoxFit.cover),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameC.text.isEmpty) return;
                final newItem = StoreItem(
                  id: item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameC.text,
                  price: double.tryParse(priceC.text) ?? 0.0,
                  quantity: int.tryParse(qtyC.text) ?? 1,
                  section: sec,
                  imagePath: img,
                  priceColor: color,
                );
                item == null ? store.addItem(newItem) : store.updateItem(newItem);
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. قسم الديون
class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final filtered = store.debts.where((d) => d.name.contains(search) || d.date.contains(search)).toList();

    double totalDebts = store.debts.where((e) => !e.isPaid).fold(0.0, (s, e) => s + e.amount);
    double totalReceived = store.debts.where((e) => e.isPaid).fold(0.0, (s, e) => s + e.amount);
    int debtorCount = store.debts.map((e) => e.name).toSet().length;

    return Scaffold(
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            color: Colors.blue.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إجمالي الديون المستحقة', style: TextStyle(color: Colors.white70)),
                      Text('$totalDebts د.ع', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('مدينون', style: TextStyle(color: Colors.white70)),
                      Text('$debtorCount', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'بحث ذكي بالحرف في الديون...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final d = filtered[index];
                Color dateColor = d.isPaid ? Colors.red : Colors.blue;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('المبلغ: ${d.amount} د.ع\nالتاريخ: ${d.date}', style: TextStyle(color: dateColor, fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: d.isPaid,
                          activeColor: Colors.red,
                          onChanged: (v) => store.updateDebt(d.id, d.name, d.amount, d.date, v),
                        ),
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showDialog(context, store, debt: d)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => store.removeDebt(d.id)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showDialog(context, store), child: const Icon(Icons.add)),
    );
  }

  void _showDialog(BuildContext context, StoreData store, {DebtItem? debt}) {
    final nameC = TextEditingController(text: debt?.name ?? '');
    final amountC = TextEditingController(text: debt?.amount.toString() ?? '');
    final dateC = TextEditingController(text: debt?.date ?? DateTime.now().toString().substring(0, 10));
    bool isPaid = debt?.isPaid ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(debt == null ? 'تسجيل دين جديد' : 'تعديل دين'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'اسم الشخص')),
            TextField(controller: amountC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
            TextField(controller: dateC, decoration: const InputDecoration(labelText: 'التاريخ (تعديل متاح)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.isEmpty) return;
              if (debt == null) {
                store.addDebt(DebtItem(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameC.text, amount: double.tryParse(amountC.text) ?? 0.0, date: dateC.text, isPaid: isPaid));
              } else {
                store.updateDebt(debt.id, nameC.text, double.tryParse(amountC
