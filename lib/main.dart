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
    final store = Provider.of<StoreData>(context);

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
        ...matchedItems.map((e) => ListTile(title: Text(e.name), subtitle: Text('السعر: ${e.price} | القسم: ${e.section}'))),
        const Divider(),
        const Text('الديون:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        ...matchedDebts.map((e) => ListTile(title: Text(e.name), subtitle: Text('المبلغ: ${e.amount} | التاريخ: ${e.date}'))),
        const Divider(),
        const Text('الإيجار:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        ...matchedRents.map((e) => ListTile(title: Text(e.name), subtitle: Text('المبلغ: ${e.amount} | التاريخ: ${e.date}'))),
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
                    subtitle: Text('القسم: ${item.section.isEmpty ? "بدون قسم" : item.section} | الكمية: ${item.quantity}'),
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
          title: Text(item == null ? 'إضافة صنف جديد' : 'تعديل صنف'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصنف')),
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر')),
                TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: store.customSections.contains(selectedSection) ? selectedSection : null,
                  decoration: const InputDecoration(labelText: 'القسم (اختياري)'),
                  items: store.customSections.map((sec) => DropdownMenuItem(value: sec, child: Text(sec))).toList(),
                  onChanged: (val) => setStateDialog(() => selectedSection = val ?? ''),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedColor,
                  decoration: const InputDecoration(labelText: 'لون السعر'),
                  items: const [
                    DropdownMenuItem(value: 'blue', child: Text('أزرق')),
                    DropdownMenuItem(value: 'red', child: Text('أحمر')),
                    DropdownMenuItem(value: 'green', child: Text('أخضر')),
                    DropdownMenuItem(value: 'orange', child: Text('برتقالي')),
                  ],
                  onChanged: (val) => setStateDialog(() => selectedColor = val ?? 'blue'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera),
                  label: const Text('بحث أو اختيار صورة الصنف'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setStateDialog(() => imagePath = pickedFile.path);
                    }
                  },
                ),
                if (imagePath != null) ...[
                  const SizedBox(height: 10),
                  Image.file(File(imagePath!), height: 80, width: 80, fit: BoxFit.cover),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                final newItem = StoreItem(
                  id: item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  price: double.tryParse(priceController.text) ?? 0.0,
                  quantity: int.tryParse(qtyController.text) ?? 1,
                  section: selectedSection,
                  imagePath: imagePath,
                  priceColor: selectedColor,
                );
                if (item == null) {
                  store.addItem(newItem);
                } else {
                  store.updateItem(newItem);
                }
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

// ---------------- 2. DEBTS SCREEN ----------------
class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);

    // Live fuzzy search on any character
    final filteredDebts = store.debts.where((d) => d.name.contains(searchQuery)).toList();

    double totalDebts = store.debts.where((e) => !e.isPaid).fold(0.0, (sum, e) => sum + e.amount);
    double totalReceived = store.debts.where((e) => e.isPaid).fold(0.0, (sum, e) => sum + e.amount);
    int debtorCount = store.debts.map((e) => e.name).toSet().length;

    return Scaffold(
      body: Column(
        children: [
          // Statistics Card
          Card(
            margin: const EdgeInsets.all(8),
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [const Text('إجمالي الديون'), Text('$totalDebts', style: const TextStyle(fontWeight: TextStyle.bold, fontSize: 16, color: Colors.blue))]),
                  Column(children: [const Text('المستلم'), Text('$totalReceived', style: const TextStyle(fontWeight: TextStyle.bold, fontSize: 16, color: Colors.red))]),
                  Column(children: [const Text('عدد المدينين'), Text('$debtorCount', style: const TextStyle(fontWeight: TextStyle.bold, fontSize: 16))]),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'بحث ذكي بالحرف في الديون...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredDebts.length,
              itemBuilder: (context, index) {
                final d = filteredDebts[index];
                // Color: blue for added debt, red for received/paid
                Color dateColor = d.isPaid ? Colors.red : Colors.blue;

                return Card(
                  child: ListTile(
                    title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('المبلغ: ${d.amount}\nالتاريخ: ${d.date}', style: TextStyle(color: dateColor, fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: d.isPaid,
                          activeColor: Colors.red,
                          onChanged: (val) {
                            store.updateDebt(d.id, d.name, d.amount, d.date, val);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showDebtDialog(context, store, debt: d),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => store.removeDebt(d.id),
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
        onPressed: () => _showDebtDialog(context, store),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDebtDialog(BuildContext context, StoreData store, {DebtItem? debt}) {
    final nameController = TextEditingController(text: debt?.name ?? '');
    final amountController = TextEditingController(text: debt?.amount.toString() ?? '');
    final dateController = TextEditingController(text: debt?.date ?? DateTime.now().toString().substring(0, 10));
    bool isPaid = debt?.isPaid ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(debt == null ? 'إضافة دين جديد' : 'تعديل دين'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الشخص')),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
            TextField(controller: dateController, decoration: const InputDecoration(labelText: 'التاريخ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              if (debt == null) {
                store.addDebt(DebtItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  amount: double.tryParse(amountController.text) ?? 0.0,
                  date: dateController.text,
                  isPaid: isPaid,
                ));
              } else {
                store.updateDebt(debt.id, nameController.text, double.tryParse(amountController.text) ?? 0.0, dateController.text, isPaid);
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

// ---------------- 3. RENTS SCREEN ----------------
class RentsScreen extends StatefulWidget {
  const RentsScreen({super.key});

  @override
  State<RentsScreen> createState() => _RentsScreenState();
}

class _RentsScreenState extends State<RentsScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final filteredRents = store.rents.where((r) => r.name.contains(searchQuery)).toList();

    double totalRents = store.rents.fold(0.0, (sum, e) => sum + e.amount);
    int renterCount = store.rents.map((e) => e.name).toSet().length;

    return Scaffold(
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8),
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [const Text('إجمالي الإيجارات'), Text('$totalRents', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue))]),
                  Column(children: [const Text('عدد المؤجرين'), Text('$renterCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'بحث في الإيجارات...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredRents.length,
              itemBuilder: (context, index) {
                final r = filteredRents[index];
                // Color: blue for active rent, red for returned
                Color dateColor = r.isReturned ? Colors.red : Colors.blue;

                return Card(
                  child: ListTile(
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('المبلغ: ${r.amount}\nالتاريخ: ${r.date}', style: TextStyle(color: dateColor, fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: r.isReturned,
                          activeColor: Colors.red,
                          onChanged: (val) {
                            store.updateRent(r.id, r.name, r.amount, r.date, val);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showRentDialog(context, store, rent: r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => store.removeRent(r.id),
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
        onPressed: () => _showRentDialog(context, store),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRentDialog(BuildContext context, StoreData store, {RentItem? rent}) {
    final nameController = TextEditingController(text: rent?.name ?? '');
    final amountController = TextEditingController(text: rent?.amount.toString() ?? '');
    final dateController = TextEditingController(text: rent?.date ?? DateTime.now().toString().substring(0, 10));
    bool isReturned = rent?.isReturned ?? false;

    // Existing names for auto-complete
    List<String> existingNames = store.rents.map((e) => e.name).toSet().toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rent == null ? 'إضافة إيجار جديد' : 'تعديل إيجار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return existingNames.where((String option) {
                  return option.contains(textEditingValue.text);
                });
              },
              onSelected: (String selection) {
                nameController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                if (controller.text.isEmpty && nameController.text.isNotEmpty) {
                  controller.text = nameController.text;
                }
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'اسم المؤجر'),
                  onChanged: (val) => nameController.text = val,
                );
              },
            ),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
            TextField(controller: dateController, decoration: const InputDecoration(labelText: 'التاريخ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              if (rent == null) {
                store.addRent(RentItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  amount: double.tryParse(amountController.text) ?? 0.0,
                  date: dateController.text,
                  isReturned: isReturned,
                ));
              } else {
                store.updateRent(rent.id, nameController.text, double.tryParse(amountController.text) ?? 0.0, dateController.text, isReturned);
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

// ---------------- 4. SETTINGS SCREEN ----------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('إعدادات النسخ الاحتياطي والمزامنة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
          SwitchListTile(
            title: const Text('حفظ تلقائي ونسخ احتياطي على الجهاز'),
            value: store.autoBackup,
            onChanged: (val) {
              store.autoBackup = val;
              store.saveData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code, color: Colors.indigo),
            title: const Text('مشاركة واستعادة البيانات عبر الباركود (بين هاتفين)'),
            subtitle: const Text('بدون إنترنت'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => QRBackupScreen(storeData: store)));
            },
          ),
          const Divider(),
          const Text('إدارة الأقسام غير المحدودة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('إضافة قسم جديد'),
            onPressed: () {
              _showAddSectionDialog(context, store);
            },
          ),
          const SizedBox(height: 10),
          ...store.customSections.map((sec) => Chip(
                label: Text(sec),
                onDeleted: () => store.removeSection(sec),
              )),
        ],
      ),
    );
  }

  void _showAddSectionDialog(BuildContext context, StoreData store) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة قسم جديد'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'اسم القسم')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                store.addSection(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
