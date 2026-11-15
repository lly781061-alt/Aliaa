import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'export.dart';
import 'store.dart';

const kInk = Color(0xFF1F2A30);
final navKey = GlobalKey<NavigatorState>();
bool _bannerHidden = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.init();
  await store.autoBackupIfDue();
  runApp(const ShopApp());
}

// ---------------------------------------------------------------- theme
double rad() => const [8.0, 14.0, 22.0][store.rad];
Color opNew() => Color(kOpHex[store.newCol]); // new operation: new debt / new rental
Color opRecv() => Color(kOpHex[store.recvCol]); // receipt: debt payment / rental return
Color shadeHex(int v, double f) => Color.fromARGB(
    255, (((v >> 16) & 255) * f).round(), (((v >> 8) & 255) * f).round(), ((v & 255) * f).round());

ThemeData _theme(Brightness b) {
  final acc = Color(kAccHex[store.acc]);
  final onAcc = acc.computeLuminance() > 0.5 ? kInk : Colors.white;
  final dark = b == Brightness.dark;
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(rad()));
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: acc, brightness: b)
        .copyWith(primary: acc, onPrimary: onAcc),
    scaffoldBackgroundColor: dark ? const Color(0xFF12171B) : const Color(0xFFF3F5F7),
    appBarTheme: const AppBarTheme(backgroundColor: kInk, foregroundColor: Colors.white),
    navigationBarTheme: NavigationBarThemeData(indicatorColor: acc.withAlpha(70)),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            shape: shape, padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: shape)),
  );
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (_, __) => MaterialApp(
          navigatorKey: navKey,
          title: 'نظام مبيعات المحل',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          themeMode: store.theme == 'light'
              ? ThemeMode.light
              : store.theme == 'dark'
                  ? ThemeMode.dark
                  : ThemeMode.system,
          builder: (c, w) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(store.fs / 16)),
              child: w!),
          home: const Home(),
        ),
      );
}

// ---------------------------------------------------------------- helpers
class Live extends StatelessWidget {
  final WidgetBuilder b;
  const Live(this.b, {super.key});
  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: store, builder: (ctx, _) => b(ctx));
}

void toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

Future<bool> confirmDlg(BuildContext c, String t) async =>
    await showDialog<bool>(
        context: c,
        builder: (ctx) => AlertDialog(title: Text(t), actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
            ])) ??
    false;

Widget tf(TextEditingController c, String l,
        {bool isNum = false, bool tel = false, int lines = 1, ValueChanged<String>? onChanged}) =>
    Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
            controller: c,
            onChanged: onChanged,
            maxLines: lines,
            keyboardType: tel
                ? TextInputType.phone
                : isNum
                    ? TextInputType.number
                    : TextInputType.text,
            decoration: InputDecoration(
                labelText: l,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(rad())))));

const _bold = TextStyle(fontWeight: FontWeight.w800);

Widget thumb(String img, {double s = 46}) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.memory(imgBytes(img), width: s, height: s, fit: BoxFit.cover, gaplessPlayback: true));

void viewImg(BuildContext c, String img) => showDialog(
    context: c,
    builder: (ctx) => Dialog(
        child: InteractiveViewer(child: Image.memory(imgBytes(img), fit: BoxFit.contain))));

Widget imgView(BuildContext c, String img) => GestureDetector(
    onTap: () => viewImg(c, img),
    child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(rad()),
            child: Image.memory(imgBytes(img), height: 170, width: double.infinity, fit: BoxFit.contain))));

Future<void> callPhone(String p) => launchUrl(Uri.parse('tel:$p'));

class PhotoField extends StatefulWidget {
  final String label, initial;
  final ValueChanged<String> onChanged;
  const PhotoField({super.key, required this.label, required this.initial, required this.onChanged});
  @override
  State<PhotoField> createState() => _PhotoFieldState();
}

class _PhotoFieldState extends State<PhotoField> {
  late String img = widget.initial;
  Future<void> pick(ImageSource s) async {
    try {
      final x = await ImagePicker().pickImage(source: s, maxWidth: 800, imageQuality: 60);
      if (x == null) return;
      final b = await x.readAsBytes();
      setState(() => img = base64Encode(b));
      widget.onChanged(img);
    } catch (_) {
      if (mounted) toast(context, 'تعذر فتح الكاميرا أو المعرض');
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('كاميرا'))),
          const SizedBox(width: 8),
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('المعرض'))),
        ]),
        if (img.isNotEmpty) ...[
          imgView(context, img),
          TextButton(
              onPressed: () {
                setState(() => img = '');
                widget.onChanged('');
              },
              child: const Text('إزالة الصورة')),
        ],
      ]);
}

/// Rounded card with soft shadow and an optional colored stripe on the start side.
class Panel extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? stripe;
  final EdgeInsets margin;
  const Panel(
      {super.key, required this.child, this.onTap, this.stripe, this.margin = const EdgeInsets.only(bottom: 10)});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = BorderRadius.circular(rad());
    return Padding(
        padding: margin,
        child: DecoratedBox(
            decoration: BoxDecoration(
                color: dark ? const Color(0xFF1C2328) : Colors.white,
                borderRadius: r,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(dark ? 64 : 18),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]),
            child: ClipRRect(
                borderRadius: r,
                child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                        onTap: onTap,
                        child: IntrinsicHeight(
                            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          if (stripe != null) Container(width: 5, color: stripe),
                          Expanded(child: Padding(padding: const EdgeInsets.all(12), child: child)),
                        ])))))));
  }
}

Widget itemRow({Widget? lead, required String title, Widget? sub, Widget? trail}) => Row(children: [
      if (lead != null) ...[lead, const SizedBox(width: 10)],
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (sub != null) sub,
      ])),
      if (trail != null) trail,
    ]);

Widget subText(String s, {Color? c}) =>
    Text(s, style: TextStyle(fontSize: 12.5, color: c ?? Colors.grey.shade600));

Widget secTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
    child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)));

Widget bigStat(IconData i, Color c, String t, String v) => Expanded(
    child: Panel(
        margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: c.withAlpha(36), shape: BoxShape.circle),
              child: Icon(i, color: c, size: 20)),
          const SizedBox(height: 8),
          Text(t, style: const TextStyle(fontSize: 12)),
          Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ])));

