import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final List> _sales = [];

  void _addSale() {
    if (_itemController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      setState(() {
        _sales.add({
          'item': _itemController.text,
          'price': _priceController.text,
        });
      });
      _itemController.clear();
      _priceController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المتجر - العراق (IQD)'),
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
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'السعر (IQD)'),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _addSale,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مادة للمتجر'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _sales.isEmpty
                  ? const Center(child: Text('لا توجد مبيعات مسجلة حتى الآن'))
                  : ListView.builder(
                      itemCount: _sales.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.bolt)),
                          title: Text(_sales[index]['item']!),
                          trailing: Text('${_sales[index]['price']} IQD',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
