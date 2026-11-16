import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'store.dart';
import 'export.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => StoreData(),
      child: const StoreApp(),
    ),
  );
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'متجر برو الشامل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String globalSearchQuery = '';

  final List<Widget> _screens = [
    const InventoryScreen(),
    const DebtsScreen(),
    const RentsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المتجر الشاملة'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث عام (في المخزن، الديون، والإيجار)...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                setState(() {
                  globalSearchQuery = val.trim();
                });
              },
            ),
          ),
        ),
      ),
      body: globalSearchQuery.isNotEmpty
          ? GlobalSearchResults(query: globalSearchQuery)
          : _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            globalSearchQuery = '';
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory), label: 'المخزن'),
          NavigationDestination(icon: Icon(Icons.money), label: 'الديون'),
          NavigationDestination(icon: Icon(Icons.car_rental), label: 'الإيجار'),
          NavigationDestination(
