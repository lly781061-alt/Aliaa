import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

String formatCurrency(dynamic amount) {
  final formatter = NumberFormat('#,###', 'en_US');
  if (amount is double) return formatter.format(amount);
  if (amount is int) return formatter.format(amount);
  return formatter.format(double.tryParse(amount.toString()) ?? 0);
}

class DebtTransaction {
  String id;
  double amount;
  String date;
  bool isPayment;
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

class RentalEquipment {
  String id;
  String name;
  int totalCount;
  int availableCount;
  double pricePerDay;

  RentalEquipment({required this.id, required this.name, required this.totalCount, required this.availableCount, required this.pricePerDay});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'totalCount': totalCount, 'availableCount': availableCount, 'pricePerDay': pricePerDay};
  
  factory RentalEquipment.fromJson(Map<String, dynamic> json) => RentalEquipment(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        totalCount: json['totalCount'] ?? 0,
        availableCount: json['availableCount'] ?? 0,
        pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      );
}

class ActiveRental {
  String id;
  String equipmentName;
  int count;
  String customerName;
  String phone;
  String note;
  String date;
  bool isReturned;
  String? imagePath;

  ActiveRental({required this.id, required this.equipmentName, required this.count, required this.customerName, required this.phone, required this.note, required this.date, required this.isReturned, this.imagePath});

  Map<String, dynamic> toJson() => {
        'id': id,
        'equipmentName': equipmentName,
        'count': count,
        'customerName': customerName,
        'phone': phone,
        'note': note,
        'date': date,
        'isReturned': isReturned,
        'imagePath': imagePath,
      };

