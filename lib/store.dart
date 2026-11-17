import 'package:flutter/foundation.dart';

class StoreProvider extends ChangeNotifier {
  final List> _sales = [];

  List> get sales => _sales;

  void addSale(String name, String price) {
    _sales.add({
      'name': name,
      'price': price,
      'time': DateTime.now().toString().substring(11, 16),
    });
    notifyListeners();
  }
}
