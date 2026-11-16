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
  int _currentIndex = 3; // المخزن افتراضياً
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
                // أزرار الاختصارات السريعة أسفل البحث
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade100, foregroundColor: Colors.teal.shade900),
                          icon: const Icon(Icons.store, size: 18),
                          label: const Text('إيجار جديد'),
                          onPressed: () => setState(() => _currentIndex = 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade900),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('دين جديد'),
                          onPressed: () => setState(() => _currentIndex = 2),
                        ),
                      ),
                    ],
                  ),
                ),
                // خانة البحث الشامل
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'بحث عام (المخزن، الديون، الإيجارات)...',
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
        ...items.map((e) => ListTile(title: Text(e.name), subtitle: Text('السعر: ${e.price} | القسم: ${e.section}'))),
        const Divider(),
        const Text('الديون:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        ...debts.map((e) => ListTile(title: Text(e.name), subtitle: Text('المبلغ: ${e.amount} | التاريخ: ${e.date}'))),
        const Divider(),
        const Text('الإيجار:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        ...rents.map((e) => ListTile(title: Text(e.name), subtitle: Text('المبلغ: ${e.amount} | التاريخ: ${e.date}'))),
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
                        : const Icon(Icons.inventory_2, color: Colors.amber, size: 40),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('القسم: ${item.section.isEmpty ? "عام" : item.section} | المتوفر: ${item.quantity}'),
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

// 2. قسم الديون (مع البحث الذكي بالحرف وتغيير الاسم والتاريخ والألوان)
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
    final filtered = store.debts.where((d) => d.name.toLowerCase().contains(search.toLowerCase()) || d.date.contains(search)).toList();

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
                      Text('إجمالي الديون المستحقة', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      Text('$totalDebts د.ع', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('المستلم: $totalReceived د.ع', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('مدينون', style: TextStyle(color: Colors.white.withOpacity(0.7))),
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
                store.updateDebt(debt.id, nameC.text, double.tryParse(amountC.text) ?? 0.0, dateC.text, isPaid);
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

// 3. قسم الإيجار (مع الإكمال التلقائي وتغيير التاريخ والاسم)
class RentsScreen extends StatefulWidget {
  const RentsScreen({super.key});
  @override
  State<RentsScreen> createState() => _RentsScreenState();
}

class _RentsScreenState extends State<RentsScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final filtered = store.rents.where((r) => r.name.toLowerCase().contains(search.toLowerCase()) || r.date.contains(search)).toList();

    double totalRents = store.rents.fold(0.0, (s, e) => s + e.amount);
    int renterCount = store.rents.map((e) => e.name).toSet().length;

    return Scaffold(
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            color: Colors.teal.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إجمالي إيرادات الإيجار', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      Text('$totalRents د.ع', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('المؤجرون', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      Text('$renterCount', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'بحث في الإيجارات...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final r = filtered[index];
                Color rColor = r.isReturned ? Colors.red : Colors.blue;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('المبلغ: ${r.amount} د.ع\nالتاريخ: ${r.date}', style: TextStyle(color: rColor, fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: r.isReturned,
                          activeColor: Colors.red,
                          onChanged: (v) => store.updateRent(r.id, r.name, r.amount, r.date, v),
                        ),
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showDialog(context, store, rent: r)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => store.removeRent(r.id)),
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

  void _showDialog(BuildContext context, StoreData store, {RentItem? rent}) {
    final nameC = TextEditingController(text: rent?.name ?? '');
    final amountC = TextEditingController(text: rent?.amount.toString() ?? '');
    final dateC = TextEditingController(text: rent?.date ?? DateTime.now().toString().substring(0, 10));
    bool isReturned = rent?.isReturned ?? false;
    List<String> names = store.rents.map((e) => e.name).toSet().toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rent == null ? 'تسجيل إيجار جديد' : 'تعديل إيجار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              optionsBuilder: (textVal) => textVal.text.isEmpty ? const Iterable.empty() : names.where((n) => n.contains(textVal.text)),
              onSelected: (sel) => nameC.text = sel,
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                if (controller.text.isEmpty && nameC.text.isNotEmpty) controller.text = nameC.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'اسم المؤجر (إكمال تلقائي)'),
                  onChanged: (v) => nameC.text = v,
                );
              },
            ),
            TextField(controller: amountC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
            TextField(controller: dateC, decoration: const InputDecoration(labelText: 'التاريخ (تعديل متاح)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.isEmpty) return;
              if (rent == null) {
                store.addRent(RentItem(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameC.text, amount: double.tryParse(amountC.text) ?? 0.0, date: dateC.text, isReturned: isReturned));
              } else {
                store.updateRent(rent.id, nameC.text, double.tryParse(amountC.text) ?? 0.0, dateC.text, isReturned);
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    return Scaffold(
      body: Center(
        child: Text('إجمالي الأصناف: ${store.items.length}\nإجمالي الديون: ${store.debts.length}\nإجمالي الإيجارات: ${store.rents.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ),
    );
  }
}

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('شاشة نقطة البيع السريع (الكاشير)', style: TextStyle(fontSize: 18))));
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final nameC = TextEditingController(text: store.storeName);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات والتحكم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('بيانات المحل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
          TextField(
            controller: nameC,
            decoration: const InputDecoration(labelText: 'اسم المحل'),
            onChanged: (v) { store.storeName = v; store.saveData(); },
          ),
          const Divider(),
          const Text('النسخ الاحتياطي والمزامنة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
          SwitchListTile(
            title: const Text('حفظ تلقائي للبيانات'),
            value: store.autoBackup,
            onChanged: (v) { store.autoBackup = v; store.saveData(); },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code, color: Colors.amber),
            title: const Text('مشاركة واستعادة النسخة عبر الباركود (بدون إنترنت)'),
            subtitle: const Text('توليد وقراءة باركود قاعدة البيانات'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRBackupScreen(storeData: store))),
          ),
          const Divider(),
          const Text('إدارة الأقسام (غير محدودة)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('إضافة قسم جديد للمخزن'),
            onPressed: () => _showSectionDialog(context, store),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: store.customSections.map((s) => Chip(label: Text(s), onDeleted: () => store.removeSection(s))).toList(),
          ),
        ],
      ),
    );
  }

  void _showSectionDialog(BuildContext context, StoreData store) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة قسم جديد'),
        content: TextField(controller: c, decoration: const InputDecoration(labelText: 'اسم القسم')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () { if (c.text.isNotEmpty) { store.addSection(c.text); Navigator.pop(context); } }, child: const Text('إضافة')),
        ],
      ),
    );
  }
}
