import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const ShopManagerApp());
}

class ShopManagerApp extends StatelessWidget {
  const ShopManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة المحل',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ====================== الشاشة الرئيسية ======================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // قاعدة البيانات الوهمية (في التطبيق الحقيقي تستخدم SQLite أو Hive)
  List<Map<String, dynamic>> debts = [
    {'name': 'أحمد محمد', 'amount': 5000.0, 'date': DateTime.now(), 'isReceived': false},
    {'name': 'محمد علي', 'amount': 2000.0, 'date': DateTime.now(), 'isReceived': true},
  ];

  List<Map<String, dynamic>> rents = [
    {'name': 'علي حسن', 'amount': 15000.0, 'date': DateTime.now(), 'isDelivered': false},
    {'name': 'حسين كريم', 'amount': 10000.0, 'date': DateTime.now(), 'isDelivered': true},
  ];

  List<Map<String, dynamic>> inventory = [
    {'name': 'مصباح 40 واط', 'price': 1500.0, 'category': 'قسم 5', 'color': Colors.green},
    {'name': 'مفتاح كهرباء', 'price': 500.0, 'category': null, 'color': Colors.green},
  ];

  List<String> categories = ['قسم 1', 'قسم 5', 'قسم المصابيح']; // أقسام قابلة للإضافة
  Color globalPriceColor = Colors.green; // لون السعر الافتراضي
  bool autoBackup = true; // تفعيل النسخ التلقائي
  String searchQuery = ''; // للبحث العام

  // دوال الحسابات
  double get totalDebts => debts.fold(0, (sum, item) => sum + (item['amount'] as double));
  double get receivedDebts => debts.where((item) => item['isReceived']).fold(0, (sum, item) => sum + (item['amount'] as double));
  int get debtorsCount => debts.map((item) => item['name']).toSet().length;
  int get rentersCount => rents.map((item) => item['name']).toSet().length;

