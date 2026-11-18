import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

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

  Map<String, dynamic> toJson() =>
