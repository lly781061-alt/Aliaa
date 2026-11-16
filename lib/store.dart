import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebtTransaction {
  String id;
  double amount;
  String date;
  bool isPayment; // false = دين جديد, true = استلام دفعة
  String note;

  DebtTransaction({required this.id, required this.amount, required this.date, required this.isPayment, this.note = ''});

  Map<String, dynamic> toJson() => {'id': id, 'amount': amount, 'date': date, 'isPayment': isPayment, 'note': note};
  factory DebtTransaction.fromJson(Map<String, dynamic> json) => DebtTransaction(
        id: json['id'] ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: json['date'] ?? '',
        isPayment: json['isPayment'] ?? false,
        note: json['note'] ?? '',
      );
}

class CustomerDebt {
  String id;
  String name;
  String phone;
  String? imagePath;
  List<DebtTransaction> transactions;

  CustomerDebt({required this.id, required this.name, this.phone = '', this.imagePath, required this.transactions});

  double get remainingBalance {
    double total = 0;
    for (var t in transactions) {
      if (t.isPayment) {
        total -= t.amount;
      } else {
        total += t.amount;
      }
    }
    return total < 0 ? 0 : total;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'imagePath': imagePath,
        'transactions': transactions.map((e) => e.toJson()).toList(),
      };

  factory CustomerDebt.fromJson(Map<String, dynamic> json) => CustomerDebt(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        imagePath: json['imagePath'],
        transactions: (json['transactions'] as List?)?.map((e) => DebtTransaction.fromJson(e)).toList() ?? [],
      );
}

class RentItem {
  String id;
  String name;
  String phone;
  double amount;
  String date;
  bool isReturned;
  RentItem({required this.id, required this.name, this.phone = '', required this.amount, required this.date, required this.isReturned});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone, 'amount': amount, 'date': date, 'isReturned': isReturned};
  factory RentItem.fromJson(Map<String, dynamic> json) => RentItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: json['date'] ?? '',
        isReturned: json['isReturned'] ?? false,
      );
}

class StoreItem {
  String id;
  String name;
  double price;
  int quantity;
  String section;
  String? imagePath;
  String priceColor;

  StoreItem({required this.id, required this.name, required this.price, required this.quantity, required this.section, this.imagePath, this.priceColor = 'blue'});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price, 'quantity': quantity, 'section': section, 'imagePath': imagePath, 'priceColor': priceColor};
  factory StoreItem.fromJson(Map<String, dynamic> json) => StoreItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        quantity: json['quantity'] ?? 0,
        section: json['section'] ?? '',
        imagePath: json['imagePath'],
        priceColor: json['priceColor'] ?? 'blue',
      );
}

class StoreData extends ChangeNotifier {
  List<CustomerDebt> debts = [];
  List<RentItem> rents = [];
  List<StoreItem> items = [];
  List<String> customSections = ['كهربائيات', 'إنشائيات', 'أخرى'];
  bool autoBackup = true;
  bool driveAutoSync = false;
  String storeName = 'محل الكهربائيات والإنشائيات';
  String primaryColorName = 'amber';

  StoreData() {
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final dStr = prefs.getString('debts_v2');
    if (dStr != null) {
      debts = (jsonDecode(dStr) as List).map((e) => CustomerDebt.fromJson(e)).toList();
    }
    final rStr = prefs.getString('rents');
    if (rStr != null) rents = (jsonDecode(rStr) as List).map((e) => RentItem.fromJson(e)).toList();
    final iStr = prefs.getString('items');
    if (iStr != null) items = (jsonDecode(iStr) as List).map((e) => StoreItem.fromJson(e)).toList();
    final sStr = prefs.getString('customSections');
    if (sStr != null) customSections = List<String>.from(jsonDecode(sStr));
    autoBackup = prefs.getBool('autoBackup') ?? true;
    driveAutoSync = prefs.getBool('driveAutoSync') ?? false;
    storeName = prefs.getString('storeName') ?? 'محل الكهربائيات والإنشائيات';
    primaryColorName = prefs.getString('primaryColorName') ?? 'amber';
    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('debts_v2', jsonEncode(debts.map((e) => e.toJson()).toList()));
    prefs.setString('rents', jsonEncode(rents.map((e) => e.toJson()).toList()));
    prefs.setString('items', jsonEncode(items.map((e) => e.toJson()).toList()));
    prefs.setString('customSections', jsonEncode(customSections));
    prefs.setBool('autoBackup', autoBackup);
    prefs.setBool('driveAutoSync', driveAutoSync);
    prefs.setString('storeName', storeName);
    prefs.setString('primaryColorName', primaryColorName);
    notifyListeners();
  }

