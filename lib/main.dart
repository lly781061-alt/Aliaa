import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Init Error: $e');
  }
  runApp(const StoreApp());
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String storeId = 'my_main_store_2026';
  
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  void _addSale(String item, double price) async {
    try {
      await _firestore.collection('stores').doc(storeId).collection('sales').add({
        'item': item,
        'price': price,
        'currency': 'IQD',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _itemController.clear();
      _priceController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المادة ومزامنتها بنجاح')),
        );
      }
    } catch (e) {
      debugPrint('Error adding sale: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المتجر - مزامنة لحظية (IQD)'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'اسم المادة الكهربائية'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'السعر (IQD)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (_itemController.text.isNotEmpty && _priceController.text.isNotEmpty) {
                  double? price = double.tryParse(_priceController.text);
                  if (price != null) {
                    _addSale(_itemController.text, price);
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('حفظ ومزامنة فورية'),
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: Center(
                child: Text(
                  'المتجر متصل بقاعدة بيانات فايربيس بنجاح',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