Widget prodAvatar(Product p) {
  if (p.img.isNotEmpty) return thumb(p.img);
  final c = p.cat == kCats[0]
      ? const Color(0xFFF2A900)
      : p.cat == kCats[1]
          ? const Color(0xFFE8590C)
          : const Color(0xFF868E96);
  final ic = p.cat == kCats[0] ? Icons.bolt : p.cat == kCats[1] ? Icons.foundation : Icons.category;
  return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: c.withAlpha(40), borderRadius: BorderRadius.circular(10)),
      child: Icon(ic, color: c));
}

Widget qtyText(Product p) => subText(
    p.qty <= 0 ? 'نفدت الكمية' : 'المتوفر: ${p.qty}${p.qty <= store.low ? ' (منخفض)' : ''}',
    c: p.qty <= 0
        ? Colors.red
        : p.qty <= store.low
            ? Colors.orange.shade800
            : Colors.green.shade700);

void showInvoice(BuildContext c, Sale s) => showDialog(
    context: c,
    builder: (ctx) => AlertDialog(
          title: Text('${s.kind == 'rent' ? 'إيجار' : 'فاتورة'} ${s.no}'),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            SelectableText(s.text()),
            const SizedBox(height: 12),
            shareRow(ctx, () => saleDoc(s)),
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
        ));

List<Product> filtered(String cat, String q) => store.prods
    .where((p) => (cat == 'الكل' || p.cat == cat) && p.name.toLowerCase().contains(q.trim().toLowerCase()))
    .toList();

class Filters extends StatelessWidget {
  final String cat;
  final ValueChanged<String> onCat;
  final ValueChanged<String> onQ;
  const Filters(this.cat, this.onCat, this.onQ, {super.key});
  @override
  Widget build(BuildContext context) => Column(children: [
        TextField(
            onChanged: onQ,
            decoration: InputDecoration(
                hintText: 'ابحث عن صنف',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(rad())))),
        const SizedBox(height: 6),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final c in ['الكل', ...kCats])
                Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(label: Text(c), selected: cat == c, onSelected: (_) => onCat(c))),
            ])),
      ]);
}

// ---------------------------------------------------------------- backup helpers
Future<void> backupToDrive(BuildContext c) async {
  try {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/shop-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json');
    await f.writeAsString(store.exportJson());
    store.markDrive();
    await Share.shareXFiles([XFile(f.path)], text: 'نسخة احتياطية - ${store.shop}');
  } catch (_) {
    if (c.mounted) toast(c, 'تعذر إنشاء النسخة');
  }
}

Future<void> restoreFromFile(BuildContext c) async {
  final r = await FilePicker.platform.pickFiles();
  if (r == null || r.files.single.path == null) return;
  try {
    final s = await File(r.files.single.path!).readAsString();
    jsonDecode(s);
    if (!c.mounted) return;
    if (!await confirmDlg(c, 'ستُستبدل بيانات الجهاز الحالية بالنسخة. متابعة؟')) return;
    store.importJson(s);
    if (c.mounted) toast(c, 'تمت الاستعادة');
  } catch (_) {
    if (c.mounted) toast(c, 'الملف غير صالح');
  }
}

// ---------------------------------------------------------------- home
class _Tab {
  final String label;
  final IconData icon;
  final Widget Function() page;
  _Tab(this.label, this.icon, this.page);
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  int tab = 0;
  String _sig = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store.addListener(_shortcuts);
    _shortcuts();
    QuickActions().initialize(_onQuick);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    store.removeListener(_shortcuts);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) store.autoBackupIfDue();
  }

  void _shortcuts() {
    final items = <ShortcutItem>[
      if (store.qDebt) ShortcutItem(type: 'debt', localizedTitle: 'تسجيل دين'),
      if (store.qRent) ShortcutItem(type: 'rent', localizedTitle: 'إيجار جديد'),
      if (store.qStock) ShortcutItem(type: 'stock', localizedTitle: 'إضافة صنف'),
      if (store.qSell) ShortcutItem(type: 'sell', localizedTitle: 'بيع جديد'),
    ];
    final sig = items.map((e) => e.type).join(',');
    if (sig == _sig) return;
    _sig = sig;
    try {
      QuickActions().setShortcutItems(items).catchError((_) {});
    } catch (_) {}
  }

  void _onQuick(String t) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = navKey.currentContext;
      if (c == null) return;
      if (t == 'debt') {
        newDebt(c);
      } else if (t == 'rent') {
        newRental(c);
      } else if (t == 'stock') {
        editProduct(c);
      } else if (t == 'sell') {
        setState(() => tab = 0);
      }
    });
  }

  Widget _qtile(IconData i, String l, Color c, VoidCallback f) => Expanded(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
              color: c.withAlpha(30),
              borderRadius: BorderRadius.circular(rad()),
              child: InkWell(
                  borderRadius: BorderRadius.circular(rad()),
                  onTap: f,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Column(children: [
                        Icon(i, color: c),
                        const SizedBox(height: 3),
                        Text(l, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
                      ]))))));

  @override
  Widget build(BuildContext context) => Live((_) {
        final tabs = <_Tab>[
          _Tab('بيع', Icons.point_of_sale, () => SellPage()),
          if (store.showStock) _Tab('المخزون', Icons.inventory_2, () => StockPage()),
          if (store.showDebt) _Tab('الديون', Icons.account_balance_wallet, () => DebtPage()),
          if (store.showRent) _Tab('الإيجار', Icons.construction, () => RentPage()),
          _Tab('التقارير', Icons.bar_chart, () => ReportPage()),
        ];
        if (tab >= tabs.length) tab = 0;
        final qs = <Widget>[
          if (store.qDebt) _qtile(Icons.person_add_alt_1, 'دين جديد', opNew(), () => newDebt(context)),
          if (store.qRent) _qtile(Icons.add_business, 'إيجار جديد', opNew(), () => newRental(context)),
          if (store.qStock) _qtile(Icons.add_box, 'إضافة صنف', const Color(0xFF2F9E44), () => editProduct(context)),
        ];
        return Scaffold(
          appBar: AppBar(
            title: Text(store.shop, style: _bold),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [shadeHex(kAccHex[store.acc], .5), shadeHex(kAccHex[store.acc], .86)]))),
            actions: [
              IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
            ],
          ),
          body: Column(children: [
            if (store.driveDue && !_bannerHidden)
              Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Panel(
                      margin: EdgeInsets.zero,
                      stripe: Colors.orange,
                      child: Row(children: [
                        const Icon(Icons.cloud_upload, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('حان وقت النسخ الاحتياطي على Drive', style: _bold)),
                        TextButton(onPressed: () => backupToDrive(context), child: const Text('نسخ الآن')),
                        IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _bannerHidden = true)),
                      ]))),
            if (store.showQuick && qs.isNotEmpty)
              Padding(padding: const EdgeInsets.fromLTRB(8, 10, 8, 0), child: Row(children: qs)),
            Expanded(child: tabs[tab].page()),
          ]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: [for (final t in tabs) NavigationDestination(icon: Icon(t.icon), label: t.label)],
          ),
        );
      });
}

