import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebtItem {
  String id;
  String name;
  double amount;
  String date;
  bool isPaid; // false = دين جديد (أزرق)، true = استلام دفعة (أحمر)
  DebtItem({required this.id, required this.name, required this.amount, required this.date, required this.isPaid});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'amount': amount, 'date': date, 'isPaid': isPaid};
  factory DebtItem.fromJson(Map<String, dynamic> json) => DebtItem(
        id: json['id'],
        name: json['name'],
        amount: (json['amount'] as num).toDouble(),
        date: json['date'],
        isPaid: json['isPaid'] ?? false,
      );
}

class RentItem {
  String id;
  String name;
  double amount;
  String date;
  bool isReturned; // false = إيجار جاري (أزرق)، true = تسليم (أحمر)
  RentItem({required this.id, required this.name, required this.amount, required this.date, required this.isReturned});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'amount': amount, 'date': date, 'isReturned': isReturned};
  factory RentItem.fromJson(Map<String, dynamic> json) => RentItem(
        id: json['id'],
        name: json['name'],
        amount: (json['amount'] as num).toDouble(),
        date: json['date'],
        isReturned: json['isReturned'] ?? false,
      );
}

class StoreItem {
  String id;
  String name;
  double price;
  int quantity;
  String section; // اختيارية
  String? imagePath;
  String priceColor; // لون السعر

  StoreItem({required this.id, required this.name, required this.price, required this.quantity, required this.section, this.imagePath, this.priceColor = 'blue'});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price, 'quantity': quantity, 'section': section, 'imagePath': imagePath, 'priceColor': priceColor};
  factory StoreItem.fromJson(Map<String, dynamic> json) => StoreItem(
        id: json['id'],
        name: json['name'],
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'],
        section: json['section'] ?? '',
        imagePath: json['imagePath'],
        priceColor: json['priceColor'] ?? 'blue',
      );
}

class StoreData extends ChangeNotifier {
  List<DebtItem> debts = [];
  List<RentItem> rents = [];
  List<StoreItem> items = [];
  List<String> customSections = ['كهربائيات', 'إنشائيات', 'أخرى'];
  bool autoBackup = true;
  String storeName = 'محل الكهربائيات والإنشائيات';

  StoreData() { loadData(); }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final dStr = prefs.getString('debts');
    if (dStr != null) debts = (jsonDecode(dStr) as List).map((e) => DebtItem.fromJson(e)).toList();
    final rStr = prefs.getString('rents');
    if (rStr != null) rents = (jsonDecode(rStr) as List).map((e) => RentItem.fromJson(e)).toList();
    final iStr = prefs.getString('items');
    if (iStr != null) items = (jsonDecode(iStr) as List).map((e) => StoreItem.fromJson(e)).toList();
    final sStr = prefs.getString('customSections');
    if (sStr != null) customSections = List<String>.from(jsonDecode(sStr));
    autoBackup = prefs.getBool('autoBackup') ?? true;
    storeName = prefs.getString('storeName') ?? 'محل الكهربائيات والإنشائيات';
    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('debts', jsonEncode(debts.map((e) => e.toJson()).toList()));
    prefs.setString('rents', jsonEncode(rents.map((e) => e.toJson()).toList()));
    prefs.setString('items', jsonEncode(items.map((e) => e.toJson()).toList()));
    prefs.setString('customSections', jsonEncode(customSections));
    prefs.setBool('autoBackup', autoBackup);
    prefs.setString('storeName', storeName);
    notifyListeners();
  }

  String exportToJson() => jsonEncode({'debts': debts.map((e) => e.toJson()).toList(), 'rents': rents.map((e) => e.toJson()).toList(), 'items': items.map((e) => e.toJson()).toList(), 'customSections': customSections, 'storeName': storeName});

  bool importFromJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      if (data['debts'] != null) debts = (data['debts'] as List).map((e) => DebtItem.fromJson(e)).toList();
      if (data['rents'] != null) rents = (data['rents'] as List).map((e) => RentItem.fromJson(e)).toList();
      if (data['items'] != null) items = (data['items'] as List).map((e) => StoreItem.fromJson(e)).toList();
      if (data['customSections'] != null) customSections = List<String>.from(data['customSections']);
      if (data['storeName'] != null) storeName = data['storeName'];
      saveData();
      return true;
    } catch (e) { return false; }
  }

  void addDebt(DebtItem d) { debts.add(d); saveData(); }
  void updateDebt(String id, String name, double amount, String date, bool isPaid) {
    int idx = debts.indexWhere((e) => e.id == id);
    if (idx != -1) { debts[idx] = DebtItem(id: id, name: name, amount: amount, date: date, isPaid: isPaid); saveData(); }
  }
  void removeDebt(String id) { debts.removeWhere((e) => e.id == id); saveData(); }

  void addRent(RentItem r) { rents.add(r); saveData(); }
  void updateRent(String id, String name, double amount, String date, bool isReturned) {
    int idx = rents.indexWhere((e) => e.id == id);
    if (idx != -1) { rents[idx] = RentItem(id: id, name: name, amount: amount, date: date, isReturned: isReturned); saveData(); }
  }
  void removeRent(String id) { rents.removeWhere((e) => e.id == id); saveData(); }

  void addItem(StoreItem item) { items.add(item); saveData(); }
  void updateItem(StoreItem item) {
    int idx = items.indexWhere((e) => e.id == item.id);
    if (idx != -1) { items[idx] = item; saveData(); }
  }
  void removeItem(String id) { items.removeWhere((e) => e.id == id); saveData(); }

  void addSection(String s) { if (!customSections.contains(s)) { customSections.add(s); saveData(); } }
  void removeSection(String s) { customSections.remove(s); saveData(); }
}
