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
  // الترتيب من اليمين لليسار: 0: التقارير، 1: الإيجار، 2: الديون، 3: المخزن، 4: بيع
  int _currentIndex = 3; 
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('صنف'),
                          onPressed: () => setState(() => _currentIndex = 3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade100, foregroundColor: Colors.teal.shade900),
                          icon: const Icon(Icons.store, size: 18),
                          label: const Text('إيجار'),
                          onPressed: () => setState(() => _currentIndex = 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade900),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('دين'),
                          onPressed: () => setState(() => _currentIndex = 2),
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
    final debts = store.debts.where((e) => e.name.contains(query) || e.phone.contains(query)).toList();
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
        ...debts.map((e) => ListTile(title: Text(e.name), subtitle: Text('المتبقي: ${e.remainingBalance} د.ع'))),
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

// 2. قسم الديون (قائمة العملاء)
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
                      Text('$totalDebts د.ع', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
                        Text('${c.remainingBalance} د.ع', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
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
    final phoneC = TextEditingController();
    final amountC = TextEditingController();
    String? imgPath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('إضافة عميل دين جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'اسم العميل')),
                TextField(controller: phoneC, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
                TextField(controller: amountC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ الابتدائي (دين جديد)')),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('صورة الهوية / العميل'),
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (picked != null) setD(() => imgPath = picked.path);
                  },
                ),
                if (imgPath != null) Image.file(File(imgPath!), height: 60, width: 60, fit: BoxFit.cover),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameC.text.isEmpty) return;
                double initialAmount = double.tryParse(amountC.text) ?? 0.0;
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
                            note: 'الدين الابتدائي',
                          )
                        ]
                      : [],
                );
                store.addCustomerDebt(newCustomer);
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

// 3. شاشة تفاصيل الدين للعميل (مطابقة تماماً للصورة المطلوبة)
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
          // بطاقة رقم الهاتف وتعديل الهاتف والصورة
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
          // بطاقة المتبقي
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المتبقي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${customer.remainingBalance} د.ع', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // حقل المبلغ
          TextField(
            controller: amountC,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'المبلغ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          // حقل الملاحظة
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
          // أزرار دين جديد / استلام دفعة
          Row(
            children: [
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
                    double amt = double.tryParse(amountC.text) ?? 0.0;
                    if (amt > 0) {
                      store.addTransactionToCustomer(customer.id, amt, false, noteC.text);
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
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('استلام دفعة', style: TextStyle(fontSize: 16)),
                  onPressed: () {
                    double amt = double.tryParse(amountC.text) ?? 0.0;
                    if (amt > 0) {
                      store.addTransactionToCustomer(customer.id, amt, true, noteC.text);
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
          // مشاركة كشف الحساب
          const Text('مشاركة كشف الحساب مع العميل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.share, color: Colors.amber),
                label: const Text('نص'),
                onPressed: () {},
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.table_chart, color: Colors.amber),
                label: const Text('Excel'),
                onPressed: () {},
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.amber),
                label: const Text('PDF'),
                onPressed: () {},
              ),
            ],
          ),
          const Divider(height: 30),
          const Text('الحركات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          // قائمة الحركات
          ...customer.transactions.map((t) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(t.isPayment ? 'استلام دفعة' : 'دين جديد', style: TextStyle(fontWeight: FontWeight.bold, color: t.isPayment ? Colors.red : Colors.blue)),
                subtitle: Text('${t.date}${t.note.isNotEmpty ? " · ${t.note}" : ""}'),
                trailing: Text('${t.isPayment ? "-" : "+"}${t.amount} د.ع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: t.isPayment ? Colors.red : Colors.blue)),
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

// 4. قسم الإيجار
class RentsScreen extends StatelessWidget {
  const RentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
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
                      Text('إجمالي الإيجارات', style: TextStyle(color: Colors.white.withOpacity(0.7))),
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
          Expanded(
            child: ListView.builder(
              itemCount: store.rents.length,
              itemBuilder: (context, index) {
                final r = store.rents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('المبلغ: ${r.amount} د.ع\nالتاريخ: ${r.date}'),
                    trailing: Switch(
                      value: r.isReturned,
                      activeColor: Colors.red,
                      onChanged: (v) => store.updateRent(r.id, r.name, r.phone, r.amount, r.date, v),
                    ),
                  ),
                );
              },
            ),
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

// 5. شاشة الإعدادات والتحكم الشامل
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final nameC = TextEditingController(text: store.storeName);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات والتحكم الشامل')),
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
          const Text('لون التطبيق الأساسي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
          DropdownButtonFormField<String>(
            value: store.primaryColorName,
            items: const [
              DropdownMenuItem(value: 'amber', child: Text('أصفر / كهرماني')),
              DropdownMenuItem(value: 'blue', child: Text('أزرق')),
              DropdownMenuItem(value: 'teal', child: Text('تركواز')),
              DropdownMenuItem(value: 'green', child: Text('أخضر')),
              DropdownMenuItem(value: 'indigo', child: Text('نيلي')),
            ],
            onChanged: (v) {
              if (v != null) {
                store.primaryColorName = v;
                store.saveData();
              }
            },
          ),
          const Divider(),
          const Text('النسخ الاحتياطي والمزامنة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
          SwitchListTile(
            title: const Text('حفظ تلقائي للبيانات'),
            value: store.autoBackup,
            onChanged: (v) { store.autoBackup = v; store.saveData(); },
          ),
          SwitchListTile(
            title: const Text('مزامنة تلقائية مع Google Drive'),
            value: store.driveAutoSync,
            onChanged: (v) { store.driveAutoSync = v; store.saveData(); },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code, color: Colors.amber),
            title: const Text('مشاركة واستعادة النسخة عبر الباركود أو Drive'),
            subtitle: const Text('توليد وقراءة باركود أو مشاركة ملف النسخة'),
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