// ---------------------------------------------------------------- sell
class SellPage extends StatefulWidget {
  const SellPage({super.key});
  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  String cat = 'الكل', q = '';
  @override
  Widget build(BuildContext context) {
    final l = filtered(cat, q);
    return Column(children: [
      Padding(
          padding: const EdgeInsets.all(12),
          child: Filters(cat, (v) => setState(() => cat = v), (v) => setState(() => q = v))),
      Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
        for (final p in l)
          Panel(
              onTap: () {
                final e = store.addToCart(p);
                if (e != null) toast(context, e);
              },
              child: itemRow(
                  lead: prodAvatar(p),
                  title: p.name,
                  sub: qtyText(p),
                  trail: Text(fm(p.price), style: _bold))),
      ])),
      if (store.cart.isNotEmpty)
        SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: () => openCart(context),
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: Text('الفاتورة (${store.cart.length}) · ${fm(store.net)}', style: _bold))))),
    ]);
  }
}

void openCart(BuildContext context) {
  final discC = TextEditingController(text: store.disc == 0 ? '' : store.disc.round().toString());
  final custC = TextEditingController(text: store.cust);
  final paidC = TextEditingController(text: store.paid == 0 ? '' : store.paid.round().toString());
  var closed = false;
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Live((_) {
            if (store.cart.isEmpty) {
              if (!closed) {
                closed = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (ctx.mounted) Navigator.pop(ctx);
                });
              }
              return const SizedBox(height: 60);
            }
            final sugg = custC.text.trim().isEmpty
                ? <String>[]
                : store.debts.keys.where((n) => n.contains(custC.text.trim()) && n != custC.text.trim()).take(5).toList();
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final c in List.of(store.cart))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.p.name),
                    subtitle: Text('${fm(c.p.price)} × ${c.qty} = ${fm(c.p.price * c.qty)}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => store.change(c, -1)),
                      Text('${c.qty}', style: _bold),
                      IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            final e = store.change(c, 1);
                            if (e != null) toast(context, e);
                          }),
                    ]),
                  ),
                tf(discC, 'خصم (${store.cur})', isNum: true, onChanged: (v) {
                  store.disc = double.tryParse(v) ?? 0;
                  store.touch();
                }),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('نقدي')),
                    ButtonSegment(value: true, label: Text('آجل (دين)')),
                  ],
                  selected: {store.credit},
                  onSelectionChanged: (s) {
                    store.credit = s.first;
                    store.touch();
                  },
                ),
                const SizedBox(height: 10),
                tf(custC, store.credit ? 'اسم العميل' : 'اسم العميل (اختياري)', onChanged: (v) {
                  store.cust = v;
                  store.touch();
                }),
                if (sugg.isNotEmpty)
                  Wrap(spacing: 6, children: [
                    for (final n in sugg)
                      ActionChip(
                          label: Text(n),
                          onPressed: () {
                            custC.text = n;
                            store.cust = n;
                            store.touch();
                          })
                  ]),
                if (store.credit)
                  tf(paidC, 'المبلغ المدفوع الآن', isNum: true, onChanged: (v) {
                    store.paid = double.tryParse(v) ?? 0;
                    store.touch();
                  }),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('الإجمالي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      Text(fm(store.net), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    ])),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: () {
                          final e = store.checkout();
                          if (e != null) {
                            toast(context, e);
                            return;
                          }
                          closed = true;
                          Navigator.pop(ctx);
                          if (store.autoInvoice) showInvoice(context, store.lastSale!);
                        },
                        child: const Text('إتمام البيع', style: _bold))),
              ])),
            );
          }));
}

// ---------------------------------------------------------------- stock
class StockPage extends StatefulWidget {
  const StockPage({super.key});
  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  String cat = 'الكل', q = '';
  @override
  Widget build(BuildContext context) {
    final l = filtered(cat, q);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => editProduct(context),
          icon: const Icon(Icons.add),
          label: const Text('صنف جديد')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(12),
            child: Filters(cat, (v) => setState(() => cat = v), (v) => setState(() => q = v))),
        Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 80), children: [
          for (final p in l)
            Panel(
                onTap: () => editProduct(context, p),
                child: itemRow(
                    lead: prodAvatar(p),
                    title: p.name,
                    sub: Row(children: [subText('${p.cat} · '), qtyText(p)]),
                    trail: Text(fm(p.price), style: _bold))),
        ])),
      ]),
    );
  }
}

