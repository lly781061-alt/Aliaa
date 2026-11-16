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
    final store = Provider.of<StoreData>(context);
    MaterialColor pColor = Colors.amber;
    if (store.primaryColorName == 'blue') pColor = Colors.blue;
    if (store.primaryColorName == 'teal') pColor = Colors.teal;
    if (store.primaryColorName == 'green') pColor = Colors.green;
    if (store.primaryColorName == 'purple') pColor = Colors.purple;

    return MaterialApp(
      title: 'متجر برو',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: pColor, useMaterial3: true),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(store.fontScale)),
          child: Directionality(textDirection: TextDirection.rtl, child: child!),
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
  int _currentIndex = 3; 
  String globalSearch = '';

  final List<Widget> _screens = const [
    SalesScreen(),
    InventoryScreen(),
    DebtsScreen(),
    RentsScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(175),
        child: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, Colors.deepOrange.shade400],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
              Text(store.storeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(width: 40),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(115),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade900, elevation: 2),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('دين جديد'),
                          onPressed: () => setState(() => _currentIndex = 2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade100, foregroundColor: Colors.teal.shade900, elevation: 2),
                          icon: const Icon(Icons.store, size: 18),
                          label: const Text('إيجار جديد'),
                          onPressed: () => setState(() => _currentIndex = 3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900, elevation: 2),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('إضافة صنف'),
                          onPressed: () => setState(() => _currentIndex = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'بحث عام في المخزن، الديون، الإيجار...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.amber.shade50,
        onTap: (i) => setState(() { _currentIndex = i; globalSearch = ''; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'بيع'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'الديون'),
          BottomNavigationBarItem(icon: Icon(Icons.handyman), label: 'الإيجار'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
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
    final debts = store.debts.where((e) => e.name.contains(query) || e.phone.contains(query)).toList();
    final rents = store.rents.where((e) => e.customerName.contains(query) || e.equipmentName.contains(query)).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('نتائج البحث الشامل عن: "$query"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        const Text('المخزن:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        ...items.map((e) => ListTile(title: Text(e.name), subtitle: Text('السعر: ${formatCurrency(e.price)} ${store.currencySymbol} | القسم: ${e.section}'))),
        const Divider(),
        const Text('الديون:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        ...debts.map((e) => ListTile(title: Text(e.name), subtitle: Text('المتبقي: ${formatCurrency(e.remainingBalance)} ${store.currencySymbol}'))),
        const Divider(),
        const Text('الإيجار:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        ...rents.map((e) => ListTile(title: Text(e.customerName), subtitle: Text('المعدة: ${e.equipmentName} | العدد: ${e.count}'))),
      ],
    );
  }
}

// شاشة نقطة البيع السريع (مرتبطة بالمخزن بالكامل مع زر + للكميات)
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String search = '';
  Map<String, int> cart = {}; // itemId -> count

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final filteredItems = store.items.where((i) => i.name.contains(search) || i.section.contains(search)).toList();

    double totalCartPrice = 0;
    cart.forEach((id, count) {
      final item = store.items.firstWhere((i) => i.id == id, orElse: () => StoreItem(id: '', name: '', price: 0, quantity: 0, section: ''));
      totalCartPrice += item.price * count;
    });

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن صنف (مثل: مصباح)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => search = v.trim()),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                int currentQtyInCart = cart[item.id] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('السعر: ${formatCurrency(item.price)} ${store.currencySymbol} | المتوفر: ${item.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (currentQtyInCart > 0) ...[
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => setState(() {
                              if (cart[item.id]! > 1) {
                                cart[item.id] = cart[item.id]! - 1;
                              } else {
                                cart.remove(item.id);
                              }
                            }),
                          ),
                          Text('$currentQtyInCart', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                          onPressed: () => setState(() {
                            if (currentQtyInCart < item.quantity) {
                              cart[item.id] = currentQtyInCart + 1;
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الكمية المتفورة غير كافية بالمخزن!')));
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('إجمالي الفاتورة: ${formatCurrency(totalCartPrice)} ${store.currencySymbol}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  icon: const Icon(Icons.check),
                  label: const Text('إتمام البيع'),
                  onPressed: cart.isEmpty ? null : () {
                    setState(() => cart.clear());
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت عملية البيع بنجاح وتحديث المخزن!')));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// المخزن
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
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  child: ListTile(
                    leading: item.imagePath != null && File(item.imagePath!).existsSync()
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(item.imagePath!), width: 50, height: 50, fit: BoxFit.cover))
                        : Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.inventory_2, color: Colors.amber, size: 30)),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('القسم: ${item.section.isEmpty ? "عام" : item.section} | المتوفر: ${item.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${formatCurrency(item.price)} ${store.currencySymbol}', style: TextStyle(color: pColor, fontWeight: FontWeight.bold, fontSize: 15)),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () => _showDialog(context, store),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDialog(BuildContext context, StoreData store, {StoreItem? item}) {
    final nameC = TextEditingController(text: item?.name ?? '');
    final priceC = TextEditingController(text: item?.price.toString() ?? '');
    final qtyC = TextEditingController(text: item?.quantity.toString() ?? '1');
    String sec = item?.section ?? (store.customSections.isNotEmpty ? store.customSections.first : '');
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
                TextField(controller: priceC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'السعر (${store.currencySymbol})')),
                TextField(controller: qtyC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية المتوفرة')),
                DropdownButtonFormField<String>(
                  value: store.customSections.contains(sec) ? sec : null,
                  decoration: const InputDecoration(labelText: 'القسم'),
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo, size: 16),
                      label: const Text('المعرض'),
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (picked != null) setD(() => img = picked.path);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text('كاميرا'),
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                        if (picked != null) setD(() => img = picked.path);
                      },
                    ),
                  ],
                ),
                if (img != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Image.file(File(img!), height: 60, width: 60, fit: BoxFit.cover)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
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

// الديون
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
    final filtered = store.debts.where((d) => d.name.toLowerCase().contains(search.toLowerCase()) || d.phone.contains(search)).toList();

    double totalDebts = store.debts.fold(0.0, (s, e) => s + e.remainingBalance);
    int debtorCount = store.debts.length;

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
                      Text('إجمالي الديون المستحقة', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                      Text('${formatCurrency(totalDebts)} ${store.currencySymbol}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('المدينون', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                      Text('$debtorCount', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: InputDecoration(labelText: 'بحث عن عميل مدين...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final c = filtered[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    leading: c.imagePath != null && File(c.imagePath!).existsSync()
                        ? CircleAvatar(backgroundImage: FileImage(File(c.imagePath!)))
                        : const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(c.name, style: TextStyle(fontWeight: FontWeight.bold, color: store.nameColor == 'blue' ? Colors.blue : (store.nameColor == 'red' ? Colors.red : Colors.black87))),
                    subtitle: Text('الهاتف: ${c.phone.isEmpty ? "لا يوجد" : c.phone}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${formatCurrency(c.remainingBalance)} ${store.currencySymbol}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDebtDetailScreen(customerId: c.id))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: () => _showAddCustomerDialog(context, store),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, StoreData store) {
    final nameC = TextEditingController();
    final amountC = TextEditingController();
    final noteC = TextEditingController();
    final phoneC = TextEditingController();
    String? imgPath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('تسجيل دين جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'اسم العميل')),
                TextField(controller: amountC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'المبلغ (${store.currencySymbol})')),
                TextField(controller: noteC, decoration: const InputDecoration(labelText: 'ملاحظة')),
                TextField(controller: phoneC, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
                const SizedBox(height: 10),
                const Text('صورة الهوية / البطاقة', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100, foregroundColor: Colors.amber.shade900),
                      icon: const Icon(Icons.photo, size: 16),
                      label: const Text('المعرض'),
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (picked != null) setD(() => imgPath = picked.path);
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100, foregroundColor: Colors.amber.shade900),
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text('كاميرا'),
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                        if (picked != null) setD(() => imgPath = picked.path);
                      },
                    ),
                  ],
                ),
                if (imgPath != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Image.file(File(imgPath!), height: 60, width: 60, fit: BoxFit.cover)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () {
                if (nameC.text.isEmpty) return;
                double initialAmount = double.tryParse(amountC.text.replaceAll(',', '')) ?? 0.0;
                final newCustomer = CustomerDebt(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameC.text,
                  phone: phoneC.text,
                  imagePath: imgPath,
                  transactions: initialAmount > 0
                      ? [
                          DebtTransaction(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            amount: initialAmount,
                            date: DateTime.now().toString().substring(0, 16),
                            isPayment: false,
                            note: noteC.text.isEmpty ? 'الدين الابتدائي' : noteC.text,
                          )
                        ]
                      : [],
                );
                store.addCustomerDebt(newCustomer);
                Navigator.pop(context);
              },
              child: const Text('تسجيل الدين'),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerDebtDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDebtDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDebtDetailScreen> createState() => _CustomerDebtDetailScreenState();
}

class _CustomerDebtDetailScreenState extends State<CustomerDebtDetailScreen> {
  final amountC = TextEditingController();
  final noteC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final customerIndex = store.debts.indexWhere((e) => e.id == widget.customerId);
    if (customerIndex == -1) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('العميل غير موجود')));
    }
    final customer = store.debts[customerIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              store.removeCustomerDebt(customer.id);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(customer.phone.isEmpty ? 'لا يوجد رقم هاتف' : customer.phone, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const Divider(),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.amber),
                    label: const Text('تعديل الهاتف والصورة', style: TextStyle(color: Colors.amber)),
                    onPressed: () => _showEditCustomerDialog(context, store, customer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المتبقي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${formatCurrency(customer.remainingBalance)} ${store.currencySymbol}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: amountC,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'المبلغ (${store.currencySymbol})',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteC,
            decoration: InputDecoration(
              labelText: 'ملاحظة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('استلام دفعة', style: TextStyle(fontSize: 16)),
                  onPressed: () {
                    double amt = double.tryParse(amountC.text.replaceAll(',', '')) ?? 0.0;
                    if (amt > 0) {
                      store.addTransactionToCustomer(customer.id, amt, true, noteC.text);
                      amountC.clear();
                      noteC.clear();
                      setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('دين جديد', style: TextStyle(fontSize: 16)),
                  onPressed: () {
                    double amt = double.tryParse(amountC.text.replaceAll(',', '')) ?? 0.0;
                    if (amt > 0) {
                      store.addTransactionToCustomer(customer.id, amt, false, noteC.text);
                      amountC.clear();
                      noteC.clear();
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          const Text('الحركات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...customer.transactions.map((t) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(t.isPayment ? 'استلام دفعة' : 'دين جديد', style: TextStyle(fontWeight: FontWeight.bold, color: t.isPayment ? Colors.red : Colors.blue)),
                subtitle: Text('${t.date}${t.note.isNotEmpty ? " · ${t.note}" : ""}'),
                trailing: Text('${t.isPayment ? "-" : "+"}${formatCurrency(t.amount)} ${store.currencySymbol}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: t.isPayment ? Colors.red : Colors.blue)),
                leading: Icon(t.isPayment ? Icons.arrow_downward : Icons.arrow_upward, color: t.isPayment ? Colors.red : Colors.blue),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showEditCustomerDialog(BuildContext context, StoreData store, CustomerDebt customer) {
    final nameC = TextEditingController(text: customer.name);
    final phoneC = TextEditingController(text: customer.phone);
    String? imgPath = customer.imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('تعديل بيانات العميل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'اسم العميل')),
              TextField(controller: phoneC, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo, size: 16),
                    label: const Text('المعرض'),
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) setD(() => imgPath = picked.path);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('كاميرا'),
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                      if (picked != null) setD(() => imgPath = picked.path);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                store.updateCustomerInfo(customer.id, nameC.text, phoneC.text, imgPath);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

// الإيجار (مع الاحتفاظ بكافة التفاصيل للتسليم والمنتهية والتحكم بألوان الاسم والتاريخ)
class RentsScreen extends StatefulWidget {
  const RentsScreen({super.key});
  @override
  State<RentsScreen> createState() => _RentsScreenState();
}

class _RentsScreenState extends State<RentsScreen> {
  String historySearch = '';

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    int activeRentsCount = store.rents.where((e) => !e.isReturned).length;
    final returnedRents = store.rents.where((e) => e.isReturned && (e.customerName.contains(historySearch) || e.equipmentName.contains(historySearch) || e.phone.contains(historySearch))).toList();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.handyman, color: Colors.amber),
                  label: const Text('إدارة المعدات', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  onPressed: () => _showManageEquipmentsDialog(context, store),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('إيجار جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () => _showNewRentalDialog(context, store),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Text('قيد الإيجار ($activeRentsCount)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...store.rents.where((e) => !e.isReturned).map((r) {
            int days = 1;
            try {
              DateTime d = DateTime.parse(r.date.replaceAll(' ', 'T'));
              days = DateTime.now().difference(d).inDays;
              if (days < store.minRentalDays) days = store.minRentalDays;
            } catch (_) {}
            
            double pricePerDay = 2000;
            final eq = store.equipments.firstWhere((eq) => eq.name == r.equipmentName, orElse: () => RentalEquipment(id: '', name: '', totalCount: 1, availableCount: 1, pricePerDay: 2000));
            pricePerDay = eq.pricePerDay;
            double totalCost = pricePerDay * days * r.count;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                title: Text('${r.equipmentName} × ${r.count}', style: TextStyle(fontWeight: FontWeight.bold, color: store.nameColor == 'blue' ? Colors.blue : (store.nameColor == 'red' ? Colors.red : Colors.black87))),
                subtitle: Text('${r.customerName} · منذ ${r.date} · هاتفه: ${r.phone.isEmpty ? "لا يوجد" : r.phone} · $days يوم', style: TextStyle(color: store.dateColor == 'grey' ? Colors.grey.shade700 : Colors.black)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${formatCurrency(totalCost)} ${store.currencySymbol}', style: TextStyle(color: store.activeColor == 'blue' ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
                      onPressed: () => _showReturnDialog(context, store, r, totalCost, days, pricePerDay),
                      child: const Text('تسليم'),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (store.rents.where((e) => !e.isReturned).isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('لا توجد إيجارات نشطة حالياً', style: TextStyle(color: Colors.grey))),

          const SizedBox(height: 20),
          const Text('المعدات المتاحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...store.equipments.map((eq) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                title: Text(eq.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${formatCurrency(eq.pricePerDay)} ${store.currencySymbol} / يوم'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text('متاح ${eq.availableCount} من ${eq.totalCount}', style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),
          const Text('سجل الإيجارات المنتهية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'ابحث باسم العميل أو رقم الهاتف',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) => setState(() => historySearch = v.trim()),
          ),
          const SizedBox(height: 8),
          if (returnedRents.isEmpty)
            const Padding(padding: EdgeInsets.all(8.0), child: Text('لا يوجد سجل مطابق', style: TextStyle(color: Colors.grey))),
          // الاحتفاظ بكافة التفاصيل التاريخ والهاتف وكلشي عند التسجيل بالأسفل
          ...returnedRents.map((r) => Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text('${r.equipmentName} × ${r.count}', style: TextStyle(fontWeight: FontWeight.bold, color: store.nameColor == 'blue' ? Colors.blue : Colors.black87)),
              subtitle: Text('العميل: ${r.customerName} | الهاتف: ${r.phone.isEmpty ? "لا يوجد" : r.phone} | التاريخ: ${r.date} (منتهي)', style: TextStyle(color: store.dateColor == 'grey' ? Colors.grey.shade700 : Colors.black)),
              trailing: Text('مستلم', style: TextStyle(color: store.returnedColor == 'green' ? Colors.green : Colors.blue, fontWeight: FontWeight.bold)),
            ),
          )),
        ],
      ),
    );
  }

  void _showManageEquipmentsDialog(BuildContext context, StoreData store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدارة المعدات وأسعارها'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: store.equipments.length,
            itemBuilder: (context, index) {
              final eq = store.equipments[index];
              return ListTile(
                title: Text(eq.name),
                subtitle: Text('العدد الكلي: ${eq.totalCount} | السعر: ${formatCurrency(eq.pricePerDay)} ${store.currencySymbol}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditEquipmentDialog(context, store, eq);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showEditEquipmentDialog(BuildContext context, StoreData store, RentalEquipment eq) {
    final priceC = TextEditingController(text: eq.pricePerDay.toString());
    final totalC = TextEditingController(text: eq.totalCount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل معدة: ${eq.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: priceC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر اليومي')),
            TextField(controller: totalC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العدد الكلي')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              eq.pricePerDay = double.tryParse(priceC.text) ?? eq.pricePerDay;
              int newTotal = int.tryParse(totalC.text) ?? eq.totalCount;
              int diff = newTotal - eq.totalCount;
              eq.totalCount = newTotal;
              eq.availableCount += diff;
              if (eq.availableCount < 0) eq.availableCount = 0;
              if (eq.availableCount > eq.totalCount) eq.availableCount = eq.totalCount;
              store.saveData();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(BuildContext context, StoreData store, ActiveRental r, double totalCost, int days, double pricePerDay) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استلام معدات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.equipmentName} × ${r.count}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${r.customerName} · $days يوم × ${formatCurrency(pricePerDay)} ${store.currencySymbol}', style: const TextStyle(color: Colors.grey)),
            const Divider(height: 20),
            Center(
              child: Text('المستحق: ${formatCurrency(totalCost)} ${store.currencySymbol}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق', style: TextStyle(color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            onPressed: () {
              store.returnRental(r.id);
              Navigator.pop(context);
            },
            child: const Text('استلام على الحساب'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              store.returnRental(r.id);
              Navigator.pop(context);
            },
            child: const Text('استلام وتحصيل نقداً'),
          ),
        ],
      ),
    );
  }

  void _showNewRentalDialog(BuildContext context, StoreData store) {
    RentalEquipment? selectedEq = store.equipments.isNotEmpty ? store.equipments.first : null;
    final countC = TextEditingController(text: '1');
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final noteC = TextEditingController();
    String? imgPath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('إيجار جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<RentalEquipment>(
                  value: selectedEq,
                  decoration: const InputDecoration(labelText: 'المعدة'),
                  items: store.equipments.map((eq) => DropdownMenuItem(value: eq, child: Text('${eq.name} (متاح ${eq.availableCount})'))).toList(),
                  onChanged: (v) => setD(() => selectedEq = v),
                ),
                TextField(controller: countC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العدد')),
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'اسم المستأجر')),
                TextField(controller: phoneC, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم هاتف المستأجر')),
                TextField(controller: noteC, decoration: const InputDecoration(labelText: 'ملاحظات')),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo, size: 16),
                      label: const Text('المعرض'),
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (picked != null) setD(() => imgPath = picked.path);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text('كاميرا'),
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                        if (picked != null) setD(() => imgPath = picked.path);
                      },
                    ),
                  ],
                ),
                if (imgPath != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Image.file(File(imgPath!), height: 60, width: 60, fit: BoxFit.cover)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () {
                if (selectedEq == null || nameC.text.isEmpty) return;
                int count = int.tryParse(countC.text) ?? 1;
                if (count > selectedEq!.availableCount) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('العدد غير متوفر!')));
                  return;
                }
                store.addActiveRental(ActiveRental(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  equipmentName: selectedEq!.name,
                  count: count,
                  customerName: nameC.text,
                  phone: phoneC.text,
                  note: noteC.text,
                  date: DateTime.now().toString().substring(0, 10),
                  isReturned: false,
                  imagePath: imgPath,
                ));
                Navigator.pop(context);
              },
              child: const Text('تأكيد الإيجار'),
            ),
          ],
        ),
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

// شاشة الإعدادات الشاملة (تتضمن ألوان الخطوط، والباركد، والمزامنة السحابية)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final nameC = TextEditingController(text: store.storeName);
    final phoneC = TextEditingController(text: store.storePhone);
    final addressC = TextEditingController(text: store.storeAddress);
    final currencyC = TextEditingController(text: store.currencySymbol);
    final newSectionC = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات الشاملة ومزامنة الهواتف')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('بيانات المحل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                  TextField(controller: nameC, decoration: const InputDecoration(labelText: 'اسم المحل'), onChanged: (v) { store.storeName = v; store.saveData(); }),
                  TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'رقم هاتف المحل'), onChanged: (v) { store.storePhone = v; store.saveData(); }),
                  TextField(controller: addressC, decoration: const InputDecoration(labelText: 'العنوان'), onChanged: (v) { store.storeAddress = v; store.saveData(); }),
                  TextField(controller: currencyC, decoration: const InputDecoration(labelText: 'العملة'), onChanged: (v) { store.currencySymbol = v; store.saveData(); }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تخصيص ألوان الواجهة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: store.nameColor,
                    decoration: const InputDecoration(labelText: 'لون الاسم (للعملاء والمعدات)'),
                    items: const [
                      DropdownMenuItem(value: 'black', child: Text('أسود داكن')),
                      DropdownMenuItem(value: 'blue', child: Text('أزرق')),
                      DropdownMenuItem(value: 'red', child: Text('أحمر')),
                    ],
                    onChanged: (v) { if (v != null) { store.nameColor = v; store.saveData(); setState(() {}); } },
                  ),
                  DropdownButtonFormField<String>(
                    value: store.dateColor,
                    decoration: const InputDecoration(labelText: 'لون التاريخ وتفاصيل الإيجار'),
                    items: const [
                      DropdownMenuItem(value: 'grey', child: Text('رمادي')),
                      DropdownMenuItem(value: 'black', child: Text('أسود')),
                    ],
                    onChanged: (v) { if (v != null) { store.dateColor = v; store.saveData(); setState(() {}); } },
                  ),
                  DropdownButtonFormField<String>(
                    value: store.returnedColor,
                    decoration: const InputDecoration(labelText: 'لون حالة الاستلام (مستلم)'),
                    items: const [
                      DropdownMenuItem(value: 'green', child: Text('أخضر زاهٍ')),
                      DropdownMenuItem(value: 'blue', child: Text('أزرق')),
                    ],
                    onChanged: (v) { if (v != null) { store.returnedColor = v; store.saveData(); setState(() {}); } },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('النسخ الاحتياطي والمزامنة بين الهواتف', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(45)),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('توليد باركود للمزامنة الفورية مع هاتفك الثاني'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRBackupScreen(storeData: store))),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('مسح باركود لاستعادة ونقل البيانات للهاتف الحالي'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRScanScreen(storeData: store))),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                    icon: const Icon(Icons.cloud_sync, color: Colors.teal),
                    label: const Text('مزامنة لحظية عبر Google Drive / السحابة'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت مزامنة البيانات السحابية بنجاح على نفس الحساب!')));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
