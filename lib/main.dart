import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StoreManagerApp());
}

// ==================== نماذج البيانات (Models) ====================

class StoreCategory {
  String id;
  String name;
  int colorValue;

  StoreCategory({required this.id, required this.name, required this.colorValue});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'colorValue': colorValue};
  factory StoreCategory.fromJson(Map<String, dynamic> json) => StoreCategory(
        id: json['id'],
        name: json['name'],
        colorValue: json['colorValue'] ?? 0xFF2196F3,
      );
}

class ProductItem {
  String id;
  String name;
  String categoryId;
  double buyPrice;
  double sellPrice;
  int quantity;
  String barcode;

  ProductItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    this.barcode = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'buyPrice': buyPrice,
        'sellPrice': sellPrice,
        'quantity': quantity,
        'barcode': barcode,
      };

  factory ProductItem.fromJson(Map<String, dynamic> json) => ProductItem(
        id: json['id'],
        name: json['name'],
        categoryId: json['categoryId'],
        buyPrice: (json['buyPrice'] ?? 0).toDouble(),
        sellPrice: (json['sellPrice'] ?? 0).toDouble(),
        quantity: json['quantity'] ?? 0,
        barcode: json['barcode'] ?? '',
      );
}

class DebtTransaction {
  String id;
  double amount;
  bool isDebt; // true = دين جديد (+), false = استلام دفعة (-)
  String date;
  String note;
  String? imagePath;

  DebtTransaction({
    required this.id,
    required this.amount,
    required this.isDebt,
    required this.date,
    this.note = '',
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'isDebt': isDebt,
        'date': date,
        'note': note,
        'imagePath': imagePath,
      };

  factory DebtTransaction.fromJson(Map<String, dynamic> json) => DebtTransaction(
        id: json['id'],
        amount: (json['amount'] ?? 0).toDouble(),
        isDebt: json['isDebt'] ?? true,
        date: json['date'] ?? '',
        note: json['note'] ?? '',
        imagePath: json['imagePath'],
      );
}

class DebtorCustomer {
  String id;
  String name;
  String phone;
  List<DebtTransaction> transactions;

  DebtorCustomer({
    required this.id,
    required this.name,
    this.phone = '',
    required this.transactions,
  });

  double get remainingBalance {
    double total = 0;
    for (var t in transactions) {
      total += t.isDebt ? t.amount : -t.amount;
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'transactions': transactions.map((e) => e.toJson()).toList(),
      };

  factory DebtorCustomer.fromJson(Map<String, dynamic> json) => DebtorCustomer(
        id: json['id'],
        name: json['name'],
        phone: json['phone'] ?? '',
        transactions: (json['transactions'] as List? ?? [])
            .map((e) => DebtTransaction.fromJson(e))
            .toList(),
      );
}

class RentalEquipment {
  String id;
  String name;
  double dailyRate;
  int totalCount;

  RentalEquipment({
    required this.id,
    required this.name,
    required this.dailyRate,
    required this.totalCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dailyRate': dailyRate,
        'totalCount': totalCount,
      };

  factory RentalEquipment.fromJson(Map<String, dynamic> json) => RentalEquipment(
        id: json['id'],
        name: json['name'],
        dailyRate: (json['dailyRate'] ?? 0).toDouble(),
        totalCount: json['totalCount'] ?? 1,
      );
}

class RentalRecord {
  String id;
  String equipmentId;
  String equipmentName;
  int quantity;
  double dailyRate;
  String customerName;
  String customerPhone;
  String startDate; // yyyy-MM-dd HH:mm
  String? returnDate;
  bool isReturned;
  double? finalAmount;
  String notes;

  RentalRecord({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.quantity,
    required this.dailyRate,
    required this.customerName,
    this.customerPhone = '',
    required this.startDate,
    this.returnDate,
    this.isReturned = false,
    this.finalAmount,
    this.notes = '',
  });

  int get calculatedDays {
    try {
      DateTime start = DateTime.parse(startDate);
      DateTime end = isReturned && returnDate != null ? DateTime.parse(returnDate!) : DateTime.now();
      int days = end.difference(start).inDays;
      return days < 1 ? 1 : days;
    } catch (_) {
      return 1;
    }
  }

  double get calculatedTotal {
    if (isReturned && finalAmount != null) return finalAmount!;
    return calculatedDays * dailyRate * quantity;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'equipmentId': equipmentId,
        'equipmentName': equipmentName,
        'quantity': quantity,
        'dailyRate': dailyRate,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'startDate': startDate,
        'returnDate': returnDate,
        'isReturned': isReturned,
        'finalAmount': finalAmount,
        'notes': notes,
      };

  factory RentalRecord.fromJson(Map<String, dynamic> json) => RentalRecord(
        id: json['id'],
        equipmentId: json['equipmentId'],
        equipmentName: json['equipmentName'],
        quantity: json['quantity'] ?? 1,
        dailyRate: (json['dailyRate'] ?? 0).toDouble(),
        customerName: json['customerName'] ?? '',
        customerPhone: json['customerPhone'] ?? '',
        startDate: json['startDate'] ?? '',
        returnDate: json['returnDate'],
        isReturned: json['isReturned'] ?? false,
        finalAmount: json['finalAmount']?.toDouble(),
        notes: json['notes'] ?? '',
      );
}

class SaleRecord {
  String id;
  String date;
  double totalAmount;
  double totalProfit;
  List> items;

  SaleRecord({
    required this.id,
    required this.date,
    required this.totalAmount,
    required this.totalProfit,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'totalAmount': totalAmount,
        'totalProfit': totalProfit,
        'items': items,
      };

  factory SaleRecord.fromJson(Map<String, dynamic> json) => SaleRecord(
        id: json['id'],
        date: json['date'] ?? '',
        totalAmount: (json['totalAmount'] ?? 0).toDouble(),
        totalProfit: (json['totalProfit'] ?? 0).toDouble(),
        items: List>.from(json['items'] ?? []),
      );
}

// ==================== التطبيق الرئيسي ====================

class StoreManagerApp extends StatefulWidget {
  const StoreManagerApp({super.key});

  @override
  State<StoreManagerApp> createState() => _StoreManagerAppState();
}

class _StoreManagerAppState extends State<StoreManagerApp> {
  // إعدادات المتجر والألوان
  String storeName = 'محل الكهربائيات والإنشائيات';
  String storePhone = '';
  String storeAddress = '';
  String currency = 'د.ع';

  int primaryHeaderStartColor = 0xFFD86B3E;
  int primaryHeaderEndColor = 0xFF7B4397;
  int appAccentColor = 0xFF009688;
  int textPrimaryColor = 0xFF1E1E1E;
  int textSecondaryColor = 0xFF757575;
  int returnedBadgeColor = 0xFF4CAF50;

  String? syncedEmail;
  bool autoSyncEnabled = false;

  // البيانات الأساسية
  List<StoreCategory> categories = [];
  List<ProductItem> products = [];
  List<DebtorCustomer> debtors = [];
  List<RentalEquipment> equipments = [];
  List<RentalRecord> rentals = [];
  List<SaleRecord> sales = [];