Future<void> editProduct(BuildContext c, [Product? p]) async {
  final n = TextEditingController(text: p?.name ?? '');
  final pr = TextEditingController(text: p == null ? '' : p.price.round().toString());
  final k = TextEditingController(text: p == null ? '' : p.cost.round().toString());
  final q = TextEditingController(text: p == null ? '' : '${p.qty}');
  String cat = p?.cat ?? kCats[0];
  String img = p?.img ?? '';
  await showDialog(
      context: c,
      builder: (_) => StatefulBuilder(
          builder: (ctx, set) => AlertDialog(
                title: Text(p == null ? 'صنف جديد' : 'تعديل صنف'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  tf(n, 'الاسم'),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DropdownButtonFormField<String>(
                          value: cat,
                          decoration: const InputDecoration(labelText: 'القسم', border: OutlineInputBorder()),
                          items: kCats.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => set(() => cat = v!))),
                  tf(pr, 'سعر البيع', isNum: true),
                  tf(k, 'سعر الشراء (لحساب الربح)', isNum: true),
                  tf(q, 'الكمية', isNum: true),
                  PhotoField(label: 'صورة المنتج', initial: img, onChanged: (v) => img = v),
                ])),
                actions: [
                  if (p != null)
                    TextButton(
                        onPressed: () async {
                          if (await confirmDlg(ctx, 'حذف هذا الصنف؟')) {
                            store.prods.remove(p);
                            store.save();
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                        child: const Text('حذف', style: TextStyle(color: Colors.red))),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                  FilledButton(
                      onPressed: () {
                        final price = double.tryParse(pr.text), qty = int.tryParse(q.text);
                        if (n.text.trim().isEmpty || price == null || qty == null) {
                          toast(ctx, 'أكمل البيانات');
                          return;
                        }
                        final x = p ?? Product(id: nowMs(), name: '', cat: cat, price: 0, qty: 0);
                        x.name = n.text.trim();
                        x.cat = cat;
                        x.price = price;
                        x.cost = double.tryParse(k.text) ?? 0;
                        x.qty = qty;
                        x.img = img;
                        if (p == null) store.prods.add(x);
                        store.save();
                        Navigator.pop(ctx);
                      },
                      child: const Text('حفظ')),
                ],
              )));
}

// ---------------------------------------------------------------- debts
class DebtPage extends StatelessWidget {
  const DebtPage({super.key});
  @override
  Widget build(BuildContext context) {
    final ns = store.debts.keys.where((n) => store.bal(n) > 0).toList()
      ..sort((a, b) => store.bal(b).compareTo(store.bal(a)));
    final sum = ns.fold(0.0, (a, n) => a + store.bal(n));
    return ListView(padding: const EdgeInsets.all(12), children: [
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(rad()),
              gradient: LinearGradient(colors: [shadeHex(kOpHex[store.newCol], .6), opNew()])),
          child: Row(children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 34),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('إجمالي الديون المستحقة', style: TextStyle(color: Colors.white70)),
              Text(fm(sum), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            ])),
            Text('${ns.length}\nمدين',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ])),
      const SizedBox(height: 12),
      FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: opNew(), foregroundColor: Colors.white),
          onPressed: () => newDebt(context),
          icon: const Icon(Icons.add),
          label: const Text('تسجيل دين جديد')),
      secTitle('المدينون'),
      if (ns.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد ديون مستحقة'))),
      for (final n in ns)
        Panel(
            stripe: opNew(),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DebtDetail(n))),
            child: itemRow(
                lead: store.imgOf(n).isEmpty
                    ? CircleAvatar(backgroundColor: opNew().withAlpha(40), child: Icon(Icons.person, color: opNew()))
                    : thumb(store.imgOf(n)),
                title: n,
                sub: subText(store.phoneOf(n).isEmpty ? 'آخر حركة: ${fd(store.debts[n]!.last.d)}' : store.phoneOf(n)),
                trail: Text(fm(store.bal(n)), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)))),
    ]);
  }
}

Future<void> newDebt(BuildContext c) async {
  final n = TextEditingController(), a = TextEditingController();
  final nt = TextEditingController(), ph = TextEditingController();
  String img = '';
  await showDialog(
      context: c,
      builder: (ctx) => AlertDialog(
            title: const Text('تسجيل دين جديد'),
            content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              tf(n, 'اسم العميل', onChanged: (v) {
                final p = store.phoneOf(v.trim());
                if (p.isNotEmpty && ph.text.isEmpty) ph.text = p;
              }),
              tf(a, 'المبلغ', isNum: true),
              tf(nt, 'ملاحظة'),
              tf(ph, 'رقم الهاتف', tel: true),
              PhotoField(label: 'صورة الهوية / البطاقة', initial: '', onChanged: (v) => img = v),
            ])),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: opNew(), foregroundColor: Colors.white),
                  onPressed: () {
                    final name = n.text.trim(), amt = double.tryParse(a.text) ?? 0;
                    if (name.isEmpty || amt <= 0) {
                      toast(ctx, 'أكمل البيانات');
                      return;
                    }
                    store.addL(name, 'debt', amt, nt.text.trim());
                    store.setInfo(name, ph.text.trim(), img);
                    store.save();
                    Navigator.pop(ctx);
                  },
                  child: const Text('تسجيل الدين')),
            ],
          ));
}

Future<void> editCust(BuildContext c, String name) async {
  final ph = TextEditingController(text: store.phoneOf(name));
  String img = store.imgOf(name);
  await showDialog(
      context: c,
      builder: (ctx) => AlertDialog(
            title: Text(name),
            content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              tf(ph, 'رقم الهاتف', tel: true),
              PhotoField(label: 'صورة الهوية / البطاقة', initial: img, onChanged: (v) => img = v),
            ])),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              FilledButton(
                  onPressed: () {
                    final m = store.cinfo.putIfAbsent(name, () => <String, String>{});
                    m['phone'] = ph.text.trim();
                    if (img.isEmpty) {
                      m.remove('img');
                    } else {
                      m['img'] = img;
                    }
                    store.save();
                    Navigator.pop(ctx);
                  },
                  child: const Text('حفظ')),
            ],
          ));
}

class DebtDetail extends StatefulWidget {
  final String name;
  const DebtDetail(this.name, {super.key});
  @override
  State<DebtDetail> createState() => _DebtDetailState();
}

class _DebtDetailState extends State<DebtDetail> {
  final a = TextEditingController(), nt = TextEditingController();

