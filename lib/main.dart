
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SanbulaApp());
}

class SanbulaApp extends StatefulWidget {
  const SanbulaApp({super.key});

  @override
  State<SanbulaApp> createState() => _SanbulaAppState();
}

class _SanbulaAppState extends State<SanbulaApp> {
  Color primaryColor = const Color(0xFF0B2A4A);
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      primaryColor = Color(
        prefs.getInt('primaryColor') ?? 0xFF0B2A4A,
      );
      darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> changeTheme(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.toARGB32());

    setState(() {
      primaryColor = color;
    });
  }

  Future<void> toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);

    setState(() {
      darkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'السنبلة',

      locale: const Locale('ar'),

      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      themeMode: darkMode
          ? ThemeMode.dark
          : ThemeMode.light,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
        ),
        scaffoldBackgroundColor:
            const Color(0xFFF4F6F8),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
      ),

      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MainScreen(
          onChangeTheme: changeTheme,
          darkMode: darkMode,
          onDarkModeChanged: toggleDarkMode,
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(Color) onChangeTheme;
  final bool darkMode;
  final Function(bool) onDarkModeChanged;

  const MainScreen({
    super.key,
    required this.onChangeTheme,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final List<String> titles = [
    'الرئيسية',
    'المبيعات',
    'المخزن',
    'الديون',
    'الإيجارات',
    'التقارير',
    'الإعدادات',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const SalesPage(),
      const InventoryPage(),
      const DebtsPage(),
      const RentalsPage(),
      const ReportsPage(),
      SettingsPage(
        onChangeTheme: widget.onChangeTheme,
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('🌾 السنبلة - ${titles[selectedIndex]}'),
      ),

      body: pages[selectedIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale),
            label: 'البيع',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2),
            label: 'المخزن',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'الديون',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman),
            label: 'الإيجارات',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'التقارير',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget dashboardCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, size: 35, color: color),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AppDatabase.getProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(15),
          children: [
            const Text(
              'مرحباً بك في السنبلة 🌾',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                dashboardCard(
                  context,
                  'عدد الأصناف',
                  '${products.length}',
                  Icons.inventory,
                  Colors.blue,
                ),
                dashboardCard(
                  context,
                  'المبيعات',
                  '0 د.ع',
                  Icons.point_of_sale,
                  Colors.green,
                ),
                dashboardCard(
                  context,
                  'الديون',
                  '0 د.ع',
                  Icons.money_off,
                  Colors.red,
                ),
                dashboardCard(
                  context,
                  'الإيجارات',
                  '0',
                  Icons.handyman,
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 15),

            const Text(
              'أقسام التطبيق',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'إدارة المبيعات والمخزون والديون '
              'والإيجارات من مكان واحد.',
            ),
          ],
        );
      },
    );
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  Future<void> addProduct() async {
    final name = TextEditingController();
    final category = TextEditingController();
    final quantity = TextEditingController();
    final buy = TextEditingController();
    final sell = TextEditingController();
    final barcode = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة صنف جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(name, 'اسم الصنف'),
              field(category, 'القسم'),
              field(barcode, 'الباركود'),
              field(quantity, 'الكمية',
                  keyboard: TextInputType.number),
              field(buy, 'سعر الشراء',
                  keyboard: TextInputType.number),
              field(sell, 'سعر البيع',
                  keyboard: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;

              await AppDatabase.addProduct({
                'name': name.text.trim(),
                'category': category.text,
                'barcode': barcode.text,
                'quantity':
                    double.tryParse(quantity.text) ?? 0,
                'buyPrice':
                    double.tryParse(buy.text) ?? 0,
                'sellPrice':
                    double.tryParse(sell.text) ?? 0,
              });

              if (!mounted) return;
              Navigator.pop(dialogContext);
              setState(() {});
            },
            child: const Text('حفظ الصنف'),
          ),
        ],
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: AppDatabase.getProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final products = snapshot.data!;

          if (products.isEmpty) {
            return const Center(
              child: Text('لا توجد أصناف. أضف أول صنف.'),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.electrical_services),
                  ),
                  title: Text(product['name']),
                  subtitle: Text(
                    'القسم: ${product['category'] ?? ''}\n'
                    'الكمية: ${product['quantity']}\n'
                    'الشراء: ${product['buyPrice']} د.ع\n'
                    'البيع: ${product['sellPrice']} د.ع',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      await AppDatabase.deleteProduct(
                        product['id'],
                      );
                      setState(() {});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: addProduct,
        icon: const Icon(Icons.add),
        label: const Text('إضافة صنف'),
      ),
    );
  }
}

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('نظام المبيعات وإنشاء الفواتير'),
    );
  }
}

class DebtsPage extends StatelessWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('إدارة ديون الزبائن والدفعات'),
    );
  }
}

class RentalsPage extends StatelessWidget {
  const RentalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('إدارة إيجارات المعدات'),
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('تقارير المبيعات والأرباح والمخزون'),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final Function(Color) onChangeTheme;
  final bool darkMode;
  final Function(bool) onDarkModeChanged;

  const SettingsPage({
    super.key,
    required this.onChangeTheme,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF0B2A4A),
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
      const Color(0xFFF26522),
      const Color(0xFF6A1B9A),
      const Color(0xFFB8860B),
    ];

    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        const Text(
          'إعدادات التطبيق',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        const Text('اختر اللون الأساسي'),

        Wrap(
          spacing: 12,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () => onChangeTheme(color),
              child: CircleAvatar(
                backgroundColor: color,
                radius: 23,
              ),
            );
          }).toList(),
        ),

        const Divider(height: 35),

        SwitchListTile(
          title: const Text('الوضع الداكن'),
          value: darkMode,
          onChanged: onDarkModeChanged,
        ),

        const Divider(),

        const ListTile(
          leading: Icon(Icons.backup),
          title: Text('النسخ الاحتياطي'),
          subtitle: Text('سيتم ربط النسخ الاحتياطي في المرحلة التالية'),
        ),

        const ListTile(
          leading: Icon(Icons.print),
          title: Text('إعدادات الطابعة الحرارية'),
        ),

        const ListTile(
          leading: Icon(Icons.cloud_sync),
          title: Text('مزامنة البيانات'),
        ),

        const ListTile(
          leading: Icon(Icons.info),
          title: Text('عن تطبيق السنبلة'),
          subtitle: Text('إدارة محل كهربائيات وإنشائيات'),
        ),
      ],
    );
  }
}
