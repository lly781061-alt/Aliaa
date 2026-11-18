import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'store.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final jsonString = store.exportToJson();
    final textController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مشاركة ونقل البيانات'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'امسح رمز الاستجابة السريعة أو انسخ كود الـ JSON أدناه لنقله بين الأجهزة بسهولة تامة.',
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (jsonString.length < 2500)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: QrImageView(
                    data: jsonString,
                    version: QrVersions.auto,
                    size: 220.0,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: textController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'الصق كود البيانات هنا للاستيراد السريع',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
              icon: const Icon(Icons.download),
              label: const Text('استيراد البيانات من النص المنسوخ'),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  bool success = store.importFromJson(textController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'تم استيراد البيانات بنجاح!' : 'الكود غير صالح، تأكد من صحة النص.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