  void act(String t) {
    final amt = double.tryParse(a.text) ?? 0;
    if (amt <= 0) {
      toast(context, 'اكتب المبلغ');
      return;
    }
    store.addL(widget.name, t, amt, nt.text.trim());
    store.save();
    a.clear();
    nt.clear();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.name;
    return Scaffold(
      appBar: AppBar(title: Text(n)),
      body: Live((_) {
        final ph = store.phoneOf(n), img = store.imgOf(n);
        final l = (store.debts[n] ?? <LEntry>[]).reversed.toList();
        final bal = store.bal(n);
        return ListView(padding: const EdgeInsets.all(12), children: [
          Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.phone, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(ph.isEmpty ? 'لا يوجد رقم هاتف' : ph, style: _bold)),
              if (ph.isNotEmpty) IconButton(icon: const Icon(Icons.call), onPressed: () => callPhone(ph)),
            ]),
            if (img.isNotEmpty) imgView(context, img),
            TextButton.icon(
                onPressed: () => editCust(context, n),
                icon: const Icon(Icons.edit),
                label: const Text('تعديل الهاتف والصورة')),
          ])),
          Panel(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('المتبقي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(fm(bal),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: bal > 0 ? Colors.orange.shade800 : Colors.green)),
          ])),
          tf(a, 'المبلغ', isNum: true),
          tf(nt, 'ملاحظة'),
          Row(children: [
            Expanded(
                child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: opRecv(), foregroundColor: Colors.white),
                    onPressed: () => act('pay'),
                    icon: const Icon(Icons.call_received),
                    label: const Text('استلام دفعة'))),
            const SizedBox(width: 8),
            Expanded(
                child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: opNew(), foregroundColor: Colors.white),
                    onPressed: () => act('debt'),
                    icon: const Icon(Icons.add),
                    label: const Text('دين جديد'))),
          ]),
          secTitle('مشاركة كشف الحساب مع العميل'),
          shareRow(context, () => debtDoc(n)),
          secTitle('الحركات'),
          for (final e in l)
            Panel(
                stripe: e.t == 'debt' ? opNew() : opRecv(),
                child: itemRow(
                    lead: Icon(e.t == 'debt' ? Icons.north_east : Icons.south_west,
                        color: e.t == 'debt' ? opNew() : opRecv()),
                    title: '${e.t == 'debt' ? 'دين جديد' : 'استلام دفعة'}${e.note.isEmpty ? '' : ' · ${e.note}'}',
                    sub: subText(fd(e.d)),
                    trail: Text('${e.t == 'debt' ? '+' : '−'}${fm(e.amt)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, color: e.t == 'debt' ? opNew() : opRecv())))),
        ]);
      }),
    );
  }
}

// ---------------------------------------------------------------- rentals
class RentPage extends StatefulWidget {
  const RentPage({super.key});
  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final act = store.rentals.where((x) => x.ret == null).toList();
    final nq = norm(q);
    final all = store.rentals.where((x) => x.ret != null).toList().reversed.toList();
    final hist = all.where((x) {
      final ph = x.phone.isNotEmpty ? x.phone : store.phoneOf(x.cust);
      return nq.isEmpty || x.cust.toLowerCase().contains(nq) || ph.contains(nq);
    }).take(50).toList();
    return ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [
        Expanded(
            child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: opNew(), foregroundColor: Colors.white),
                onPressed: () => newRental(context),
                icon: const Icon(Icons.add),
                label: const Text('إيجار جديد'))),
        const SizedBox(width: 8),
        Expanded(
            child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipPage())),
                icon: const Icon(Icons.build),
                label: const Text('إدارة المعدات'))),
      ]),
      secTitle('قيد الإيجار (${act.length})'),
      if (act.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد معدات مؤجّرة حاليًا'))),
      for (final x in act)
        Panel(
            stripe: opNew(),
            onTap: () => returnDialog(context, x),
            child: itemRow(
                title: '${x.name} × ${x.qty}',
                sub: subText('${x.cust}${x.phone.isEmpty ? '' : ' · ${x.phone}'} · منذ ${fd(x.start)} · ${x.daysNow()} يوم'),
                trail: Text(fm(x.daysNow() * x.rate * x.qty),
                    style: TextStyle(fontWeight: FontWeight.w800, color: opNew())))),
      secTitle('المعدات المتاحة'),
      for (final r in store.ritems)
        Panel(
            child: itemRow(
                title: r.name,
                sub: subText('${fm(r.rate)} / يوم'),
                trail: Text('متاح ${store.avail(r)} من ${r.qty}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: store.avail(r) > 0 ? Colors.green.shade700 : Colors.red)))),
      secTitle('سجل الإيجارات المنتهية'),
      TextField(
          onChanged: (v) => setState(() => q = v),
          decoration: InputDecoration(
              hintText: 'ابحث باسم العميل أو رقم الهاتف',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(rad())))),
      const SizedBox(height: 8),
      if (hist.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(all.isEmpty ? 'لا يوجد سجل بعد' : 'لا توجد نتائج'))),
      for (final x in hist)
        Panel(
            stripe: opRecv(),
            onTap: () => histDialog(context, x),
            child: itemRow(
                lead: Icon(Icons.south_west, color: opRecv()),
                title: '${x.cust} · ${x.name} × ${x.qty}',
                sub: subText('${fd(x.start)} ← ${fd(x.ret!)}${x.phone.isEmpty ? '' : ' · ${x.phone}'}'),
                trail: Text(fm(x.total > 0 ? x.total : x.daysNow() * x.rate * x.qty),
                    style: TextStyle(fontWeight: FontWeight.w800, color: opRecv())))),
    ]);
  }
}

Future<void> newRental(BuildContext c) async {
  if (store.ritems.isEmpty) {
    toast(c, 'أضف معدات الإيجار أولًا');
    return;
  }
  RItem it = store.ritems.first;
  final q = TextEditingController(text: '1'), cu = TextEditingController();
  final ph = TextEditingController(), nt = TextEditingController();
  String img = '';
  await showDialog(
      context: c,
      builder: (_) => StatefulBuilder(
          builder: (ctx, set) => AlertDialog(
                title: const Text('إيجار جديد'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<int>(
                      value: it.id,
                      decoration: const InputDecoration(labelText: 'المعدة', border: OutlineInputBorder()),
                      items: store.ritems
                          .map((r) => DropdownMenuItem(value: r.id, child: Text('${r.name} (متاح ${store.avail(r)})')))
                          .toList(),
                      onChanged: (v) => set(() => it = store.ritems.firstWhere((r) => r.id == v))),
                  const SizedBox(height: 10),
                  tf(q, 'العدد', isNum: true),
                  tf(cu, 'اسم المستأجر', onChanged: (v) {
                    final p = store.phoneOf(v.trim());
                    if (p.isNotEmpty && ph.text.isEmpty) ph.text = p;
                  }),
                  tf(ph, 'رقم هاتف المستأجر', tel: true),
                  tf(nt, 'ملاحظات', lines: 2),
                  PhotoField(label: 'صورة الهوية / البطاقة', initial: '', onChanged: (v) => img = v),
                ])),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                  FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: opNew(), foregroundColor: Colors.white),
                      onPressed: () {
                        final e = store.addRental(
                            it, int.tryParse(q.text) ?? 0, cu.text.trim(), ph.text.trim(), nt.text.trim(), img);
                        if (e != null) {
                          toast(ctx, e);
                          return;
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('تأكيد الإيجار')),
                ],
              )));
}

