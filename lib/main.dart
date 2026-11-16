import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShopManagerApp());
}

class ShopManagerApp extends StatelessWidget {
  const ShopManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة المحل',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Cairo', // إذا كنت تستخدم خط عربي أضفه هنا
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // ================== البيانات الأساسية ==================
  List<Map<String, dynamic>> debts = [];
  List<Map<String, dynamic>> rents = [];
  List<Map<String, dynamic>> inventory = [];
  List<String> categories = ['عام', 'كهرباء', 'مطاعم'];
  
  bool autoBackup = true;
  Color globalPriceColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _loadData(); // تحميل البيانات عند فتح التطبيق
  }

  // ================== دوال حفظ واسترجاع البيانات ==================
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      debts = List<Map<String, dynamic>>.from(jsonDecode(prefs.getString('debts') ?? '[]'));
      rents = List<Map<String, dynamic>>.from(jsonDecode(prefs.getString('rents') ?? '[]'));
      inventory = List<Map<String, dynamic>>.from(jsonDecode(prefs.getString('inventory') ?? '[]'));
      categories = List<String>.from(jsonDecode(prefs.getString('categories') ?? '["عام", "كهرباء"]'));
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('debts', jsonEncode(debts));
    await prefs.setString('rents', jsonEncode(rents));
    await prefs.setString('inventory', jsonEncode(inventory));
    await prefs.setString('categories', jsonEncode(categories));
  }

  // دوال الحسابات
  double get totalDebts => debts.fold(0, (sum, item) => sum + (item['amount'] as num));
  double get receivedDebts => debts.where((item) => item['isReceived']).fold(0, (sum, item) => sum + (item['amount'] as num));
  int get debtorsCount => debts.map((item) => item['name']).toSet().length;
  int get rentersCount => rents.map((item) => item['name']).toSet().length;

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
        title: Text(['الرئيسية', 'الديون', 'الإيجار', 'المخزن', 'الإعدادات'][_currentIndex]),
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
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'الديون'),
          BottomNavigationBarItem(icon: Icon(Icons.house), label: 'الإيجار'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }

  // ====================== 1. الشاشة الرئيسية (الإحصائيات) ======================
  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ملخص الإحصائيات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildStatCard('إجمالي الديون المسجلة', '${totalDebts.toStringAsFixed(0)} د.ع', Colors.orange),
          _buildStatCard('الديون المستلمة', '${receivedDebts.toStringAsFixed(0)} د.ع', Colors.green),
          _buildStatCard('عدد المدينين (الأشخاص)', '$debtorsCount أشخاص', Colors.blue),
          _buildStatCard('عدد المؤجرين (الأشخاص)', '$rentersCount أشخاص', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        trailing: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  // ====================== 2. شاشة الديون ======================
  Widget _buildDebtsScreen() {
    return Scaffold(
      body: debts.isEmpty
          ? const Center(child: Text('لا توجد ديون مسجلة'))
          : ListView.builder(
              itemCount: debts.length,
              itemBuilder: (context, index) {
                final debt = debts[index];
                DateTime date = DateTime.parse(debt['date']);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(debt['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd').format(date),
                      style: TextStyle(
                        color: debt['isReceived'] ? Colors.red : Colors.blue, // اللون الأزرق للدين والأحمر للاستلام
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${debt['amount']} د.ع', style: const TextStyle(fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _editName(debts, index, 'اسم المدين'),
                        ),
                        Checkbox(
                          value: debt['isReceived'],
                          onChanged: (val) {
                            setState(() => debt['isReceived'] = val);
                            _saveData();
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDebt,
        backgroundColor: Colors.blue,
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة دين جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الشخص')),
              TextField(controller: amountController, decoration: const InputDecoration(labelText: 'المبلغ'), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              ListTile(
                title: Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                trailing: const Icon(Icons.calendar_today, color: Colors.blue),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  setState(() {
                    debts.add({
                      'name': nameController.text,
                      'amount': double.tryParse(amountController.text) ?? 0.0,
                      'date': selectedDate.toIso8601String(),
                      'isReceived': false,
                    });
                  });
                  _saveData();
                  Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== 3. شاشة الإيجار ======================
  Widget _buildRentsScreen() {
    return Scaffold(
      body: rents.isEmpty
          ? const Center(child: Text('لا توجد إيجارات مسجلة'))
          : ListView.builder(
              itemCount: rents.length,
              itemBuilder: (context, index) {
                final rent = rents[index];
                DateTime date = DateTime.parse(rent['date']);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(rent['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd').format(date),
                      style: TextStyle(
                        color: rent['isDelivered'] ? Colors.red : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${rent['amount']} د.ع', style: const TextStyle(fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _editName(rents, index, 'اسم المستأجر'),
                        ),
                        Checkbox(
                          value: rent['isDelivered'],
                          onChanged: (val) {
                            setState(() => rent['isDelivered'] = val);
                            _saveData();
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRent,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addRent() {
    TextEditingController nameController = TextEditingController();
    TextEditingController amountController = TextEditingController();
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
                    controller: controller, focusNode: focusNode,
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
              if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                setState(() {
                  rents.add({
                    'name': nameController.text,
                    'amount': double.tryParse(amountController.text) ?? 0.0,
                    'date': DateTime.now().toIso8601String(),
                    'isDelivered': false,
                  });
                });
                _saveData();
                Navigator.pop(context);
              }
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
      body: inventory.isEmpty
          ? const Center(child: Text('المخزن فارغ'))
          : ListView.builder(
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final item = inventory[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(item['name']),
                    subtitle: item['category'] != null ? Text('القسم: ${item['category']}') : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item['price']} د.ع',
                          style: TextStyle(color: Color(item['color']), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _editName(inventory, index, 'اسم الصنف'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addInventoryItem,
        backgroundColor: Colors.green,
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
          title: const Text('إضافة صنف جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصنف')),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'السعر'), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  hint: const Text('اختر القسم (اختياري)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('بدون قسم')),
                    ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (val) => setDialogState(() => selectedCategory = val),
                ),
                const SizedBox(height: 15),
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
                if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  setState(() {
                    inventory.add({
                      'name': nameController.text,
                      'price': double.tryParse(priceController.text) ?? 0.0,
                      'category': selectedCategory,
                      'color': selectedColor.value,
                    });
                  });
                  _saveData();
                  Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== 5. شاشة الإعدادات ======================
  Widget _buildSettingsScreen() {
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('الحفظ التلقائي'),
          subtitle: const Text('حفظ البيانات تلقائياً عند كل تعديل'),
          value: autoBackup,
          onChanged: (val) {
            setState(() => autoBackup = val);
            _saveData();
          },
        ),
        ListTile(
          leading: const Icon(Icons.category, color: Colors.blue),
          title: const Text('إدارة الأقسام (للمخزن)'),
          onTap: _manageCategories,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.qr_code, color: Colors.green),
          title: const Text('إنشاء نسخة احتياطية (باركود)'),
          subtitle: const Text('امسحه من هاتف آخر لاستعادة البيانات'),
          onTap: _showBackupQR,
        ),
        ListTile(
          leading: const Icon(Icons.share, color: Colors.purple),
          title: const Text('مشاركة قاعدة البيانات'),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يتطلب إضافة مكتبة share_plus للهاتف'))),
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
          title: const Text('الأقسام'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: categories.map((c) => Chip(
                  label: Text(c),
                  onDeleted: () {
                    setDialogState(() => categories.remove(c));
                    setState(() {});
                    _saveData();
                  },
                )).toList(),
              ),
              TextField(controller: catController, decoration: const InputDecoration(labelText: 'قسم جديد...')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
            ElevatedButton(
              onPressed: () {
                if (catController.text.isNotEmpty) {
                  setDialogState(() => categories.add(catController.text));
                  setState(() {});
                  _saveData();
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
    Map<String, dynamic> backupData = {
      'debts': debts, 'rents': rents, 'inventory': inventory, 'categories': categories,
    };
    String jsonString = jsonEncode(backupData);
    // ضغط البيانات لتناسب حجم الباركود
    String base64Data = base64Encode(utf8.encode(jsonString));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('امسح الباركود'),
        content: SizedBox(
          width: 250, height: 250,
          child: QrImageView(data: base64Data, version: QrVersions.auto, size: 250.0),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
      ),
    );
  }

  // دوال مساعدة
  void _editName(List<Map<String, dynamic>> list, int index, String label) {
    TextEditingController controller = TextEditingController(text: list[index]['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل $label'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              setState(() => list[index]['name'] = controller.text);
              _saveData();
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showGlobalSearch(BuildContext context) {
    showSearch(context: context, delegate: GlobalSearchDelegate(debts: debts, rents: rents, inventory: inventory));
  }
}

// ====================== كلاس البحث العام ======================
class GlobalSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> debts, rents, inventory;
  GlobalSearchDelegate({required this.debts, required this.rents, required this.inventory});

  @override
  List<Widget> buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) {
    List<Map<String, dynamic>> results = [];
    debts.where((d) => d['name'].toString().toLowerCase().contains(query.toLowerCase())).forEach((d) => results.add({...d, 'type': 'دين', 'icon': Icons.money}));
    rents.where((r) => r['name'].toString().toLowerCase().contains(query.toLowerCase())).forEach((r) => results.add({...r, 'type': 'إيجار', 'icon': Icons.house}));
    inventory.where((i) => i['name'].toString().toLowerCase().contains(query.toLowerCase())).forEach((i) => results.add({...i, 'type': 'مخزن', 'icon': Icons.inventory}));

    if (results.isEmpty) return const Center(child: Text('لا توجد نتائج مطابقة'));

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: Icon(item['icon'], color: Colors.blue),
          title: Text(item['name']),
          subtitle: Text(item['type']),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
