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
      title: 'إدارة المتجر العراقي',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('المتجر - مزامنة لحظية (IQD)'),
          centerTitle: true,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'تم ربط المتجر بنجاح وجاهز للمزامنة اللحظية!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