void returnDialog(BuildContext c, Rental r) {
  final t = r.daysNow() * r.rate * r.qty;
  final img = store.imgOf(r.cust);
  showDialog(
      context: c,
      builder: (ctx) => AlertDialog(
            title: const Text('استلام معدات'),
            content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${r.name} × ${r.qty}', style: _bold),
              Text('${r.cust} · ${r.daysNow()} يوم × ${fm(r.rate)}'),
              if (r.phone.isNotEmpty) Text('الهاتف: ${r.phone}'),
              if (r.note.isNotEmpty) Text('ملاحظات: ${r.note}'),
              if (img.isNotEmpty) imgView(ctx, img),
              const Divider(),
              Text('المستحق: ${fm(t)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text('مشاركة كشف مبدئي مع المستأجر:'),
              const SizedBox(height: 6),
              shareRow(ctx, () => rentalDoc([r], r.cust)),
            ])),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
              OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: opRecv(), side: BorderSide(color: opRecv())),
                  onPressed: () {
                    final s = store.returnRental(r, false);
                    Navigator.pop(ctx);
                    showInvoice(c, s);
                  },
                  child: const Text('استلام على الحساب')),
              FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: opRecv(), foregroundColor: Colors.white),
                  onPressed: () {
                    final s = store.returnRental(r, true);
                    Navigator.pop(ctx);
                    showInvoice(c, s);
                  },
                  child: const Text('استلام وتحصيل نقدًا')),
            ],
          ));
}

void histDialog(BuildContext c, Rental x) {
  final ph = x.phone.isNotEmpty ? x.phone : store.phoneOf(x.cust);
  final img = store.imgOf(x.cust);
  showDialog(
      context: c,
      builder: (ctx) => AlertDialog(
            title: Text(x.cust),
            content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(ph.isEmpty ? 'لا يوجد رقم هاتف' : ph, style: _bold)),
                if (ph.isNotEmpty) IconButton(icon: const Icon(Icons.call), onPressed: () => callPhone(ph)),
              ]),
              if (x.note.isNotEmpty) Text('ملاحظات: ${x.note}'),
              if (img.isNotEmpty) imgView(ctx, img),
              const Divider(),
              Text('${x.name} × ${x.qty}', style: _bold),
              Text('الاستلام: ${fd(x.start)}'),
              Text('الإرجاع: ${fd(x.ret!)} (${x.days > 0 ? x.days : x.daysNow()} يوم × ${fm(x.rate)})'),
              Text('الدفع: ${x.cash == null ? '—' : x.cash! ? 'نقدًا' : 'على الحساب (دين)'}'),
              const Divider(),
              Text('المبلغ: ${fm(x.total > 0 ? x.total : x.daysNow() * x.rate * x.qty)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text('مشاركة هذا الإيجار:'),
              const SizedBox(height: 6),
              shareRow(ctx, () => rentalDoc([x], x.cust)),
              const SizedBox(height: 10),
              const Text('مشاركة كل إيجارات العميل:'),
              const SizedBox(height: 6),
              shareRow(ctx, () => rentalDoc(store.rentals.where((r) => r.cust == x.cust).toList(), x.cust)),
            ])),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
          ));
}

class EquipPage extends StatelessWidget {
  const EquipPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('معدات الإيجار')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => editEquip(context), icon: const Icon(Icons.add), label: const Text('إضافة معدة')),
        body: Live((_) => ListView(padding: const EdgeInsets.all(12), children: [
              for (final r in store.ritems)
                Panel(
                    onTap: () => editEquip(context, r),
                    child: itemRow(
                        title: r.name,
                        sub: subText('${fm(r.rate)} / يوم'),
                        trail: Text('العدد: ${r.qty}', style: _bold))),
            ])),
      );
}

Future<void> editEquip(BuildContext c, [RItem? r]) async {
  final n = TextEditingController(text: r?.name ?? '');
  final rt = TextEditingController(text: r == null ? '' : r.rate.round().toString());
  final q = TextEditingController(text: r == null ? '' : '${r.qty}');
  await showDialog(
      context: c,
      builder: (ctx) => AlertDialog(
            title: Text(r == null ? 'معدة جديدة' : 'تعديل معدة'),
            content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              tf(n, 'الاسم'),
              tf(rt, 'الأجرة اليومية', isNum: true),
              tf(q, 'العدد الكلي', isNum: true),
            ])),
            actions: [
              if (r != null)
                TextButton(
                    onPressed: () async {
                      if (await confirmDlg(ctx, 'حذف المعدة؟')) {
                        store.ritems.remove(r);
                        store.save();
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text('حذف', style: TextStyle(color: Colors.red))),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              FilledButton(
                  onPressed: () {
                    final rate = double.tryParse(rt.text), qty = int.tryParse(q.text);
                    if (n.text.trim().isEmpty || rate == null || qty == null || qty <= 0) {
                      toast(ctx, 'أكمل البيانات');
                      return;
                    }
                    if (r == null) {
                      store.ritems.add(RItem(id: nowMs(), name: n.text.trim(), rate: rate, qty: qty));
                    } else {
                      r.name = n.text.trim();
                      r.rate = rate;
                      r.qty = qty;
                    }
                    store.save();
                    Navigator.pop(ctx);
                  },
                  child: const Text('حفظ')),
            ],
          ));
}

// ---------------------------------------------------------------- reports
class ReportPage extends StatelessWidget {
  const ReportPage({super.key});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    bool sameDay(int ms, DateTime d) {
      final x = DateTime.fromMillisecondsSinceEpoch(ms);
      return x.year == d.year && x.month == d.month && x.day == d.day;
    }

    bool isMonth(int ms) {
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return d.year == now.year && d.month == now.month;
    }