  factory ActiveRental.fromJson(Map<String, dynamic> json) => ActiveRental(
        id: json['id'] ?? '',
        equipmentName: json['equipmentName'] ?? '',
        count: json['count'] ?? 1,
        customerName: json['customerName'] ?? '',
        phone: json['phone'] ?? '',
        note: json['note'] ?? '',
        date: json['date'] ?? '',
        isReturned: json['isReturned'] ?? false,
        imagePath: json['imagePath'],
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
  List<RentalEquipment> equipments = [
    RentalEquipment(id: '1', name: 'سقالة حديد', totalCount: 30, availableCount: 30, pricePerDay: 2000),
    RentalEquipment(id: '2', name: 'خلاطة كونكريت', totalCount: 3, availableCount: 3, pricePerDay: 15000),
    RentalEquipment(id: '3', name: 'مثقاب هدم', totalCount: 4, availableCount: 4, pricePerDay: 10000),
    RentalEquipment(id: '4', name: 'سلم ألومنيوم', totalCount: 6, availableCount: 6, pricePerDay: 5000),
  ];
  List<ActiveRental> rents = [];
  List<StoreItem> items = [];
  List<String> customSections = ['كهربائيات', 'إنشائيات', 'أخرى'];
  
  String storeName = 'محل الكهربائيات والإنشائيات';
  String storePhone = '';
  String storeAddress = '';
  String currencySymbol = 'د.ع';
  String primaryColorName = 'amber';
  int minRentalDays = 1;
  double fontScale = 1.0;
  
  String nameColor = 'black';
  String dateColor = 'grey';
  String activeColor = 'blue';
  String returnedColor = 'green';

  StoreData() {
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final dStr = prefs.getString('debts_v2');
    if (dStr != null) debts = (jsonDecode(dStr) as List).map((e) => CustomerDebt.fromJson(e)).toList();
    
    final eqStr = prefs.getString('equipments');
    if (eqStr != null) equipments = (jsonDecode(eqStr) as List).map((e) => RentalEquipment.fromJson(e)).toList();

    final rStr = prefs.getString('rents_v2');
    if (rStr != null) rents = (jsonDecode(rStr) as List).map((e) => ActiveRental.fromJson(e)).toList();

    final iStr = prefs.getString('items');
    if (iStr != null) items = (jsonDecode(iStr) as List).map((e) => StoreItem.fromJson(e)).toList();

    final sStr = prefs.getString('customSections');
    if (sStr != null) customSections = List<String>.from(jsonDecode(sStr));

    storeName = prefs.getString('storeName') ?? 'محل الكهربائيات والإنشائيات';
    storePhone = prefs.getString('storePhone') ?? '';
    storeAddress = prefs.getString('storeAddress') ?? '';
    currencySymbol = prefs.getString('currencySymbol') ?? 'د.ع';
    primaryColorName = prefs.getString('primaryColorName') ?? 'amber';
    fontScale = prefs.getDouble('fontScale') ?? 1.0;
    
    nameColor = prefs.getString('nameColor') ?? 'black';
    dateColor = prefs.getString('dateColor') ?? 'grey';
    activeColor = prefs.getString('activeColor') ?? 'blue';
    returnedColor = prefs.getString('returnedColor') ?? 'green';

    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('debts_v2', jsonEncode(debts.map((e) => e.toJson()).toList()));
    prefs.setString('equipments', jsonEncode(equipments.map((e) => e.toJson()).toList()));
    prefs.setString('rents_v2', jsonEncode(rents.map((e) => e.toJson()).toList()));
    prefs.setString('items', jsonEncode(items.map((e) => e.toJson()).toList()));
    prefs.setString('customSections', jsonEncode(customSections));
    prefs.setString('storeName', storeName);
    prefs.setString('storePhone', storePhone);
    prefs.setString('storeAddress', storeAddress);
    prefs.setString('currencySymbol', currencySymbol);
    prefs.setString('primaryColorName', primaryColorName);
    prefs.setDouble('fontScale', fontScale);
    
    prefs.setString('nameColor', nameColor);
    prefs.setString('dateColor', dateColor);
    prefs.setString('activeColor', activeColor);
    prefs.setString('returnedColor', returnedColor);
    notifyListeners();
  }

  String exportToJson() => jsonEncode({
        'debts': debts.map((e) => e.toJson()).toList(),
        'rents': rents.map((e) => e.toJson()).toList(),
        'items': items.map((e) => e.toJson()).toList(),
        'equipments': equipments.map((e) => e.toJson()).toList(),
        'customSections': customSections,
        'storeName': storeName,
      });

  bool importFromJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      if (data['debts'] != null) debts = (data['debts'] as List).map((e) => CustomerDebt.fromJson(e)).toList();
      if (data['rents'] != null) rents = (data['rents'] as List).map((e) => ActiveRental.fromJson(e)).toList();
      if (data['items'] != null) items = (data['items'] as List).map((e) => StoreItem.fromJson(e)).toList();
      if (data['equipments'] != null) equipments = (data['equipments'] as List).map((e) => RentalEquipment.fromJson(e)).toList();
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
    saveData();
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
      saveData();
    }
  }

  void updateTransaction(String customerId, String transId, double amount, String note) {
    int cIdx = debts.indexWhere((e) => e.id == customerId);
    if (cIdx != -1) {
      int tIdx = debts[cIdx].transactions.indexWhere((t) => t.id == transId);
      if (tIdx != -1) {
        debts[cIdx].transactions[tIdx].amount = amount;
        debts[cIdx].transactions[tIdx].note = note;
        saveData();
      }
    }
  }

  void removeTransaction(String customerId, String transId) {
    int cIdx = debts.indexWhere((e) => e.id == customerId);
    if (cIdx != -1) {
      debts[cIdx].transactions.removeWhere((t) => t.id == transId);
      saveData();
    }
  }

  void updateCustomerInfo(String customerId, String name, String phone, String? imagePath) {
    int idx = debts.indexWhere((e) => e.id == customerId);
    if (idx != -1) {
      debts[idx].name = name;
      debts[idx].phone = phone;
      if (imagePath != null) debts[idx].imagePath = imagePath;
      saveData();
    }
  }

  void removeCustomerDebt(String customerId) {
    debts.removeWhere((e) => e.id == customerId);
    saveData();
  }

  void addActiveRental(ActiveRental r) {
    rents.insert(0, r);
    int eqIdx = equipments.indexWhere((e) => e.name == r.equipmentName);
    if (eqIdx != -1) {
      equipments[eqIdx].availableCount -= r.count;
      if (equipments[eqIdx].availableCount < 0) equipments[eqIdx].availableCount = 0;
    }
    saveData();
  }

  void updateRental(String id, int newCount, String note) {
    int idx = rents.indexWhere((e) => e.id == id);
    if (idx != -1) {
      int oldCnt = rents[idx].count;
      rents[idx].count = newCount;
      rents[idx].note = note;
      int eqIdx = equipments.indexWhere((e) => e.name == rents[idx].equipmentName);
      if (eqIdx != -1) {
        int diff = newCount - oldCnt;
        equipments[eqIdx].availableCount -= diff;
      }
      saveData();
    }
  }

  void returnRental(String id) {
    int idx = rents.indexWhere((e) => e.id == id);
    if (idx != -1) {
      rents[idx].isReturned = true;
      int eqIdx = equipments.indexWhere((e) => e.name == rents[idx].equipmentName);
      if (eqIdx != -1) {
        equipments[eqIdx].availableCount += rents[idx].count;
        if (equipments[eqIdx].availableCount > equipments[eqIdx].totalCount) {
          equipments[eqIdx].availableCount = equipments[eqIdx].totalCount;
        }
      }
      saveData();
    }
  }

  void addItem(StoreItem item) {
    items.add(item);
    saveData();
  }

  void updateItem(StoreItem item) {
    int idx = items.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      items[idx] = item;
      saveData();
    }
  }

  void removeItem(String id) {
    items.removeWhere((e) => e.id == id);
    saveData();
  }

  void addSection(String s) {
    if (!customSections.contains(s)) {
      customSections.add(s);
      saveData();
    }
  }

  void removeSection(String s) {
    customSections.remove(s);
    saveData();
  }
}
