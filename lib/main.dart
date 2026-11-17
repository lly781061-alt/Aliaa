import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const StoreApp());
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة المتجر العراقي',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('متجر العراق - مزامنة لحظية'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'تم ربط المتجر بنجاح وجاهز للعمل!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ),
      ),
    );
  }
}