  int currentTab = 0; // 0: بيع, 1: المخزن, 2: الديون, 3: الإيجار, 4: التقارير
  String globalSearchQuery = '';
  final TextEditingController _globalSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  String formatMoney(double amount) {
    final formatter = intl.NumberFormat('#,##0', 'en_US');
    return '${formatter.format(amount)} $currency';
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      storeName = prefs.getString('storeName') ?? 'محل الكهربائيات والإنشائيات';
      storePhone = prefs.getString('storePhone') ?? '';
      storeAddress = prefs.getString('storeAddress') ?? '';
      currency = prefs.getString('currency') ?? 'د.ع';

      primaryHeaderStartColor = prefs.getInt('primaryHeaderStartColor') ?? 0xFFD86B3E;
      primaryHeaderEndColor = prefs.getInt('primaryHeaderEndColor') ?? 0xFF7B4397;
      appAccentColor = prefs.getInt('appAccentColor') ?? 0xFF009688;
      textPrimaryColor = prefs.getInt('textPrimaryColor') ?? 0xFF1E1E1E;
      textSecondaryColor = prefs.getInt('textSecondaryColor') ?? 0xFF757575;
      returnedBadgeColor = prefs.getInt('returnedBadgeColor') ?? 0xFF4CAF50;
      syncedEmail = prefs.getString('syncedEmail');
      autoSyncEnabled = prefs.getBool('autoSyncEnabled') ?? false;

      final catStr = prefs.getString('categories');
      if (catStr != null) {
        categories = (jsonDecode(catStr) as List).map((e) => StoreCategory.fromJson(e)).toList();
      } else {
        categories = [
          StoreCategory(id: '1', name: 'كهربائيات', colorValue: 0xFFFF9800),
          StoreCategory(id: '2', name: 'إنشائيات', colorValue: 0xFF2196F3),
          StoreCategory(id: '3', name: 'أخرى', colorValue: 0xFF9C27B0),
        ];
      }

      final prodStr = prefs.getString('products');
      if (prodStr != null) {
        products = (jsonDecode(prodStr) as List).map((e) => ProductItem.fromJson(e)).toList();
      }

      final debtStr = prefs.getString('debtors');
      if (debtStr != null) {
        debtors = (jsonDecode(debtStr) as List).map((e) => DebtorCustomer.fromJson(e)).toList();
      }

      final eqStr = prefs.getString('equipments');
      if (eqStr != null) {
        equipments = (jsonDecode(eqStr) as List).map((e) => RentalEquipment.fromJson(e)).toList();
      } else {
        equipments = [
          RentalEquipment(id: 'e1', name: 'سقالة حديد', dailyRate: 2000, totalCount: 30),
          RentalEquipment(id: 'e2', name: 'خلاطة كونكريت', dailyRate: 15000, totalCount: 3),
          RentalEquipment(id: 'e3', name: 'مثقاب هدم', dailyRate: 10000, totalCount: 4),
        ];
      }

      final rentStr = prefs.getString('rentals');
      if (rentStr != null) {
        rentals = (jsonDecode(rentStr) as List).map((e) => RentalRecord.fromJson(e)).toList();
      }

      final saleStr = prefs.getString('sales');
      if (saleStr != null) {
        sales = (jsonDecode(saleStr) as List).map((e) => SaleRecord.fromJson(e)).toList();
      }
    });
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storeName', storeName);
    await prefs.setString('storePhone', storePhone);
    await prefs.setString('storeAddress', storeAddress);
    await prefs.setString('currency', currency);

    await prefs.setInt('primaryHeaderStartColor', primaryHeaderStartColor);
    await prefs.setInt('primaryHeaderEndColor', primaryHeaderEndColor);
    await prefs.setInt('appAccentColor', appAccentColor);
    await prefs.setInt('textPrimaryColor', textPrimaryColor);
    await prefs.setInt('textSecondaryColor', textSecondaryColor);
    await prefs.setInt('returnedBadgeColor', returnedBadgeColor);
    if (syncedEmail != null) {
      await prefs.setString('syncedEmail', syncedEmail!);
    }
    await prefs.setBool('autoSyncEnabled', autoSyncEnabled);

    await prefs.setString('categories', jsonEncode(categories.map((e) => e.toJson()).toList()));
    await prefs.setString('products', jsonEncode(products.map((e) => e.toJson()).toList()));
    await prefs.setString('debtors', jsonEncode(debtors.map((e) => e.toJson()).toList()));
    await prefs.setString('equipments', jsonEncode(equipments.map((e) => e.toJson()).toList()));
    await prefs.setString('rentals', jsonEncode(rentals.map((e) => e.toJson()).toList()));
    await prefs.setString('sales', jsonEncode(sales.map((e) => e.toJson()).toList()));

    // إذا كانت المزامنة اللحظية مفعلة، يتم رفع التحديث للسحابة فوراً
    if (autoSyncEnabled && syncedEmail != null) {
      _pushRealtimeCloudSync();
    }
  }