    double sum(Iterable<Sale> l) => l.fold(0.0, (a, s) => a + s.total);
    final ts = store.sales.where((s) => sameDay(s.date, now)).toList();
    final mo = store.sales.where((s) => isMonth(s.date));
    final profit = store.sales.fold(0.0, (a, s) {
      final g = s.items.fold(
          0.0, (b, i) => b + ((i['price'] ?? 0) - (i['cost'] ?? 0)).toDouble() * (i['qty'] ?? 0).toDouble());
      return a + g - s.disc;
    });
    final dsum = store.debts.keys.fold(0.0, (a, n) => a + (store.bal(n) > 0 ? store.bal(n) : 0));
    final low = store.prods.where((p) => p.qty <= store.low).length;
    final recent = store.sales.reversed.take(30).toList();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    final vals = days.map((d) => sum(store.sales.where((s) => sameDay(s.date, d)))).toList();
    final mx = vals.fold<double>(1, (a, b) => b > a ? b : a);
    final acc = Color(kAccHex[store.acc]);
    return ListView(padding: const EdgeInsets.all(8), children: [
      Row(children: [
        bigStat(Icons.today, acc, 'مبيعات اليوم', fm(sum(ts))),
        bigStat(Icons.receipt_long, Colors.indigo, 'فواتير اليوم', '${ts.length}'),
      ]),
      Row(children: [
        bigStat(Icons.calendar_month, Colors.teal, 'مبيعات الشهر', fm(sum(mo))),
        bigStat(Icons.trending_up, Colors.green, 'إجمالي الأرباح', fm(profit)),
      ]),
      Row(children: [
        bigStat(Icons.account_balance_wallet, opNew(), 'الديون المستحقة', fm(dsum)),
        bigStat(Icons.warning_amber, low > 0 ? Colors.orange : Colors.grey, 'أصناف منخفضة', '$low'),
      ]),
      Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
          child: Panel(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('مبيعات آخر 7 أيام', style: _bold),
                const SizedBox(height: 10),
                SizedBox(
                    height: 130,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Container(
                              height: 4 + 90 * vals[i] / mx,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                  color: i == 6 ? acc : acc.withAlpha(110), borderRadius: BorderRadius.circular(6))),
                          const SizedBox(height: 4),
                          Text(DateFormat('d/M').format(days[i]), style: const TextStyle(fontSize: 10)),
                        ])),
                    ])),
              ]))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: secTitle('آخر الفواتير')),
      if (recent.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد فواتير بعد'))),
      for (final s in recent)
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Panel(
                stripe: s.kind == 'rent' ? opRecv() : acc,
                onTap: () => showInvoice(context, s),
                child: itemRow(
                    title: '${s.kind == 'rent' ? 'إيجار' : 'فاتورة'} ${s.no}${s.cust.isEmpty ? '' : ' · ${s.cust}'}',
                    sub: subText(fd(s.date) + (s.total > s.paid ? ' · آجل' : '')),
                    trail: Text(fm(s.total), style: _bold)))),
    ]);
  }
}