  // إعدادات الحفظ (لأغراض النسخ الاحتياطي)
  Map<String, dynamic> get backupData => {
    'debts': debts,
    'rents': rents,
    'inventory': inventory,
    'categories': categories,
  };

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      _buildHomeScreen(),
      _buildDebtsScreen(),
      _buildRentsScreen(),
      _buildInventoryScreen(),
      _buildSettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام إدارة المحل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showGlobalSearch(context),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'الديون'),
          BottomNavigationBarItem(icon: Icon(Icons.house), label: 'الإيجار'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }

  // ====================== 1. شاشة الإحصائيات الرئيسية ======================
  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ملخص الإحصائيات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildStatCard('إجمالي الديون المسجلة', '$totalDebts د.ع', Colors.orange),
          _buildStatCard('الديون المستلمة', '$receivedDebts د.ع', Colors.green),
          _buildStatCard('عدد المدينين (الأشخاص)', '$debtorsCount أشخاص', Colors.blue),
          _buildStatCard('عدد المؤجرين (الأشخاص)', '$rentersCount أشخاص', Colors.purple),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showGlobalSearch(context),
            icon: const Icon(Icons.search),
            label: const Text('البحث الشامل (مخزن، دين، إيجار)'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  // ====================== 2. شاشة الديون ======================
  Widget _buildDebtsScreen() {
    return Scaffold(
      body: ListView.builder(
        itemCount: debts.length,
        itemBuilder: (context, index) {
          final debt = debts[index];
          return ListTile(
            title: Text(debt['name']),
            subtitle: Text(
              DateFormat('yyyy-MM-dd').format(debt['date']),
              style: TextStyle(
                color: debt['isReceived'] ? Colors.red : Colors.blue, // تغيير لون التاريخ
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${debt['amount']} د.ع'),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _editDebt(index),
                ),
                Checkbox(
                  value: debt['isReceived'],
                  onChanged: (val) {
                    setState(() => debt['isReceived'] = val);
                  },
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDebt,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addDebt() {
    TextEditingController nameController = TextEditingController();
    TextEditingController amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دين'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الشخص')),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'المبلغ'), keyboardType: TextInputType.number),
            ListTile(
              title: Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (picked != null) selectedDate = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                debts.add({
                  'name': nameController.text,
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'date': selectedDate,
                  'isReceived': false,
                });
              });
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _editDebt(int index) {
    TextEditingController nameController = TextEditingController(text: debts[index]['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الاسم'),
        content: TextField(controller: nameController),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              setState(() => debts[index]['name'] = nameController.text);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // ====================== 3. شاشة الإيجار ======================
  Widget _buildRentsScreen() {
    return Scaffold(
      body: ListView.builder(
        itemCount: rents.length,
        itemBuilder: (context, index) {
          final rent = rents[index];
          return ListTile(
            title: Text(rent['name']),
            subtitle: Text(
              DateFormat('yyyy-MM-dd').format(rent['date']),
              style: TextStyle(
                color: rent['isDelivered'] ? Colors.red : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${rent['amount']} د.ع'),
                Checkbox(
                  value: rent['isDelivered'],
                  onChanged: (val) => setState(() => rent['isDelivered'] = val),
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRent,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addRent() {
    TextEditingController nameController = TextEditingController();
    TextEditingController amountController = TextEditingController();
    
    // فلترة الأسماء السابقة لظهورها كاقتراحات
    List<String> existingNames = rents.map((e) => e['name'].toString()).toSet().toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة إيجار جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                  return existingNames.where((String option) => option.contains(textEditingValue.text));
                },
                onSelected: (String selection) => nameController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  nameController = controller;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'اسم المستأجر (اكتب للبحث)'),
                  );
                },
              ),
              TextField(controller: amountController, decoration: const InputDecoration(labelText: 'المبلغ'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                rents.add({
                  'name': nameController.text,
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'date': DateTime.now(),
                  'isDelivered': false,
                });
              });
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // ====================== 4. شاشة المخزن ======================
  Widget _buildInventoryScreen() {
    return Scaffold(
      body: ListView.builder(
        itemCount: inventory.length,
        itemBuilder: (context, index) {
          final item = inventory[index];
          return ListTile(
            leading: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.grey), // زر البحث بالصورة (وهمي)
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('البحث بالصورة يتطلب إضافة كاميرا و AI'))),
            ),
            title: Text(item['name']),
            subtitle: item['category'] != null ? Text('القسم: ${item['category']}') : null,
            trailing: Text(
              '${item['price']} د.ع',
              style: TextStyle(color: item['color'], fontWeight: FontWeight.bold, fontSize: 16),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addInventoryItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addInventoryItem() {
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    String? selectedCategory;
    Color selectedColor = globalPriceColor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة صنف'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصنف')),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'السعر'), keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  hint: const Text('اختر القسم (اختياري)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('بدون قسم')),
                    ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (val) => setDialogState(() => selectedCategory = val),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('لون السعر: '),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('اختر اللون'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: selectedColor,
                                onColorChanged: (color) => setDialogState(() => selectedColor = color),
                              ),
                            ),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))],
                          ),
                        );
                      },
                      child: Container(width: 30, height: 30, color: selectedColor, decoration: BoxDecoration(border: Border.all())),
                    )
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  inventory.add({
                    'name': nameController.text,
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'category': selectedCategory,
                    'color': selectedColor,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== 5. شاشة الإعدادات والنسخ الاحتياطي ======================
  Widget _buildSettingsScreen() {
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('الحفظ التلقائي والمزامنة'),
          subtitle: const Text('حفظ نسخة احتياطية تلقائياً على الهاتف'),
          value: autoBackup,
          onChanged: (val) => setState(() => autoBackup = val),
        ),
        ListTile(
          leading: const Icon(Icons.add_box, color: Colors.blue),
          title: const Text('إدارة الأقسام'),
          onTap: _manageCategories,
        ),
        ListTile(
          leading: const Icon(Icons.qr_code, color: Colors.green),
          title: const Text('إنشاء نسخة احتياطية (باركود)'),
          subtitle: const Text('امسحه من هاتف آخر للاستعادة'),
          onTap: _showBackupQR,
        ),
        ListTile(
          leading: const Icon(Icons.download, color: Colors.orange),
          title: const Text('استعادة نسخة احتياطية'),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يفتح الكاميرا لقراءة الباركود (تتطلب كود mobile_scanner)'))),
        ),
        ListTile(
          leading: const Icon(Icons.share, color: Colors.purple),
          title: const Text('مشاركة قاعدة البيانات'),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يتطلب حزمة share_plus'))),
        ),
      ],
    );
  }

  void _manageCategories() {
    TextEditingController catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إدارة الأقسام'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: catController, decoration: const InputDecoration(labelText: 'اسم القسم الجديد')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: categories.map((c) => Chip(
                  label: Text(c),
                  onDeleted: () => setDialogState(() {
                    categories.remove(c);
                    setState(() {});
                  }),
                )).toList(),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
            ElevatedButton(
              onPressed: () {
                if (catController.text.isNotEmpty) {
                  setDialogState(() => categories.add(catController.text));
                  setState(() {});
                  catController.clear();
                }
              },
              child: const Text('إضافة'),
            )
          ],
        ),
      ),
    );
  }

  void _showBackupQR() {
    String jsonString = jsonEncode(backupData);
    String base64Data = base64Encode(utf8.encode(jsonString));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نسخة احتياطية (باركود)'),
        content: SizedBox(
          width: 250,
          height: 250,
          child: QrImageView(
            data: base64Data,
            version: QrVersions.auto,
            size: 250.0,
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
      ),
    );
  }

  // ====================== شاشة البحث العام ======================
  void _showGlobalSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: GlobalSearchDelegate(
        debts: debts,
        rents: rents,
        inventory: inventory,
      ),
    );
  }
}

// كلاس البحث الشامل
class GlobalSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> debts;
  final List<Map<String, dynamic>> rents;
  final List<Map<String, dynamic>> inventory;

  GlobalSearchDelegate({required this.debts, required this.rents, required this.inventory});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    // دمج النتائج وفلترتها بناءً على الحرف/الكلمة
    List<Map<String, dynamic>> results = [];
    
    debts.where((d) => d['name'].toString().contains(query)).forEach((d) {
      results.add({...d, 'type': 'دين'});
    });
    rents.where((r) => r['name'].toString().contains(query)).forEach((r) {
      results.add({...r, 'type': 'إيجار'});
    });
    inventory.where((i) => i['name'].toString().contains(query)).forEach((i) {
      results.add({...i, 'type': 'مخزن'});
    });

    if (results.isEmpty) return const Center(child: Text('لا توجد نتائج'));

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: Icon(item['type'] == 'دين' ? Icons.money : item['type'] == 'إيجار' ? Icons.house : Icons.inventory, color: Colors.blue),
          title: Text(item['name']),
          subtitle: Text(item['type']),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context); // البحث الفوري بمجرد كتابة حرف
  }
}