  String _exportDatabaseToJson() {
    return jsonEncode({
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'storeName': storeName,
      'storePhone': storePhone,
      'storeAddress': storeAddress,
      'currency': currency,
      'categories': categories.map((e) => e.toJson()).toList(),
      'products': products.map((e) => e.toJson()).toList(),
      'debtors': debtors.map((e) => e.toJson()).toList(),
      'equipments': equipments.map((e) => e.toJson()).toList(),
      'rentals': rentals.map((e) => e.toJson()).toList(),
      'sales': sales.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> _importDatabaseFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);
      setState(() {
        storeName = data['storeName'] ?? storeName;
        storePhone = data['storePhone'] ?? storePhone;
        storeAddress = data['storeAddress'] ?? storeAddress;
        currency = data['currency'] ?? currency;
        if (data['categories'] != null) {
          categories = (data['categories'] as List).map((e) => StoreCategory.fromJson(e)).toList();
        }
        if (data['products'] != null) {
          products = (data['products'] as List).map((e) => ProductItem.fromJson(e)).toList();
        }
        if (data['debtors'] != null) {
          debtors = (data['debtors'] as List).map((e) => DebtorCustomer.fromJson(e)).toList();
        }
        if (data['equipments'] != null) {
          equipments = (data['equipments'] as List).map((e) => RentalEquipment.fromJson(e)).toList();
        }
        if (data['rentals'] != null) {
          rentals = (data['rentals'] as List).map((e) => RentalRecord.fromJson(e)).toList();
        }
        if (data['sales'] != null) {
          sales = (data['sales'] as List).map((e) => SaleRecord.fromJson(e)).toList();
        }
      });
      await _saveAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت استعادة البيانات بنجاح!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في قراءة البيانات: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pushRealtimeCloudSync() async {
    // هنا يتم ربط Firebase Firestore بالمستخدم (syncedEmail) لمزامنة البيانات لحظياً بين الهاتفين
    // مثال: FirebaseFirestore.instance.collection('stores').doc(syncedEmail).set(jsonDecode(_exportDatabaseToJson()));
    debugPrint('Realtime Sync Pushed for $syncedEmail');
  }

  int getAvailableEquipmentCount(String eqId, int total) {
    int rentedOut = 0;
    for (var r in rentals) {
      if (r.equipmentId == eqId && !r.isReturned) {
        rentedOut += r.quantity;
      }
    }
    return (total - rentedOut).clamp(0, total);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: storeName,
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [Locale('ar', 'IQ'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Color(appAccentColor),
        scaffoldBackgroundColor: const Color(0xFFF6F6F8),
        fontFamily: 'Roboto',
      ),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Column(
            children: [
              _buildTopHeader(ctx),
              Expanded(
                child: globalSearchQuery.trim().isNotEmpty
                    ? _buildGlobalSearchResults(ctx)
                    : _buildCurrentScreen(ctx),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavBar(),
        ),
      ),
    );
  }

  // ==================== الشريط العلوي المطابق للصورة ====================
  Widget _buildTopHeader(BuildContext ctx) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(ctx).padding.top + 8,
        left: 14,
        right: 14,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(primaryHeaderStartColor), Color(primaryHeaderEndColor)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // اسم المحل + زر الإعدادات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                onPressed: () => _openSettingsPage(ctx),
              ),
              Expanded(
                child: Text(
                  storeName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (autoSyncEnabled)
                const Icon(Icons.cloud_done, color: Colors.greenAccent, size: 22)
              else
                const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 8),
          // 3 أزرار اختصار سريعة: دين جديد | إيجار جديد | إضافة صنف
          Row(
            children: [
              Expanded(
                child: _quickActionPill(
                  icon: Icons.person_add_alt_1,
                  iconColor: Colors.blue.shade800,
                  bgColor: const Color(0xFFD6E4FF),
                  label: 'دين\nجديد',
                  onTap: () => _showAddDebtDialog(ctx),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _quickActionPill(
                  icon: Icons.storefront,
                  iconColor: Colors.teal.shade800,
                  bgColor: const Color(0xFFD3ECE6),
                  label: 'إيجار\nجديد',
                  onTap: () => _showAddRentalDialog(ctx),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _quickActionPill(
                  icon: Icons.add,
                  iconColor: Colors.green.shade800,
                  bgColor: const Color(0xFFD5E8D4),
                  label: 'إضافة\nصنف',
                  onTap: () => _showAddOrEditProductDialog(ctx),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // خانة البحث العام في الأعلى
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _globalSearchController,
              onChanged: (val) => setState(() => globalSearchQuery = val),
              decoration: InputDecoration(
                hintText: 'بحث عام في المخزن، الديون، الإيجار...',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.black87),
                suffixIcon: globalSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          _globalSearchController.clear();
                          setState(() => globalSearchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionPill({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade900,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== نتائج البحث العام الشامل ====================
  Widget _buildGlobalSearchResults(BuildContext ctx) {
    final q = globalSearchQuery.trim().toLowerCase();
    final matchedProducts = products.where((p) => p.name.toLowerCase().contains(q) || p.barcode.contains(q)).toList();
    final matchedDebtors = debtors.where((d) => d.name.toLowerCase().contains(q) || d.phone.contains(q)).toList();
    final matchedRentals = rentals
        .where((r) =>
            r.customerName.toLowerCase().contains(q) ||
            r.equipmentName.toLowerCase().contains(q) ||
            r.customerPhone.contains(q))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text('نتائج البحث العام عن "$globalSearchQuery"',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        if (matchedProducts.isEmpty && matchedDebtors.isEmpty && matchedRentals.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('لا توجد نتائج مطابقة في أي قسم', style: TextStyle(color: Colors.grey)),
            ),
          ),
        if (matchedProducts.isNotEmpty) ...[
          const Text('📦 في المخزن:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          ...matchedProducts.map((p) => Card(
                child: ListTile(
                  title: Text(p.name, style: TextStyle(color: Color(textPrimaryColor), fontWeight: FontWeight.bold)),
                  subtitle: Text('المتوفر: ${p.quantity} | البيع: ${formatMoney(p.sellPrice)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showAddOrEditProductDialog(ctx, existing: p),
                  ),
                ),
              )),
          const SizedBox(height: 10),
        ],
        if (matchedDebtors.isNotEmpty) ...[
          const Text('💳 في الديون:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ...matchedDebtors.map((d) => Card(
                child: ListTile(
                  title: Text(d.name, style: TextStyle(color: Color(textPrimaryColor), fontWeight: FontWeight.bold)),
                  subtitle: Text('الهاتف: ${d.phone.isEmpty ? "لا يوجد" : d.phone}'),
                  trailing: Text(formatMoney(d.remainingBalance),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () => _openDebtorDetails(ctx, d),
                ),
              )),
          const SizedBox(height: 10),
        ],
        if (matchedRentals.isNotEmpty) ...[
          const Text('🛠️ في الإيجارات:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          ...matchedRentals.map((r) => Card(
                child: ListTile(
                  title: Text('${r.equipmentName} × ${r.quantity}',
                      style: TextStyle(color: Color(textPrimaryColor), fontWeight: FontWeight.bold)),
                  subtitle: Text('العميل: ${r.customerName} | ${r.isReturned ? "مستلم (منتهي)" : "قيد الإيجار"}'),
                  trailing: Text(formatMoney(r.calculatedTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ],
    );
  }

  // ==================== التبديل بين الشاشات الخمس ====================
  Widget _buildCurrentScreen(BuildContext ctx) {
    switch (currentTab) {
      case 0:
        return _SalesPosTab(
          products: products,
          debtors: debtors,
          formatMoney: formatMoney,
          accentColor: Color(appAccentColor),
          textPrimary: Color(textPrimaryColor),
          onCompleteSale: (cart, total, profit, asDebtCustomerName) {
            setState(() {
              for (var entry in cart.entries) {
                final idx = products.indexWhere((p) => p.id == entry.key.id);
                if (idx != -1) {
                  products[idx].quantity = (products[idx].quantity - entry.value).clamp(0, 999999);
                }
              }
              sales.insert(
                0,
                SaleRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                  totalAmount: total,
                  totalProfit: profit,
                  items: cart.entries
                      .map((e) => {'name': e.key.name, 'qty': e.value, 'price': e.key.sellPrice})
                      .toList(),
                ),
              );

              if (asDebtCustomerName != null && asDebtCustomerName.isNotEmpty) {
                final existingIdx = debtors.indexWhere((d) => d.name == asDebtCustomerName);
                final tx = DebtTransaction(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  amount: total,
                  isDebt: true,
                  date: intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                  note: 'فاتورة مبيعات آجلة',
                );
                if (existingIdx != -1) {
                  debtors[existingIdx].transactions.insert(0, tx);
                } else {
                  debtors.insert(
                    0,
                    DebtorCustomer(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: asDebtCustomerName,
                      transactions: [tx],
                    ),
                  );
                }
              }
            });
            _saveAllData();
          },
        );
      case 1:
        return _InventoryTab(
          categories: categories,
          products: products,
          formatMoney: formatMoney,
          accentColor: Color(appAccentColor),
          textPrimary: Color(textPrimaryColor),
          onAddProduct: () => _showAddOrEditProductDialog(ctx),
          onEditProduct: (p) => _showAddOrEditProductDialog(ctx, existing: p),
          onDeleteProduct: (p) {
            setState(() => products.removeWhere((item) => item.id == p.id));
            _saveAllData();
          },
        );
      case 2:
        return _DebtsTab(
          debtors: debtors,
          formatMoney: formatMoney,
          textPrimary: Color(textPrimaryColor),
          onAddDebt: () => _showAddDebtDialog(ctx),
          onOpenCustomer: (d) => _openDebtorDetails(ctx, d),
          onDeleteCustomer: (d) {
            setState(() => debtors.removeWhere((item) => item.id == d.id));
            _saveAllData();
          },
        );
      case 3:
        return _RentalsTab(
          equipments: equipments,
          rentals: rentals,
          getAvailableCount: getAvailableEquipmentCount,
          formatMoney: formatMoney,
          textPrimary: Color(textPrimaryColor),
          textSecondary: Color(textSecondaryColor),
          returnedColor: Color(returnedBadgeColor),
          onAddRental: () => _showAddRentalDialog(ctx),
          onManageEquipments: () => _showManageEquipmentsDialog(ctx),
          onReturnRental: (r) => _confirmReturnRental(ctx, r),
          onEditRental: (r) => _showAddRentalDialog(ctx, existing: r),
          onDeleteRental: (r) {
            setState(() => rentals.removeWhere((item) => item.id == r.id));
            _saveAllData();
          },
        );
      case 4:
      default:
        return _ReportsTab(
          sales: sales,
          debtors: debtors,
          rentals: rentals,
          products: products,
          formatMoney: formatMoney,
          onDeleteSale: (s) {
            setState(() => sales.removeWhere((item) => item.id == s.id));
            _saveAllData();
          },
        );
    }
  }

  Widget _buildBottomNavBar() {
    return NavigationBar(
      selectedIndex: currentTab,
      onDestinationSelected: (idx) {
        setState(() {
          currentTab = idx;
          globalSearchQuery = '';
          _globalSearchController.clear();
        });
      },
      backgroundColor: const Color(0xFFFDF8F5),
      indicatorColor: Color(appAccentColor).withOpacity(0.18),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'بيع'),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'المخزن'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'الديون'),
        NavigationDestination(icon: Icon(Icons.handyman_outlined), label: 'الإيجار'),
        NavigationDestination(icon: Icon(Icons.bar_chart), label: 'التقارير'),
      ],
    );
  }

  // ==================== نوافذ الإضافة والتعديل ====================

  void _showAddOrEditProductDialog(BuildContext ctx, {ProductItem? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final buyCtrl = TextEditingController(text: existing != null ? existing.buyPrice.toStringAsFixed(0) : '');
    final sellCtrl = TextEditingController(text: existing != null ? existing.sellPrice.toStringAsFixed(0) : '');
    final qtyCtrl = TextEditingController(text: existing != null ? existing.quantity.toString() : '');
    final barcodeCtrl = TextEditingController(text: existing?.barcode ?? '');
    String selectedCatId = existing?.categoryId ?? (categories.isNotEmpty ? categories.first.id : '1');

    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'إضافة صنف جديد للمخزن' : 'تعديل الصنف'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الصنف (مثل: مصباح LED)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: categories.any((c) => c.id == selectedCatId)
                      ? selectedCatId
                      : (categories.isNotEmpty ? categories.first.id : null),
                  decoration: const InputDecoration(labelText: 'القسم', border: OutlineInputBorder()),
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                CircleAvatar(radius: 6, backgroundColor: Color(c.colorValue)),
                                const SizedBox(width: 8),
                                Text(c.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedCatId = val!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: buyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'سعر الشراء ($currency)', border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: sellCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'سعر البيع ($currency)', border: const OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية المتوفرة', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: barcodeCtrl,
                  decoration: InputDecoration(
                    labelText: 'الباركود (اختياري)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final scanned = await Navigator.push<String>(
                          ctx,
                          MaterialPageRoute(builder: (_) => const _BarcodeScannerScreen()),
                        );
                        if (scanned != null) {
                          setDialogState(() => barcodeCtrl.text = scanned);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  if (existing == null) {
                    products.insert(
                      0,
                      ProductItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        categoryId: selectedCatId,
                        buyPrice: double.tryParse(buyCtrl.text) ?? 0,
                        sellPrice: double.tryParse(sellCtrl.text) ?? 0,
                        quantity: int.tryParse(qtyCtrl.text) ?? 0,
                        barcode: barcodeCtrl.text.trim(),
                      ),
                    );
                  } else {
                    existing.name = nameCtrl.text.trim();
                    existing.categoryId = selectedCatId;
                    existing.buyPrice = double.tryParse(buyCtrl.text) ?? 0;
                    existing.sellPrice = double.tryParse(sellCtrl.text) ?? 0;
                    existing.quantity = int.tryParse(qtyCtrl.text) ?? 0;
                    existing.barcode = barcodeCtrl.text.trim();
                  }
                });
                _saveAllData();
                Navigator.pop(dCtx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDebtDialog(BuildContext ctx) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? pickedImagePath;

    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة دين جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Autocomplete<String>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                    return debtors
                        .map((d) => d.name)
                        .where((name) => name.contains(textEditingValue.text));
                  },
                  onSelected: (selection) {
                    nameCtrl.text = selection;
                    final found = debtors.firstWhere((d) => d.name == selection);
                    phoneCtrl.text = found.phone;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    controller.addListener(() => nameCtrl.text = controller.text);
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: 'اسم العميل المدين', border: OutlineInputBorder()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف (اختياري)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'المبلغ ($currency)', border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'التفاصيل / الملاحظات', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('التاريخ: ${intl.DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('كاميرا'),
                        onPressed: () async {
                          final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
                          if (img != null) setDialogState(() => pickedImagePath = img.path);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('المعرض'),
                        onPressed: () async {
                          final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (img != null) setDialogState(() => pickedImagePath = img.path);
                        },
                      ),
                    ),
                  ],
                ),
                if (pickedImagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(pickedImagePath!), height: 100, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (nameCtrl.text.trim().isEmpty || amount <= 0) return;

                final tx = DebtTransaction(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  amount: amount,
                  isDebt: true,
                  date: '${intl.DateFormat('yyyy-MM-dd').format(selectedDate)} ${intl.DateFormat('HH:mm').format(DateTime.now())}',
                  note: noteCtrl.text.trim(),
                  imagePath: pickedImagePath,
                );

                setState(() {
                  final idx = debtors.indexWhere((d) => d.name == nameCtrl.text.trim());
                  if (idx != -1) {
                    if (phoneCtrl.text.trim().isNotEmpty) debtors[idx].phone = phoneCtrl.text.trim();
                    debtors[idx].transactions.insert(0, tx);
                  } else {
                    debtors.insert(
                      0,
                      DebtorCustomer(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        transactions: [tx],
                      ),
                    );
                  }
                });
                _saveAllData();
                Navigator.pop(dCtx);
              },
              child: const Text('حفظ الدين'),
            ),
          ],
        ),
      ),
    );
  }

  void _openDebtorDetails(BuildContext ctx, DebtorCustomer debtor) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => _DebtorDetailScreen(
          debtor: debtor,
          formatMoney: formatMoney,
          currency: currency,
          onChanged: () {
            setState(() {});
            _saveAllData();
          },
          onDeleteCustomer: () {
            setState(() => debtors.removeWhere((d) => d.id == debtor.id));
            _saveAllData();
          },
        ),
      ),
    );
  }

  void _showAddRentalDialog(BuildContext ctx, {RentalRecord? existing}) {
    if (equipments.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة معدات أولاً من زر إدارة المعدات')),
      );
      return;
    }

    String selectedEqId = existing?.equipmentId ?? equipments.first.id;
    final customerCtrl = TextEditingController(text: existing?.customerName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.customerPhone ?? '');
    final qtyCtrl = TextEditingController(text: existing != null ? existing.quantity.toString() : '1');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    DateTime startDate = existing != null ? (DateTime.tryParse(existing.startDate) ?? DateTime.now()) : DateTime.now();

    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final eq = equipments.firstWhere((e) => e.id == selectedEqId, orElse: () => equipments.first);
          final avail = getAvailableEquipmentCount(eq.id, eq.totalCount) + (existing != null ? existing.quantity : 0);

          return AlertDialog(
            title: Text(existing == null ? 'إيجار معدة جديد' : 'تعديل عملية الإيجار'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: eq.id,
                    decoration: const InputDecoration(labelText: 'اختر المعدة', border: OutlineInputBorder()),
                    items: equipments
                        .map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text('${e.name} (${formatMoney(e.dailyRate)}/يوم)'),
                            ))
                        .toList(),
                    onChanged: (val) => setDialogState(() => selectedEqId = val!),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('المتوفر حالياً: $avail من ${eq.totalCount}',
                        style: TextStyle(color: avail > 0 ? Colors.green : Colors.red, fontSize: 12)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: customerCtrl,
                    decoration: const InputDecoration(labelText: 'اسم المستأجر', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم هاتف المستأجر', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'العدد المطلوب', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('تاريخ الأخذ: ${intl.DateFormat('yyyy-MM-dd').format(startDate)}'),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setDialogState(() => startDate = picked);
                    },
                  ),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'ملاحظات إضافية (اختياري)', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () {
                  final qty = int.tryParse(qtyCtrl.text) ?? 1;
                  if (customerCtrl.text.trim().isEmpty || qty <= 0) return;

                  setState(() {
                    if (existing == null) {
                      rentals.insert(
                        0,
                        RentalRecord(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          equipmentId: eq.id,
                          equipmentName: eq.name,
                          quantity: qty,
                          dailyRate: eq.dailyRate,
                          customerName: customerCtrl.text.trim(),
                          customerPhone: phoneCtrl.text.trim(),
                          startDate: intl.DateFormat('yyyy-MM-dd HH:mm').format(startDate),
                          notes: notesCtrl.text.trim(),
                        ),
                      );
                    } else {
                      existing.equipmentId = eq.id;
                      existing.equipmentName = eq.name;
                      existing.quantity = qty;
                      existing.dailyRate = eq.dailyRate;
                      existing.customerName = customerCtrl.text.trim();
                      existing.customerPhone = phoneCtrl.text.trim();
                      existing.startDate = intl.DateFormat('yyyy-MM-dd HH:mm').format(startDate);
                      existing.notes = notesCtrl.text.trim();
                    }
                  });
                  _saveAllData();
                  Navigator.pop(dCtx);
                },
                child: const Text('حفظ الإيجار'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmReturnRental(BuildContext ctx, RentalRecord r) {
    final finalAmountCtrl = TextEditingController(text: r.calculatedTotal.toStringAsFixed(0));
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('استلام المعدة وإنهاء الإيجار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المعدة: ${r.equipmentName} (العدد: ${r.quantity})'),
            Text('المستأجر: ${r.customerName}'),
            Text('المدة المحسوبة آلياً: ${r.calculatedDays} يوم'),
            const SizedBox(height: 12),
            TextField(
              controller: finalAmountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'المبلغ النهائي المستلم ($currency)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                r.isReturned = true;
                r.returnDate = intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
                r.finalAmount = double.tryParse(finalAmountCtrl.text) ?? r.calculatedTotal;
              });
              _saveAllData();
              Navigator.pop(dCtx);
            },
            child: const Text('تأكيد الاستلام'),
          ),
        ],
      ),
    );
  }

  void _showManageEquipmentsDialog(BuildContext ctx) {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final countCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إدارة معدات الإيجار'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المعدة')),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rateCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'الإيجار اليومي ($currency)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: countCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'العدد الكلي'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة معدة'),
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setState(() {
                        equipments.add(RentalEquipment(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameCtrl.text.trim(),
                          dailyRate: double.tryParse(rateCtrl.text) ?? 0,
                          totalCount: int.tryParse(countCtrl.text) ?? 1,
                        ));
                      });
                      _saveAllData();
                      nameCtrl.clear();
                      rateCtrl.clear();
                      countCtrl.clear();
                      setDialogState(() {});
                    },
                  ),
                  const Divider(),
                  ...equipments.map((eq) => ListTile(
                        title: Text(eq.name),
                        subtitle: Text('${formatMoney(eq.dailyRate)} / يوم | العدد: ${eq.totalCount}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => equipments.removeWhere((item) => item.id == eq.id));
                            _saveAllData();
                            setDialogState(() {});
                          },
                        ),
                      )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إغلاق')),
          ],
        ),
      ),
    );
  }

  // ==================== صفحة الإعدادات الشاملة والمزامنة ====================
  void _openSettingsPage(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => _SettingsAndSyncScreen(
          storeName: storeName,
          storePhone: storePhone,
          storeAddress: storeAddress,
          currency: currency,
          categories: categories,
          primaryHeaderStartColor: primaryHeaderStartColor,
          primaryHeaderEndColor: primaryHeaderEndColor,
          appAccentColor: appAccentColor,
          textPrimaryColor: textPrimaryColor,
          textSecondaryColor: textSecondaryColor,
          returnedBadgeColor: returnedBadgeColor,
          syncedEmail: syncedEmail,
          autoSyncEnabled: autoSyncEnabled,
          exportJson: _exportDatabaseToJson,
          importJson: _importDatabaseFromJson,
          onSaveSettings: ({
            required String newName,
            required String newPhone,
            required String newAddress,
            required String newCurrency,
            required int newStartColor,
            required int newEndColor,
            required int newAccent,
            required int newTextPrimary,
            required int newTextSecondary,
            required int newReturnedBadge,
            required String? newEmail,
            required bool newAutoSync,
          }) {
            setState(() {
              storeName = newName;
              storePhone = newPhone;
              storeAddress = newAddress;
              currency = newCurrency;
              primaryHeaderStartColor = newStartColor;
              primaryHeaderEndColor = newEndColor;
              appAccentColor = newAccent;
              textPrimaryColor = newTextPrimary;
              textSecondaryColor = newTextSecondary;
              returnedBadgeColor = newReturnedBadge;
              syncedEmail = newEmail;
              autoSyncEnabled = newAutoSync;
            });
            _saveAllData();
          },
          onCategoriesChanged: () {
            setState(() {});
            _saveAllData();
          },
        ),
      ),
    );
  }
}

