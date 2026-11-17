
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      title: 'متجر العراق',
      home: Scaffold(
        appBar: AppBar(title: const Text('إدارة المتجر - مزامنة لحظية')),
        body: const Center(
          child: Text('جاري ربط المبيعات والمزامنة اللحظية (IQD)...', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