// ---------------------------------------------------------------- settings
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final shopC = TextEditingController(text: store.shop);
  final phoneC = TextEditingController(text: store.shopPhone);
  final addrC = TextEditingController(text: store.shopAddr);
  final footC = TextEditingController(text: store.footer);
  final curC = TextEditingController(text: store.cur);
  final lowC = TextEditingController(text: '${store.low}');
  final daysC = TextEditingController(text: '${store.minDays}');

  Widget sec(String t, IconData i, List<Widget> kids) => Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(i, size: 20), const SizedBox(width: 8), Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
        const Divider(),
        ...kids,
      ]));

  Widget swatches(List<int> hex, int sel, ValueChanged<int> on) => Wrap(spacing: 10, runSpacing: 10, children: [
        for (var i = 0; i < hex.length; i++)
          GestureDetector(
              onTap: () => on(i),
              child: CircleAvatar(
                  backgroundColor: Color(hex[i]),
                  radius: 18,
                  child: sel == i ? const Icon(Icons.check, color: Colors.white) : null)),
      ]);

  Widget choice<T>(Map<T, String> m, T cur, ValueChanged<T> on) => Wrap(spacing: 6, runSpacing: 4, children: [
        for (final e in m.entries)
          ChoiceChip(label: Text(e.value), selected: cur == e.key, onSelected: (_) => on(e.key)),
      ]);

  Widget sw(String t, bool v, ValueChanged<bool> on, {String? sub}) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(t),
      subtitle: sub == null ? null : Text(sub, style: const TextStyle(fontSize: 12)),
      value: v,
      onChanged: on);

  Widget lbl(String t) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)));

  String ago(int ms) {
    if (ms == 0) return 'لم تتم بعد';
    final d = ((nowMs() - ms) / 86400000).floor();
    return d <= 0 ? 'اليوم' : 'منذ $d يوم';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Live((_) => ListView(padding: const EdgeInsets.all(12), children: [
            sec('بيانات المحل', Icons.store, [
              const SizedBox(height: 8),
              tf(shopC, 'اسم المحل', onChanged: (v) => store.upd(() => store.shop = v)),
              tf(phoneC, 'رقم هاتف المحل', tel: true, onChanged: (v) => store.upd(() => store.shopPhone = v)),
              tf(addrC, 'العنوان', onChanged: (v) => store.upd(() => store.shopAddr = v)),
              tf(footC, 'عبارة أسفل الفواتير والملفات', onChanged: (v) => store.upd(() => store.footer = v)),
              tf(curC, 'اسم العملة', onChanged: (v) => store.upd(() => store.cur = v)),
              const Text('تظهر هذه البيانات في الفواتير وملفات PDF وExcel التي تشاركها.', style: TextStyle(fontSize: 12)),
            ]),
            sec('المظهر', Icons.palette, [
              lbl('لون التطبيق'),
              swatches(kAccHex, store.acc, (i) => store.upd(() => store.acc = i)),
              lbl('النمط'),
              choice<String>({'auto': 'تلقائي', 'light': 'فاتح', 'dark': 'داكن'}, store.theme,
                  (v) => store.upd(() => store.theme = v)),
              lbl('حجم الخط'),
              choice<int>({14: 'صغير', 16: 'متوسط', 18: 'كبير', 20: 'أكبر', 22: 'ضخم'}, store.fs.round(),
                  (v) => store.upd(() => store.fs = v.toDouble())),
              lbl('شكل الزوايا'),
              choice<int>({0: 'حادة', 1: 'متوسطة', 2: 'دائرية'}, store.rad, (v) => store.upd(() => store.rad = v)),
            ]),
            sec('ألوان العمليات', Icons.color_lens, [
              lbl('لون العملية الجديدة (دين جديد / إيجار جديد)'),
              swatches(kOpHex, store.newCol, (i) => store.upd(() => store.newCol = i)),
              lbl('لون الاستلام (استلام دفعة / استلام معدات)'),
              swatches(kOpHex, store.recvCol, (i) => store.upd(() => store.recvCol = i)),
            ]),
            sec('الأقسام والاختصارات', Icons.dashboard_customize, [
              sw('إظهار قسم المخزون', store.showStock, (v) => store.upd(() => store.showStock = v)),
              sw('إظهار قسم الديون', store.showDebt, (v) => store.upd(() => store.showDebt = v)),
              sw('إظهار قسم الإيجار', store.showRent, (v) => store.upd(() => store.showRent = v)),
              const Divider(),
              sw('شريط الاختصارات أعلى الشاشة', store.showQuick, (v) => store.upd(() => store.showQuick = v)),
              sw('اختصار: تسجيل دين', store.qDebt, (v) => store.upd(() => store.qDebt = v)),
              sw('اختصار: إيجار جديد', store.qRent, (v) => store.upd(() => store.qRent = v)),
              sw('اختصار: إضافة صنف', store.qStock, (v) => store.upd(() => store.qStock = v)),
              sw('اختصار: بيع جديد (للقائمة فقط)', store.qSell, (v) => store.upd(() => store.qSell = v),
                  sub: 'الاختصارات المفعّلة تظهر أيضًا عند الضغط المطوّل على أيقونة التطبيق في الشاشة الرئيسية.'),
            ]),
            sec('المبيعات والمخزون', Icons.point_of_sale, [
              sw('البيع الآجل (دين) هو الخيار الافتراضي', store.defCredit, (v) => store.upd(() {
                    store.defCredit = v;
                    store.credit = v;
                  })),
              sw('عرض الفاتورة بعد كل عملية بيع', store.autoInvoice, (v) => store.upd(() => store.autoInvoice = v)),
              tf(lowC, 'حد التنبيه للكمية المنخفضة', isNum: true, onChanged: (v) => store.upd(() => store.low = int.tryParse(v) ?? 0)),
            ]),
            sec('الإيجار', Icons.construction, [
              const SizedBox(height: 8),
              tf(daysC, 'أقل عدد أيام يُحسب للإيجار', isNum: true,
                  onChanged: (v) => store.upd(() => store.minDays = (int.tryParse(v) ?? 1).clamp(0, 30).toInt())),
            ]),
            sec('النسخ الاحتياطي', Icons.cloud_upload, [
              lbl('نمط النسخ الاحتياطي'),
              choice<String>({'manual': 'يدوي فقط', 'remind': 'تذكير بالنسخ على Drive', 'auto': 'تلقائي محلي + تذكير'},
                  store.bkMode, (v) => store.upd(() => store.bkMode = v)),
              if (store.bkMode != 'manual') ...[
                lbl('كل كم يوم'),
                choice<int>({1: 'يوميًا', 3: 'كل 3 أيام', 7: 'أسبوعيًا', 30: 'شهريًا'}, store.bkEvery,
                    (v) => store.upd(() => store.bkEvery = v)),
              ],
              if (store.bkMode == 'auto') ...[
                lbl('عدد النسخ المحلية المحفوظة'),
                choice<int>({3: '3', 7: '7', 14: '14'}, store.bkKeep, (v) => store.upd(() => store.bkKeep = v)),
              ],
              const SizedBox(height: 10),
              Text('آخر نسخة على Drive: ${ago(store.lastDrive)}', style: const TextStyle(fontSize: 12)),
              if (store.bkMode == 'auto') Text('آخر نسخة محلية: ${ago(store.lastBk)}', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 10),
              FilledButton.icon(
                  onPressed: () => backupToDrive(context),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('حفظ على Google Drive الآن')),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  onPressed: () => restoreFromFile(context),
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('استعادة من ملف (Drive أو الجهاز)')),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupsPage())),
                  icon: const Icon(Icons.folder_copy),
                  label: const Text('النسخ المحلية على الجهاز')),
              const SizedBox(height: 8),
              const Text(
                  'الحفظ على Drive يتم عبر قائمة المشاركة: اختر Drive. النسخ المحلية التلقائية تحميك من تلف البيانات، '
                  'لكنها تُحذف عند حذف التطبيق، لذلك احفظ نسخة على Drive قبل أي تحديث.',
                  style: TextStyle(fontSize: 12)),
            ]),
            Panel(
                child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (await confirmDlg(context, 'سيتم حذف كل البيانات نهائيًا. متابعة؟')) store.wipe();
                    },
                    child: const Text('مسح كل البيانات'))),
          ])),
    );
  }
}

class BackupsPage extends StatefulWidget {
  const BackupsPage({super.key});
  @override
  State<BackupsPage> createState() => _BackupsPageState();
}

class _BackupsPageState extends State<BackupsPage> {
  List<File> files = [];

  Future<void> load() async {
    final l = await store.backups();
    if (mounted) setState(() => files = l);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('النسخ المحلية')),
        body: ListView(padding: const EdgeInsets.all(12), children: [
          FilledButton.icon(
              onPressed: () async {
                await store.localBackup();
                await load();
              },
              icon: const Icon(Icons.add),
              label: const Text('إنشاء نسخة محلية الآن')),
          const SizedBox(height: 10),
          if (files.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد نسخ محلية'))),
          for (final f in files)
            Panel(
                child: itemRow(
                    title: f.path.split('/').last,
                    sub: subText('${fd(f.lastModifiedSync().millisecondsSinceEpoch)} · ${(f.lengthSync() / 1024).round()} ك.ب'),
                    trail: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                          icon: const Icon(Icons.restore),
                          onPressed: () async {
                            if (!await confirmDlg(context, 'استعادة هذه النسخة؟ ستُستبدل البيانات الحالية.')) return;
                            try {
                              store.importJson(await f.readAsString());
                              if (context.mounted) toast(context, 'تمت الاستعادة');
                            } catch (_) {
                              if (context.mounted) toast(context, 'الملف غير صالح');
                            }
                          }),
                      IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => Share.shareXFiles([XFile(f.path)])),
                      IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await f.delete();
                            await load();
                          }),
                    ]))),
        ]),
      );
}