// ==================== 1. تبويب البيع (POS) ====================
class _SalesPosTab extends StatefulWidget {
  final List<ProductItem> products;
  final List<DebtorCustomer> debtors;
  final String Function(double) formatMoney;
  final Color accentColor;
  final Color textPrimary;
  final void Function(Map<ProductItem, int> cart, double total, double profit, String? debtCustomer) onCompleteSale;

  const _SalesPosTab({
    required this.products,
    required this.debtors,
    required this.formatMoney,
    required this.accentColor,
    required this.textPrimary,
    required this.onCompleteSale,
  });

  @override
  State<_SalesPosTab> createState() => _SalesPosTabState();
}

class _SalesPosTabState extends State<_SalesPosTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<ProductItem, int> cart = {};
  String query = '';

  double get totalInvoice {
    double sum = 0;
    cart.forEach((p, qty) => sum += p.sellPrice * qty);
    return sum;
  }

  double get totalProfit {
    double profit = 0;
    cart.forEach((p, qty) => profit += (p.sellPrice - p.buyPrice) * qty);
    return profit;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = query.isEmpty
        ? <ProductItem>[]
        : widget.products
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()) || p.barcode == query)
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => query = val),
            decoration: InputDecoration(
              hintText: 'ابحث عن صنف (مثل: مصباح)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () async {
                  final code = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => const _BarcodeScannerScreen()),
                  );
                  if (code != null) {
                    final found = widget.products.where((p) => p.barcode == code).toList();
                    if (found.isNotEmpty) {
                      setState(() {
                        cart[found.first] = (cart[found.first] ?? 0) + 1;
                      });
                    }
                  }
                },
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (_, idx) {
                final p = suggestions[idx];
                return ListTile(
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('السعر: ${widget.formatMoney(p.sellPrice)} | المتوفر: ${p.quantity}'),
                  trailing: Icon(Icons.add_circle, color: widget.accentColor),
                  onTap: () {
                    setState(() {
                      cart[p] = (cart[p] ?? 0) + 1;
                      _searchCtrl.clear();
                      query = '';
                    });
                  },
                );
              },
            ),
          ),
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Text('ابحث عن صنف أعلاه لإضافته للفاتورة',
                      style: TextStyle(color: Colors.grey.shade500)),
                )
              : ListView(
                  padding: const EdgeInsets.all(14),
                  children: cart.entries.map((entry) {
                    final p = entry.key;
                    final qty = entry.value;
                    return Card(
                      child: ListTile(
                        title: Text(p.name, style: TextStyle(color: widget.textPrimary, fontWeight: FontWeight.bold)),
                        subtitle: Text('${widget.formatMoney(p.sellPrice)} × $qty = ${widget.formatMoney(p.sellPrice * qty)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  if (qty > 1) {
                                    cart[p] = qty - 1;
                                  } else {
                                    cart.remove(p);
                                  }
                                });
                              },
                            ),
                            Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onPressed: () => setState(() => cart[p] = qty + 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        // شريط إجمالي الفاتورة وإتمام البيع
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFECE6E2),
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cart.isEmpty ? Colors.grey.shade400 : widget.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.check),
                label: const Text('إتمام البيع', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: cart.isEmpty ? null : () => _showCheckoutOptions(context),
              ),
              const Spacer(),
              Text(
                'إجمالي الفاتورة: ${widget.formatMoney(totalInvoice)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCheckoutOptions(BuildContext context) {
    final customerCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('تأكيد الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الإجمالي: ${widget.formatMoney(totalInvoice)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: customerCtrl,
              decoration: const InputDecoration(
                labelText: 'تسجيل كـ دين على عميل (اتركه فارغاً للنقدي)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              widget.onCompleteSale(
                Map.from(cart),
                totalInvoice,
                totalProfit,
                customerCtrl.text.trim().isEmpty ? null : customerCtrl.text.trim(),
              );
              setState(() => cart.clear());
              Navigator.pop(dCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تسجيل عملية البيع بنجاح!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}

// ==================== 2. تبويب المخزن ====================
class _InventoryTab extends StatefulWidget {
  final List<StoreCategory> categories;
  final List<ProductItem> products;
  final String Function(double) formatMoney;
  final Color accentColor;
  final Color textPrimary;
  final VoidCallback onAddProduct;
  final void Function(ProductItem) onEditProduct;
  final void Function(ProductItem) onDeleteProduct;

  const _InventoryTab({
    required this.categories,
    required this.products,
    required this.formatMoney,
    required this.accentColor,
    required this.textPrimary,
    required this.onAddProduct,
    required this.onEditProduct,
    required this.onDeleteProduct,
  });

  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  String selectedCategoryId = 'ALL';

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategoryId == 'ALL'
        ? widget.products
        : widget.products.where((p) => p.categoryId == selectedCategoryId).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
        onPressed: widget.onAddProduct,
        child: const Icon(Icons.add, size: 28),
      ),
      body: Column(
        children: [
          // شريط أقسام المخزن القابل للتخصيص بالألوان
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _categoryChip('ALL', 'الكل', Colors.teal),
                const SizedBox(width: 8),
                ...widget.categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _categoryChip(cat.id, cat.name, Color(cat.colorValue)),
                    )),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد أصناف في هذا القسم', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                    itemCount: filtered.length,
                    itemBuilder: (_, idx) {
                      final p = filtered[idx];
                      final cat = widget.categories.firstWhere(
                        (c) => c.id == p.categoryId,
                        orElse: () => StoreCategory(id: '0', name: 'عام', colorValue: 0xFF607D8B),
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(cat.colorValue).withOpacity(0.2),
                            child: Icon(Icons.inventory_2, color: Color(cat.colorValue)),
                          ),
                          title: Text(p.name, style: TextStyle(color: widget.textPrimary, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'القسم: ${cat.name} | الكمية: ${p.quantity}\nالشراء: ${widget.formatMoney(p.buyPrice)} | البيع: ${widget.formatMoney(p.sellPrice)}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => widget.onEditProduct(p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => widget.onDeleteProduct(p),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String id, String label, Color color) {
    final isSelected = selectedCategoryId == id;
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) const Icon(Icons.check, size: 16, color: Colors.white),
          if (isSelected) const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selectedColor: color,
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color),
      ),
      onSelected: (_) => setState(() => selectedCategoryId = id),
    );
  }
}

