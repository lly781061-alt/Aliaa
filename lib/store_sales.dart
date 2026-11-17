import 'package:flutter/material.dart';

class StoreSalesScreen extends StatefulWidget {
  const StoreSalesScreen({super.key});

  @override
  State<StoreSalesScreen> createState() => _StoreSalesScreenState();
}

class _StoreSalesScreenState extends State<StoreSalesScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final List> _sales = [];

  void _addSale() {
    if (_nameController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      setState(() {
        _sales.add({
          'name': _nameController.text,
          'price': _priceController.text,
        });
      });
      _nameController.clear();
      _priceController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المتجر - المبيعات (IQD)'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المادة / الصنف',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السعر (دينار عراقي)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addSale,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مبيعة'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _sales.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(_sales[index]['name'] ?? ''),
                      trailing: Text('${_sales[index]['price']} IQD'),
                    ),
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
