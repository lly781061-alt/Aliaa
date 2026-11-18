import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store.dart';
import 'export.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoreData()),
      ],
      child: const StoreApp(),
    ),
  );
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: store.storeName,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        useMaterial3: true,
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
    const ItemsScreen(),
    const DebtsScreen(),
    const RentsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(store.storeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExportScreen()),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'الديون'),
          BottomNavigationBarItem(icon: Icon(Icons.handshake), label: 'الإيجارات'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

// 1. شاشة المخزن
class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    return Scaffold(
      body: store.items.isEmpty
          ? const Center(child: Text('لا توجد أصناف مضافة حالياً في المخزن'))
          : ListView.builder(
              itemCount: store.items.length,
              itemBuilder: (context, index) {
                final item = store.items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('القسم: ${item.section} | الكمية: ${item.quantity}'),
                    trailing: Text(
                      '${formatCurrency(item.price)} ${store.currencySymbol}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    onLongPress: () {
                      store.removeItem(item.id);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddItemDialog(context);
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final store = Provider.of<StoreData>(context, listen: false);
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    String selectedSection = store.customSections.isNotEmpty ? store.customSections.first : 'أخرى';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة صنف جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الصنف')),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر')),
              TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية')),
              DropdownButtonFormField<String>(
                value: selectedSection,
                items: store.customSections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) { if (val != null) selectedSection = val; },
                decoration: const InputDecoration(labelText: 'القسم'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                store.addItem(StoreItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  price: double.tryParse(priceCtrl.text) ?? 0.0,
                  quantity: int.tryParse(qtyCtrl.text) ?? 1,
                  section: selectedSection,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

// 2. شاشة الديون
class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    return Scaffold(
      body: store.debts.isEmpty
          ? const Center(child: Text('لا توجد ديون مسجلة'))
          : ListView.builder(
              itemCount: store.debts.length,
              itemBuilder: (context, index) {
                final customer = store.debts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('الهاتف: ${customer.phone}'),
                    trailing: Text(
                      '${formatCurrency(customer.remainingBalance)} ${store.currencySymbol}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    onLongPress: () {
                      store.removeCustomerDebt(customer.id);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add),
        onPressed: () {
          _showAddCustomerDialog(context);
        },
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final store = Provider.of<StoreData>(context, listen: false);
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مديونية جديدة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الزبون')),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ الدين')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                double amount = double.tryParse(amountCtrl.text) ?? 0.0;
                store.addCustomerDebt(CustomerDebt(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                  transactions: amount > 0
                      ? [DebtTransaction(id: '1', amount: amount, date: DateTime.now().toString().substring(0, 10), isPayment: false, note: 'دين افتتاحي')]
                      : [],
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

// 3. شاشة الإيجارات
class RentsScreen extends StatelessWidget {
  const RentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    return Scaffold(
      body: store.rents.isEmpty
          ? const Center(child: Text('لا توجد إيجارات نشطة حالياً'))
          : ListView.builder(
              itemCount: store.rents.length,
              itemBuilder: (context, index) {
                final rent = store.rents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(rent.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('المعدة: ${rent.equipmentName} (${rent.count} قطع)\nالتاريخ: ${rent.date}'),
                    trailing: IconButton(
                      icon: Icon(rent.isReturned ? Icons.check_circle : Icons.timer, color: rent.isReturned ? Colors.green : Colors.blue),
                      onPressed: () {
                        if (!rent.isReturned) {
                          store.returnRental(rent.id);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_business),
        onPressed: () {
          _showRentDialog(context);
        },
      ),
    );
  }

  void _showRentDialog(BuildContext context) {
    final store = Provider.of<StoreData>(context, listen: false);
    if (store.equipments.isEmpty) return;

    RentalEquipment selectedEq = store.equipments.first;
    final customerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل إيجار جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<RentalEquipment>(
                value: selectedEq,
                items: store.equipments.map((e) => DropdownMenuItem(value: e, child: Text('${e.name} (المتاح: ${e.availableCount})'))).toList(),
                onChanged: (val) { if (val != null) selectedEq = val; },
                decoration: const InputDecoration(labelText: 'اختر المعدة'),
              ),
              TextField(controller: customerCtrl, decoration: const InputDecoration(labelText: 'اسم المستأجر')),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
              TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العدد')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (customerCtrl.text.isNotEmpty) {
                int count = int.tryParse(countCtrl.text) ?? 1;
                store.addActiveRental(ActiveRental(
                  id: DateTime.now().millisecondsSinceEqual.toString(),
                  equipmentName: selectedEq.name,
                  count: count,
                  customerName: customerCtrl.text,
                  phone: phoneCtrl.text,
                  note: '',
                  date: DateTime.now().toString().substring(0, 10),
                  isReturned: false,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('تأكيد الإيجار'),
          ),
        ],
      ),
    );
  }
}

// 4. شاشة الإعدادات
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final nameCtrl = TextEditingController(text: store.storeName);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'اسم المحل'),
          onSubmitted: (val) {
            store.storeName = val;
            store.saveData();
          },
        ),
        const SizedBox(height: 20),
        ListTile(
          title: const Text('تصدير نسخة احتياطية محلية'),
          trailing: const Icon(Icons.download),
          onTap: () async {
            String? path = await store.saveLocalBackupFile();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(path != null ? 'تم الحفظ في: $path' : 'فشل حفظ النسخة')),
            );
          },
        ),
      ],
    );
  }
}