  String exportToJson() => jsonEncode({
        'debts': debts.map((e) => e.toJson()).toList(),
        'rents': rents.map((e) => e.toJson()).toList(),
        'items': items.map((e) => e.toJson()).toList(),
        'customSections': customSections,
        'storeName': storeName,
      });

  bool importFromJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      if (data['debts'] != null) debts = (data['debts'] as List).map((e) => CustomerDebt.fromJson(e)).toList();
      if (data['rents'] != null) rents = (data['rents'] as List).map((e) => RentItem.fromJson(e)).toList();
      if (data['items'] != null) items = (data['items'] as List).map((e) => StoreItem.fromJson(e)).toList();
      if (data['customSections'] != null) customSections = List<String>.from(data['customSections']);
      if (data['storeName'] != null) storeName = data['storeName'];
      saveData();
      return true;
    } catch (e) {
      return false;
    }
  }

  void addCustomerDebt(CustomerDebt c) {
    debts.add(c);
    if (autoBackup) saveData(); else notifyListeners();
  }

  void addTransactionToCustomer(String customerId, double amount, bool isPayment, String note) {
    int idx = debts.indexWhere((e) => e.id == customerId);
    if (idx != -1) {
      final trans = DebtTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        date: DateTime.now().toString().substring(0, 16),
        isPayment: isPayment,
        note: note,
      );
      debts[idx].transactions.insert(0, trans);
      if (autoBackup) saveData(); else notifyListeners();
    }
  }

  void updateCustomerInfo(String customerId, String name, String phone, String? imagePath) {
    int idx = debts.indexWhere((e) => e.id == customerId);
    if (idx != -1) {
      debts[idx].name = name;
      debts[idx].phone = phone;
      if (imagePath != null) debts[idx].imagePath = imagePath;
      if (autoBackup) saveData(); else notifyListeners();
    }
  }

  void removeCustomerDebt(String customerId) {
    debts.removeWhere((e) => e.id == customerId);
    if (autoBackup) saveData(); else notifyListeners();
  }

  void addRent(RentItem r) {
    rents.add(r);
    if (autoBackup) saveData(); else notifyListeners();
  }

  void updateRent(String id, String name, String phone, double amount, String date, bool isReturned) {
    int idx = rents.indexWhere((e) => e.id == id);
    if (idx != -1) {
      rents[idx] = RentItem(id: id, name: name, phone: phone, amount: amount, date: date, isReturned: isReturned);
      if (autoBackup) saveData(); else notifyListeners();
    }
  }

  void removeRent(String id) {
    rents.removeWhere((e) => e.id == id);
    if (autoBackup) saveData(); else notifyListeners();
  }

  void addItem(StoreItem item) {
    items.add(item);
    if (autoBackup) saveData(); else notifyListeners();
  }

  void updateItem(StoreItem item) {
    int idx = items.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      items[idx] = item;
      if (autoBackup) saveData(); else notifyListeners();
    }
  }

  void removeItem(String id) {
    items.removeWhere((e) => e.id == id);
    if (autoBackup) saveData(); else notifyListeners();
  }

  void addSection(String s) {
    if (!customSections.contains(s)) {
      customSections.add(s);
      if (autoBackup) saveData(); else notifyListeners();
    }
  }

  void removeSection(String s) {
    customSections.remove(s);
    if (autoBackup) saveData(); else notifyListeners();
  }
}
