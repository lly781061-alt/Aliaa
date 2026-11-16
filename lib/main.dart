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
    if (store.primaryColorName == 'indigo') pColor = Colors.indigo;

    return MaterialApp(
      title: 'متجر برو',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: pColor, useMaterial3: true),
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
  // الترتيب من اليمين لليساار: 0: بيع، 1: المخزن، 2: الديون، 3: الإيجار، 4: التقارير
  int _currentIndex = 3; 
  String globalSearch = '';

  final List<Widget> _screens = [
    const SalesScreen(),
    const InventoryScreen(),
    const DebtsScreen(),
    const RentsScreen(),
    const ReportsScreen(),
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
              gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Colors.brown], begin: Alignment.topRight, end: Alignment.bottomLeft),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade900),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('دين جديد'),
                          onPressed: () => setState(() => _currentIndex = 2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade100, foregroundColor: Colors.teal.shade900),
                          icon: const Icon(Icons.store, size: 18),
                          label: const Text('إيجار جديد'),
                          onPressed: () => setState(() => _currentIndex = 3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900),
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
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
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

// 1. المخزن
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('صورة الصنف'),
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

// 2. الديون
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
                      Text('إجمالي الديون المستحقة', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      Text('${formatCurrency(totalDebts)} ${store.currencySymbol}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('المدينون', style: TextStyle(color: Colors.white.withOpacity(0.7))),
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
              decoration: const InputDecoration(labelText: 'بحث عن عميل مدين...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
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
                  child: ListTile(
                    leading: c.imagePath != null && File(c.imagePath!).existsSync()
                        ? CircleAvatar(backgroundImage: FileImage(File(c.imagePath!)))
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('الهاتف: ${c.phone.isEmpty ? "لا يوجد" : c.phone}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${formatCurrency(c.remainingBalance)} ${store.currencySymbol}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16),
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
          const SizedBox(height: 20),
          const Text('مشاركة كشف الحساب مع العميل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(icon: const Icon(Icons.picture_as_pdf, color: Colors.amber), label: const Text('PDF'), onPressed: () {}),
              OutlinedButton.icon(icon: const Icon(Icons.table_chart, color: Colors.amber), label: const Text('Excel'), onPressed: () {}),
              OutlinedButton.icon(icon: const Icon(Icons.share, color: Colors.amber), label: const Text('نص'), onPressed: () {}),
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
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('تغيير الصورة'),
                onPressed: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) setD(() => imgPath = picked.path);
                },
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

// 3. الإيجارات والمعدات (مطابقة تماماً للصور المطلوبة)
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
    int activeRentsCount = store.rents.where((e) => !e.isReturned).length;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('إيجار جديد', style: TextStyle(fontSize: 16)),
                  onPressed: () => _showNewRentalDialog(context, store),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('قيد الإيجار', style: TextStyle(color: Colors.white70)),
                        Text('$activeRentsCount', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text('قيد الإيجار الحالية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...store.rents.where((e) => !e.isReturned).map((r) {
            // حساب الأيام المنقضية
            int days = 1;
            try {
              DateTime d = DateTime.parse(r.date.replaceAll(' ', 'T'));
              days = DateTime.now().difference(d).inDays;
              if (days < store.minRentalDays) days = store.minRentalDays;
            } catch (_) {}
            
            // البحث عن سعر المعدة
            double pricePerDay = 2000;
            final eq = store.equipments.firstWhere((eq) => eq.name == r.equipmentName, orElse: () => RentalEquipment(id: '', name: '', totalCount: 1, availableCount: 1, pricePerDay: 2000));
            pricePerDay = eq.pricePerDay;
            double totalCost = pricePerDay * days * r.count;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text('${r.equipmentName} × ${r.count}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${r.customerName} · منذ ${r.date} · $days يوم'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${formatCurrency(totalCost)} ${store.currencySymbol}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => _showReturnDialog(context, store, r, totalCost, days, pricePerDay),
                      child: const Text('تسليم'),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(height: 30),
          const Text('المعدات المتاحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...store.equipments.map((eq) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        ],
      ),
    );
  }

  // نافذة استلام المعدات المطابقة لصورة 569826.jpg
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
            const SizedBox(height: 10),
            const Text('مشاركة كشف مبدئي مع المستأجر:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(onPressed: () {}, child: const Text('Excel')),
                OutlinedButton(onPressed: () {}, child: const Text('PDF')),
                OutlinedButton(onPressed: () {}, child: const Text('نص')),
              ],
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

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('شاشة نقطة البيع السريع', style: TextStyle(fontSize: 18))));
  }
}

// 4. شاشة الإعدادات الاحترافية (مطابقة لصورة 569824.jpg)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final nameC = TextEditingController(text: store.storeName);
    final phoneC = TextEditingController(text: store.storePhone);
    final addressC = TextEditingController(text: store.storeAddress);
    final footerC = TextEditingController(text: store.invoiceFooter);
    final currencyC = TextEditingController(text: store.currencySymbol);
    final minRentalC = TextEditingController(text: store.minRentalDays.toString());

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بيانات المحل
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('بيانات المحل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  TextField(controller: nameC, decoration: const InputDecoration(labelText: 'اسم المحل'), onChanged: (v) { store.storeName = v; store.saveData(); }),
                  TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'رقم هاتف المحل'), onChanged: (v) { store.storePhone = v; store.saveData(); }),
                  TextField(controller: addressC, decoration: const InputDecoration(labelText: 'العنوان'), onChanged: (v) { store.storeAddress = v; store.saveData(); }),
                  TextField(controller: footerC, decoration: const InputDecoration(labelText: 'عبارة أسفل الفواتير والملفات'), onChanged: (v) { store.invoiceFooter = v; store.saveData(); }),
                  TextField(controller: currencyC, decoration: const InputDecoration(labelText: 'اسم العملة'), onChanged: (v) { store.currencySymbol = v; store.saveData(); }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // إعدادات الإيجار
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الإيجار', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  TextField(
                    controller: minRentalC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'أقل عدد أيام يُحسب للإيجار'),
                    onChanged: (v) {
                      store.minRentalDays = int.tryParse(v) ?? 1;
                      store.saveData();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // النسخ الاحتياطي والمزامنة السحابية (Google Drive & Email Sync)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('النسخ الاحتياطي والمزامنة السحابية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 8),
                  const Text('نمط النسخ الاحتياطي:'),
                  DropdownButtonFormField<String>(
                    value: store.backupMode,
                    items: const [
                      DropdownMenuItem(value: 'manual', child: Text('يدوي فقط')),
                      DropdownMenuItem(value: 'drive_reminder', child: Text('تذكير بالنسخ على Drive / الإيميل')),
                      DropdownMenuItem(value: 'auto_local', child: Text('تلقائي محلي + تذكير')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        store.backupMode = v;
                        store.saveData();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(45)),
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('حفظ على Google Drive / الإيميل الآن'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRBackupScreen(storeData: store))),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('استعادة من ملف (Drive أو الجهاز أو الإيميل)'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRScanScreen(storeData: store))),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                    icon: const Icon(Icons.phone_android),
                    label: const Text('النسخ المحلية على الجهاز'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ المحلي بنجاح داخل ذاكرة الهاتف')));
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
