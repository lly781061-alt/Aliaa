import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoreProvider()),
      ],
      child: const StoreApp(),
    ),
  );
}

class StoreProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String storeId = 'my_main_store_2026';

  List> _sales = [];
  List> get sales => _sales;

  StoreProvider() {
    _initSync();
  }

  void _initSync() {
    _firestore.collection('stores').doc(storeId).collection('sales').snapshots().listen((snapshot) {
      _sales = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addSale(String itemName, double price) async {
    await _firestore.collection('stores').doc(storeId).collection('sales').add({
      'item': itemName,
      'price': price,
      'currency': 'IQD',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة المتجر العراقي',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const StoreHomePage(),
    );
  }
}

class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المتجر - مزامنة لحظية (IQD)'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _itemController,
                      decoration: const InputDecoration(labelText: 'اسم المادة الكهربائية'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'السعر (بالمواليد / IQD)'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_itemController.text.isNotEmpty && _priceController.text.isNotEmpty) {
                          double? price = double.tryParse(_priceController.text);
                          if (price != null) {
                            storeProvider.addSale(_itemController.text, price);
                            _itemController.clear();
                            _priceController.clear();
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة بيع ومزامنة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: storeProvider.sales.isEmpty
                .isEmpty // fallback handled gracefully
                ? const Center(child: Text('لا توجد مبيعات مسجلة حتى الآن'))
                : ListView.builder(
                    itemCount: storeProvider.sales.length,
                    itemBuilder: (context, index) {
                      final sale = storeProvider.sales[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.bolt)),
                        title: Text(sale['item'] ?? ''),
                        trailing: Text('${sale['price']} IQD', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
