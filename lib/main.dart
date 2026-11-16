import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'store.dart';
import 'export.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => StoreData(), child: const StoreApp()));
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    MaterialColor pColor = Colors.amber;
    if (store.primaryColorName == 'blue') pColor = Colors.blue;
    if (store.primaryColorName == 'teal') pColor = Colors.teal;
    if (store.primaryColorName == 'green') pColor = Colors.green;
    if (store.primaryColorName == 'indigo') pColor = Colors.indigo;

    return MaterialApp(
      title: 'متجر برو',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: pColor, useMaterial3: true),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomeScreen(),
    );
  }
}

// 1. شاشة البيع
class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('شاشة نقطة البيع السريع', style: TextStyle(fontSize: 18))));
  }
}

// 2. شاشة المخزن
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String search = '';
  String? sectionFilter;

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreData>(context);
    final filtered = store.items.where((i) {
      bool mSearch = i.name.contains(search) || i.section.contains(search);
      bool mSec = sectionFilter == null || sectionFilter == 'الكل' || i.section == sectionFilter;
      return mSearch && mSec;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ChoiceChip(label: const Text('الكل'), selected: sectionFilter == null || sectionFilter == 'الكل', onSelected: (_) => setState(() => sectionFilter = 'الكل')),
                ...store.customSections.map((sec) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(label: Text(sec), selected: sectionFilter == sec, onSelected: (_) => setState(() => sectionFilter = sec)),
                )),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                Color pColor = Colors.blue;
                if (item.priceColor == 'red') pColor = Colors.red;
                if (item.priceColor == 'green') pColor = Colors.green;
                if (item.priceColor == 'orange') pColor = Colors.orange;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: item.imagePath != null && File(item.imagePath!).existsSync()
                        ? Image.file(File(item.imagePath!), width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.inventory_2, color: Colors.amber, size: 40),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('القسم: ${item.section.isEmpty ? "عام" : item.section} \vert{} المتوفر: ${item.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${formatCurrency(item.price)}${store.currencySymbol}', style: TextStyle(color: pColor, fontWeight: FontWeight.bold, fontSize: 
