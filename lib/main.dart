import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const StoreApp());
}
