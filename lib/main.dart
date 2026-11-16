import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      title: 'متجر برو',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
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
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const InventoryScreen(),
    const DebtsScreen(),
    const RentsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المتجر الشاملة')),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'الديون'),
          BottomNavigationBarItem(icon: Icon(Icons.car_rental), label: 'الإيجار'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

// 1. INVENTORY
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    return Scaffold(
      body: ListView.builder(
        itemCount: store.items.length,
        itemBuilder: (context, index) {
          final item = store.items[index];
          return ListTile(
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('القسم: ${item.section} | الكمية: ${item.quantity}'),
            trailing: Text('${item.price}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => store.addItem(StoreItem(id: DateTime.now().toString(), name: 'صنف تجريبي', price: 1000, quantity: 5, section: 'قسم 1')),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// 2. DEBTS
class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    double totalDebts = store.debts.where((e) => !e.isPaid).fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('إجمالي الديون: $totalDebts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: store.debts.length,
              itemBuilder: (context, index) {
                final d = store.debts[index];
                return ListTile(
                  title: Text(d.name),
                  subtitle: Text('المبلغ: ${d.amount} | التاريخ: ${d.date}'),
                  trailing: Switch(
                    value: d.isPaid,
                    activeColor: Colors.red,
                    onChanged: (val) => store.updateDebt(d.id, d.name, d.amount, d.date, val),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => store.addDebt(DebtItem(id: DateTime.now().toString(), name: 'زبون تجريبي', amount: 5000, date: '2026-11-16', isPaid: false)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// 3. RENTS
class RentsScreen extends StatelessWidget {
  const RentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    return Scaffold(
      body: ListView.builder(
        itemCount: store.rents.length,
        itemBuilder: (context, index) {
          final r = store.rents[index];
          return ListTile(
            title: Text(r.name),
            subtitle: Text('المبلغ: ${r.amount} | التاريخ: ${r.date}'),
            trailing: Switch(
              value: r.isReturned,
              activeColor: Colors.red,
              onChanged: (val) => store.updateRent(r.id, r.name, r.amount, r.date, val),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => store.addRent(RentItem(id: DateTime.now().toString(), name: 'مؤجر تجريبي', amount: 15000, date: '2026-11-16', isReturned: false)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// 4. SETTINGS
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('حفظ تلقائي ونسخ احتياطي'),
            value: store.autoBackup,
            onChanged: (val) {
              store.autoBackup = val;
              store.saveData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code, color: Colors.indigo),
            title: const Text('مشاركة واستعادة البيانات عبر الباركود'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRBackupScreen(storeData: store))),
          ),
        ],
      ),
    );
  }
}