// ==================== 3. تبويب الديون ====================
class _DebtsTab extends StatefulWidget {
  final List<DebtorCustomer> debtors;
  final String Function(double) formatMoney;
  final Color textPrimary;
  final VoidCallback onAddDebt;
  final void Function(DebtorCustomer) onOpenCustomer;
  final void Function(DebtorCustomer) onDeleteCustomer;

  const _DebtsTab({
    required this.debtors,
    required this.formatMoney,
    required this.textPrimary,
    required this.onAddDebt,
    required this.onOpenCustomer,
    required this.onDeleteCustomer,
  });

  @override
  State<_DebtsTab> createState() => _DebtsTabState();
}

class _DebtsTabState extends State<_DebtsTab> {
  String search = '';

  double get totalDebts {
    double sum = 0;
    for (var d in widget.debtors) {
      if (d.remainingBalance > 0) sum += d.remainingBalance;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.debtors
        .where((d) => d.name.toLowerCase().contains(search.toLowerCase()) || d.phone.contains(search))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        onPressed: widget.onAddDebt,
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: Column(
        children: [
          // البطاقة الزرقاء لإجمالي الديون المستحقة (مطابقة للصورة)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1572B6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إجمالي الديون المستحقة', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(widget.formatMoney(totalDebts),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text('المدينون', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${widget.debtors.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              onChanged: (val) => setState(() => search = val),
              decoration: InputDecoration(
                hintText: 'بحث عن عميل مدين...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا يوجد عملاء مدينون', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                    itemCount: filtered.length,
                    itemBuilder: (_, idx) {
                      final d = filtered[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF1572B6),
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(d.name, style: TextStyle(color: widget.textPrimary, fontWeight: FontWeight.bold)),
                          subtitle: Text('الهاتف: ${d.phone.isEmpty ? "لا يوجد" : d.phone}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.formatMoney(d.remainingBalance),
                                style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                          onTap: () => widget.onOpenCustomer(d),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== شاشة تفاصيل العميل وحركات الدين ====================
class _DebtorDetailScreen extends StatefulWidget {
  final DebtorCustomer debtor;
  final String Function(double) formatMoney;
  final String currency;
  final VoidCallback onChanged;
  final VoidCallback onDeleteCustomer;

  const _DebtorDetailScreen({
    required this.debtor,
    required this.formatMoney,
    required this.currency,
    required this.onChanged,
    required this.onDeleteCustomer,
  });

  @override
  State<_DebtorDetailScreen> createState() => _DebtorDetailScreenState();
}

class _DebtorDetailScreenState extends State<_DebtorDetailScreen> {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  String? attachedImagePath;

  void _addMovement(bool isDebt) {
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    if (amount <= 0) return;
    setState(() {
      widget.debtor.transactions.insert(
        0,
        DebtTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: amount,
          isDebt: isDebt,
          date: intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
          note: noteCtrl.text.trim(),
          imagePath: attachedImagePath,
        ),
      );
      amountCtrl.clear();
      noteCtrl.clear();
      attachedImagePath = null;
    });
    widget.onChanged();
  }

  void _editTransaction(DebtTransaction tx) {
    final editAmount = TextEditingController(text: tx.amount.toStringAsFixed(0));
    final editNote = TextEditingController(text: tx.note);
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('تعديل الحركة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editAmount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'المبلغ (${widget.currency})'),
            ),
            TextField(controller: editNote, decoration: const InputDecoration(labelText: 'ملاحظة')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                tx.amount = double.tryParse(editAmount.text) ?? tx.amount;
                tx.note = editNote.text.trim();
              });
              widget.onChanged();
              Navigator.pop(dCtx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.debtor.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.green),
            tooltip: 'مشاركة كشف الحساب واتساب',
            onPressed: () {
              final text =
                  'كشف حساب العميل: ${widget.debtor.name}\nالمتبقي: ${widget.formatMoney(widget.debtor.remainingBalance)}';
              Share.share(text);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              widget.onDeleteCustomer();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المتبقي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  widget.formatMoney(widget.debtor.remainingBalance),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'المبلغ (${widget.currency})',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: noteCtrl,
            decoration: InputDecoration(
              labelText: 'ملاحظة',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () async {
                      final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
                      if (img != null) setState(() => attachedImagePath = img.path);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: () async {
                      final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (img != null) setState(() => attachedImagePath = img.path);
                    },
                  ),
                ],
              ),
            ),
          ),
          if (attachedImagePath != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('تم إرفاق صورة بنجاح ✓', style: TextStyle(color: Colors.green.shade700)),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('استلام دفعة', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _addMovement(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('دين جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _addMovement(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('الحركات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...widget.debtor.transactions.map((tx) => Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        tx.isDebt ? Icons.arrow_upward : Icons.arrow_downward,
                        color: tx.isDebt ? Colors.blue : Colors.red,
                      ),
                      title: Text(tx.isDebt ? 'دين جديد' : 'استلام دفعة',
                          style: TextStyle(color: tx.isDebt ? Colors.blue : Colors.red, fontWeight: FontWeight.bold)),
                      subtitle: Text('${tx.date}${tx.note.isNotEmpty ? " • ${tx.note}" : ""}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${tx.isDebt ? "+" : "-"}${widget.formatMoney(tx.amount)}',
                            style: TextStyle(
                              color: tx.isDebt ? Colors.blue : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'edit') _editTransaction(tx);
                              if (val == 'delete') {
                                setState(() => widget.debtor.transactions.removeWhere((item) => item.id == tx.id));
                                widget.onChanged();
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('تعديل')),
                              PopupMenuItem(value: 'delete', child: Text('حذف')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (tx.imagePath != null && File(tx.imagePath!).existsSync())
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(tx.imagePath!), height: 140, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ==================== 4. تبويب الإيجار ====================
class _RentalsTab extends StatefulWidget {
  final List<RentalEquipment> equipments;
  final List<RentalRecord> rentals;
  final int Function(String eqId, int total) getAvailableCount;
  final String Function(double) formatMoney;
  final Color textPrimary;
  final Color textSecondary;
  final Color returnedColor;
  final VoidCallback onAddRental;
  final VoidCallback onManageEquipments;
  final void Function(RentalRecord) onReturnRental;
  final void Function(RentalRecord) onEditRental;
  final void Function(RentalRecord) onDeleteRental;

  const _RentalsTab({
    required this.equipments,
    required this.rentals,
    required this.getAvailableCount,
    required this.formatMoney,
    required this.textPrimary,
    required this.textSecondary,
    required this.returnedColor,
    required this.onAddRental,
    required this.onManageEquipments,
    required this.onReturnRental,
    required this.onEditRental,
    required this.onDeleteRental,
  });

  @override
  State<_RentalsTab> createState() => _RentalsTabState();
}

class _RentalsTabState extends State<_RentalsTab> {
  String activeSearch = '';
  String returnedSearch = '';

  @override
  Widget build(BuildContext context) {
    final activeRentals = widget.rentals
        .where((r) =>
            !r.isReturned &&
            (r.customerName.toLowerCase().contains(activeSearch.toLowerCase()) ||
                r.customerPhone.contains(activeSearch) ||
                r.equipmentName.toLowerCase().contains(activeSearch.toLowerCase())))
        .toList();

    final returnedRentals = widget.rentals
        .where((r) =>
            r.isReturned &&
            (r.customerName.toLowerCase().contains(returnedSearch.toLowerCase()) ||
                r.customerPhone.contains(returnedSearch) ||
                r.equipmentName.toLowerCase().contains(returnedSearch.toLowerCase())))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // أزرار: إدارة المعدات | + إيجار جديد (مطابقة للصورة)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.handyman, color: Colors.amber),
                label: const Text('إدارة المعدات', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                onPressed: widget.onManageEquipments,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1572B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('إيجار جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: widget.onAddRental,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // قسم: قيد الإيجار (الإيجارات النشطة) مع خانة بحث مستقلة
        Text('قيد الإيجار (${activeRentals.length})',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          onChanged: (val) => setState(() => activeSearch = val),
          decoration: InputDecoration(
            hintText: 'بحث في الإيجارات النشطة (اسم، هاتف، معدة)...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        if (activeRentals.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(child: Text('لا توجد إيجارات نشطة حالياً', style: TextStyle(color: Colors.grey))),
          )
        else
          ...activeRentals.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${r.equipmentName} × ${r.quantity}',
                                style: TextStyle(color: widget.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('${r.customerName} • منذ ${r.startDate.split(" ").first}',
                                style: TextStyle(color: widget.textSecondary)),
                            Text('هاتفه: ${r.customerPhone.isEmpty ? "لا يوجد" : r.customerPhone} • ${r.calculatedDays} يوم',
                                style: TextStyle(color: widget.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(widget.formatMoney(r.calculatedTotal),
                              style: const TextStyle(color: Color(0xFF1572B6), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD32F2F),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                onPressed: () => widget.onReturnRental(r),
                                child: const Text('تسليم / استلام', style: TextStyle(fontSize: 12)),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'edit') widget.onEditRental(r);
                                  if (val == 'delete') widget.onDeleteRental(r);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),

        const SizedBox(height: 16),
        // قسم: المعدات المتاحة
        const Text('المعدات المتاحة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...widget.equipments.map((eq) {
          final avail = widget.getAvailableCount(eq.id, eq.totalCount);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(eq.name, style: TextStyle(color: widget.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: Text('${widget.formatMoney(eq.dailyRate)} / يوم'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: avail > 0 ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'متاح $avail من ${eq.totalCount}',
                  style: TextStyle(
                    color: avail > 0 ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
        // قسم: الإيجارات المستلمة (المنتهية) مع خانة بحث مستقلة كما في الصورة 570333
        Text('الإيجارات المستلمة والمنتهية (${returnedRentals.length})',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          onChanged: (val) => setState(() => returnedSearch = val),
          decoration: InputDecoration(
            hintText: 'ابحث باسم العميل أو رقم الهاتف في المستلمات...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        ...returnedRentals.map((r) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('${r.equipmentName} × ${r.quantity}',
                    style: TextStyle(color: widget.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'العميل: ${r.customerName} | الهاتف: ${r.customerPhone.isEmpty ? "لا يوجد" : r.customerPhone}\nالتاريخ: ${r.startDate.split(" ").first} (منتهي) • المبلغ: ${widget.formatMoney(r.calculatedTotal)}',
                  style: TextStyle(color: widget.textSecondary, fontSize: 12),
                ),
                isThreeLine: true,
                trailing: Text(
                  'مستلم',
                  style: TextStyle(color: widget.returnedColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            )),
      ],
    );
  }
}

// ==================== 5. تبويب التقارير ====================
class _ReportsTab extends StatelessWidget {
  final List<SaleRecord> sales;
  final List<DebtorCustomer> debtors;
  final List<RentalRecord> rentals;
  final List<ProductItem> products;
  final String Function(double) formatMoney;
  final void Function(SaleRecord) onDeleteSale;

  const _ReportsTab({
    required this.sales,
    required this.debtors,
    required this.rentals,
    required this.products,
    required this.formatMoney,
    required this.onDeleteSale,
  });

  @override
  Widget build(BuildContext context) {
    double totalSales = sales.fold(0, (s, item) => s + item.totalAmount);
    double totalProfit = sales.fold(0, (s, item) => s + item.totalProfit);
    double totalRentalIncome = rentals.where((r) => r.isReturned).fold(0, (s, r) => s + r.calculatedTotal);
    double totalDebts = debtors.fold(0, (s, d) => s + (d.remainingBalance > 0 ? d.remainingBalance : 0));

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('ملخص الأرباح والحركة المالية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _statCard('إجمالي المبيعات', formatMoney(totalSales), Colors.teal),
            _statCard('صافي أرباح البيع', formatMoney(totalProfit), Colors.green),
            _statCard('إيرادات الإيجارات', formatMoney(totalRentalIncome), Colors.deepOrange),
            _statCard('الديون في السوق', formatMoney(totalDebts), Colors.blue),
          ],
        ),
        const SizedBox(height: 16),
        const Text('سجل فواتير البيع الأخيرة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (sales.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد مبيعات مسجلة بعد')))
        else
          ...sales.map((s) => Card(
                child: ListTile(
                  title: Text('فاتورة بقيمة ${formatMoney(s.totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${s.date} | الربح: ${formatMoney(s.totalProfit)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => onDeleteSale(s),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

// ==================== صفحة الإعدادات الشاملة والمزامنة ====================
class _SettingsAndSyncScreen extends StatefulWidget {
  final String storeName;
  final String storePhone;
  final String storeAddress;
  final String currency;
  final List<StoreCategory> categories;
  final int primaryHeaderStartColor;
  final int primaryHeaderEndColor;
  final int appAccentColor;
  final int textPrimaryColor;
  final int textSecondaryColor;
  final int returnedBadgeColor;
  final String? syncedEmail;
  final bool autoSyncEnabled;
  final String Function() exportJson;
  final Future<void> Function(String) importJson;
  final VoidCallback onCategoriesChanged;
  final void Function({
    required String newName,
    required String newPhone,
    required String newAddress,
    required String newCurrency,
    required int newStartColor,
    required int newEndColor,
    required int newAccent,
    required int newTextPrimary,
    required int newTextSecondary,
    required int newReturnedBadge,
    required String? newEmail,
    required bool newAutoSync,
  }) onSaveSettings;

  const _SettingsAndSyncScreen({
    required this.storeName,
    required this.storePhone,
    required this.storeAddress,
    required this.currency,
    required this.categories,
    required this.primaryHeaderStartColor,
    required this.primaryHeaderEndColor,
    required this.appAccentColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.returnedBadgeColor,
    required this.syncedEmail,
    required this.autoSyncEnabled,
    required this.exportJson,
    required this.importJson,
    required this.onCategoriesChanged,
    required this.onSaveSettings,
  });

  @override
  State<_SettingsAndSyncScreen> createState() => _SettingsAndSyncScreenState();
}

class _SettingsAndSyncScreenState extends State<_SettingsAndSyncScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController currencyCtrl;
  late TextEditingController emailCtrl;

  late int startColor;
  late int endColor;
  late int accentColor;
  late int textPrimary;
  late int textSecondary;
  late int returnedBadge;
  late bool autoSync;

  final List> paletteOptions = [
    {'name': 'برتقالي دافئ', 'color': 0xFFD86B3E},
    {'name': 'بنفسجي ملكي', 'color': 0xFF7B4397},
    {'name': 'أزرق سماوي', 'color': 0xFF1572B6},
    {'name': 'أخضر زاهٍ', 'color': 0xFF4CAF50},
    {'name': 'أخضر زمردي', 'color': 0xFF009688},
    {'name': 'أسود داكن', 'color': 0xFF1E1E1E},
    {'name': 'رمادي', 'color': 0xFF757575},
    {'name': 'أحمر ياقوتي', 'color': 0xFFD32F2F},
    {'name': 'كحلي ليلي', 'color': 0xFF1A237E},
  ];

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.storeName);
    phoneCtrl = TextEditingController(text: widget.storePhone);
    addressCtrl = TextEditingController(text: widget.storeAddress);
    currencyCtrl = TextEditingController(text: widget.currency);
    emailCtrl = TextEditingController(text: widget.syncedEmail ?? '');

    startColor = widget.primaryHeaderStartColor;
    endColor = widget.primaryHeaderEndColor;
    accentColor = widget.appAccentColor;
    textPrimary = widget.textPrimaryColor;
    textSecondary = widget.textSecondaryColor;
    returnedBadge = widget.returnedBadgeColor;
    autoSync = widget.autoSyncEnabled;
  }

  void _saveNow() {
    widget.onSaveSettings(
      newName: nameCtrl.text.trim().isEmpty ? 'محل الكهربائيات والإنشائيات' : nameCtrl.text.trim(),
      newPhone: phoneCtrl.text.trim(),
      newAddress: addressCtrl.text.trim(),
      newCurrency: currencyCtrl.text.trim().isEmpty ? 'د.ع' : currencyCtrl.text.trim(),
      newStartColor: startColor,
      newEndColor: endColor,
      newAccent: accentColor,
      newTextPrimary: textPrimary,
      newTextSecondary: textSecondary,
      newReturnedBadge: returnedBadge,
      newEmail: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      newAutoSync: autoSync,
    );
  }

  // نسخ احتياطي محلي على الهاتف
  Future<void> _exportLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/backup_${DateTime.now().
