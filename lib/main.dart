import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'store.dart';

const kInk = Color(0xFF1F2A30);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.init();
  runApp(const ShopApp());
}

ThemeData _theme(Brightness b) {
  final acc = Color(kAccHex[store.acc]);
  final onAcc = acc.computeLuminance() > 0.5 ? kInk : Colors.white;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: acc, brightness: b)
        .copyWith(primary: acc, onPrimary: onAcc),
    appBarTheme: const AppBarTheme(backgroundColor: kInk, foregroundColor: Colors.white),
    navigationBarTheme: NavigationBarThemeData(indicatorColor: acc),
  );
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (_, __) => MaterialApp(
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
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
            controller: c,
            onChanged: onChanged,
            maxLines: lines,
            keyboardType: tel
                ? TextInputType.phone
                : isNum
                    ? TextInputType.number
                    : TextInputType.text,
            decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())));

const _bold = TextStyle(fontWeight: FontWeight.w800);

Widget thumb(String img) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 4),
    child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(imgBytes(img), width: 46, height: 46, fit: BoxFit.cover, gaplessPlayback: true)));

void viewImg(BuildContext c, String img) => showDialog(
    context: c,
    builder: (ctx) => Dialog(
        child: InteractiveViewer(child: Image.memory(imgBytes(img), fit: BoxFit.contain))));

Widget imgView(BuildContext c, String img) => GestureDetector(
    onTap: () => viewImg(c, img),
    child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
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

void showInvoice(BuildContext c, Sale s) => showDialog(
    context: c,
    builder: (ctx) => AlertDialog(
          content: SingleChildScrollView(child: SelectableText(s.text(store.shop))),
          actions: [
            TextButton(onPressed: () => Share.share(s.text(store.shop)), child: const Text('مشاركة')),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ],
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
            decoration: const InputDecoration(
                hintText: 'ابحث عن صنف',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder())),
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

Widget stat(String t, String v, {Color? c}) => Expanded(
    child: Card(
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: const TextStyle(fontSize: 12)),
              Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c)),
            ]))));

// ---------------------------------------------------------------- home
class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Live((_) {
    final pages = <Widget>[SellPage(), StockPage(), DebtPage(), RentPage(), ReportPage()];
    return Scaffold(
      appBar: AppBar(
        title: Text(store.shop, style: _bold),
        actions: [
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: Container(height: 4, color: Color(kAccHex[store.acc]))),
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'بيع'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'المخزون'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'الديون'),
          NavigationDestination(icon: Icon(Icons.construction), label: 'الإيجار'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'التقارير'),
        ],
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
          Card(
              child: ListTile(
            leading: p.img.isEmpty ? null : thumb(p.img),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('المتوفر: ${p.qty}',
                style: TextStyle(color: p.qty <= store.low ? Colors.red : null)),
            trailing: Text(fm(p.price), style: _bold),
            onTap: () {
              final e = store.addToCart(p);
              if (e != null) toast(context, e);
            },
          )),
      ])),
      if (store.cart.isNotEmpty)
        SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        style: FilledButton.styleFrom(padding: const EdgeInsets.all(14)),
                        onPressed: () => openCart(context),
                        child: Text('الفاتورة (${store.cart.length}) · ${fm(store.net)}', style: _bold))))),
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
                tf(discC, 'خصم (د.ع)', isNum: true, onChanged: (v) {
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
                const SizedBox(height: 8),
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
                        style: FilledButton.styleFrom(padding: const EdgeInsets.all(14)),
                        onPressed: () {
                          final e = store.checkout();
                          if (e != null) {
                            toast(context, e);
                            return;
                          }
                          closed = true;
                          Navigator.pop(ctx);
                          showInvoice(context, store.lastSale!);
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
            Card(
                child: ListTile(
              leading: p.img.isEmpty ? null : thumb(p.img),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${p.cat} · الكمية: ${p.qty}${p.qty <= store.low ? ' (منخفض)' : ''}',
                  style: TextStyle(color: p.qty <= store.low ? Colors.red : null)),
              trailing: Text(fm(p.price), style: _bold),
              onTap: () => editProduct(context, p),
            )),
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
                      padding: const EdgeInsets.only(bottom: 8),
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
      Row(children: [stat('إجمالي الديون', fm(sum), c: Colors.red), stat('عدد المدينين', '${ns.length}')]),
      FilledButton.icon(
          onPressed: () => newDebt(context),
          icon: const Icon(Icons.add),
          label: const Text('تسجيل دين جديد')),
      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('المدينون', style: _bold)),
      if (ns.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد ديون مستحقة'))),
      for (final n in ns)
        Card(
            child: ListTile(
          leading: store.imgOf(n).isEmpty ? const CircleAvatar(child: Icon(Icons.person)) : thumb(store.imgOf(n)),
          title: Text(n, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(store.phoneOf(n).isEmpty ? 'آخر حركة: ${fd(store.debts[n]!.last.d)}' : store.phoneOf(n)),
          trailing: Text(fm(store.bal(n)), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DebtDetail(n))),
        )),
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
                  child: const Text('حفظ')),
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

  String statement() {
    final b = StringBuffer('${store.shop}\nكشف حساب: ${widget.name}\n------------------\n');
    for (final e in store.debts[widget.name] ?? <LEntry>[]) {
      b.writeln('${fd(e.d)} | ${e.t == 'debt' ? 'دين +' : 'تسديد −'}${fm(e.amt)}${e.note.isEmpty ? '' : ' | ${e.note}'}');
    }
    b.write('------------------\nالمتبقي: ${fm(store.bal(widget.name))}');
    return b.toString();
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
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.phone, size: 18),
                      const SizedBox(width: 6),
                      Expanded(child: Text(ph.isEmpty ? 'لا يوجد رقم هاتف' : ph, style: _bold)),
                      if (ph.isNotEmpty)
                        IconButton(icon: const Icon(Icons.call), onPressed: () => callPhone(ph)),
                    ]),
                    if (img.isNotEmpty) imgView(context, img),
                    TextButton.icon(
                        onPressed: () => editCust(context, n),
                        icon: const Icon(Icons.edit),
                        label: const Text('تعديل الهاتف والصورة')),
                  ]))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('المتبقي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(fm(bal),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: bal > 0 ? Colors.red : Colors.green)),
          ]),
          const SizedBox(height: 8),
          tf(a, 'المبلغ', isNum: true),
          tf(nt, 'ملاحظة'),
          Row(children: [
            Expanded(child: FilledButton(onPressed: () => act('pay'), child: const Text('تسديد'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => act('debt'), child: const Text('إضافة دين'))),
          ]),
          OutlinedButton.icon(
              onPressed: () => Share.share(statement()),
              icon: const Icon(Icons.share),
              label: const Text('مشاركة كشف الحساب')),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('الحركات', style: _bold)),
          for (final e in l)
            Card(
                child: ListTile(
              title: Text('${e.t == 'debt' ? 'دين' : 'تسديد'}${e.note.isEmpty ? '' : ' · ${e.note}'}'),
              subtitle: Text(fd(e.d)),
              trailing: Text('${e.t == 'debt' ? '+' : '−'}${fm(e.amt)}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: e.t == 'debt' ? Colors.red : Colors.green)),
            )),
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
                onPressed: () => newRental(context), icon: const Icon(Icons.add), label: const Text('إيجار جديد'))),
        const SizedBox(width: 8),
        Expanded(
            child: OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipPage())),
                child: const Text('إدارة المعدات'))),
      ]),
      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('قيد الإيجار (${act.length})', style: _bold)),
      if (act.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد معدات مؤجّرة حاليًا'))),
      for (final x in act)
        Card(
            child: ListTile(
          title: Text('${x.name} × ${x.qty}', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${x.cust}${x.phone.isEmpty ? '' : ' · ${x.phone}'} · منذ ${fd(x.start)} · ${x.daysNow()} يوم'),
          trailing: Text(fm(x.daysNow() * x.rate * x.qty), style: _bold),
          onTap: () => returnDialog(context, x),
        )),
      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('المعدات المتاحة', style: _bold)),
      for (final r in store.ritems)
        Card(
            child: ListTile(
          title: Text(r.name),
          subtitle: Text('${fm(r.rate)} / يوم'),
          trailing: Text('متاح ${store.avail(r)} من ${r.qty}',
              style: TextStyle(fontWeight: FontWeight.w600, color: store.avail(r) > 0 ? Colors.green : Colors.red)),
        )),
      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('سجل الإيجارات المنتهية', style: _bold)),
      TextField(
          onChanged: (v) => setState(() => q = v),
          decoration: const InputDecoration(
              hintText: 'ابحث باسم العميل أو رقم الهاتف',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder())),
      const SizedBox(height: 8),
      if (hist.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(all.isEmpty ? 'لا يوجد سجل بعد' : 'لا توجد نتائج'))),
      for (final x in hist)
        Card(
            child: ListTile(
          title: Text('${x.cust} · ${x.name} × ${x.qty}'),
          subtitle: Text('${fd(x.start)} ← ${fd(x.ret!)}${x.phone.isEmpty ? '' : ' · ${x.phone}'}'),
          trailing: Text(fm(x.total > 0 ? x.total : x.daysNow() * x.rate * x.qty), style: _bold),
          onTap: () => histDialog(context, x),
        )),
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
                  const SizedBox(height: 8),
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
            ])),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
              OutlinedButton(
                  onPressed: () {
                    final s = store.returnRental(r, false);
                    Navigator.pop(ctx);
                    showInvoice(c, s);
                  },
                  child: const Text('على الحساب (دين)')),
              FilledButton(
                  onPressed: () {
                    final s = store.returnRental(r, true);
                    Navigator.pop(ctx);
                    showInvoice(c, s);
                  },
                  child: const Text('تحصيل نقدًا')),
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
                Card(
                    child: ListTile(
                  title: Text(r.name),
                  subtitle: Text('${fm(r.rate)} / يوم'),
                  trailing: Text('العدد: ${r.qty}', style: _bold),
                  onTap: () => editEquip(context, r),
                )),
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
    bool isToday(int ms) {
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }

    bool isMonth(int ms) {
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return d.year == now.year && d.month == now.month;
    }

    double sum(Iterable<Sale> l) => l.fold(0.0, (a, s) => a + s.total);
    final ts = store.sales.where((s) => isToday(s.date)).toList();
    final mo = store.sales.where((s) => isMonth(s.date));
    final profit = store.sales.fold(0.0, (a, s) {
      final g = s.items.fold(
          0.0, (b, i) => b + ((i['price'] ?? 0) - (i['cost'] ?? 0)).toDouble() * (i['qty'] ?? 0).toDouble());
      return a + g - s.disc;
    });
    final dsum = store.debts.keys.fold(0.0, (a, n) => a + (store.bal(n) > 0 ? store.bal(n) : 0));
    final low = store.prods.where((p) => p.qty <= store.low).length;
    final recent = store.sales.reversed.take(30).toList();
    return ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [stat('مبيعات اليوم', fm(sum(ts))), stat('فواتير اليوم', '${ts.length}')]),
      Row(children: [stat('مبيعات الشهر', fm(sum(mo))), stat('إجمالي الأرباح', fm(profit), c: Colors.green)]),
      Row(children: [
        stat('الديون المستحقة', fm(dsum), c: Colors.red),
        stat('أصناف منخفضة', '$low', c: low > 0 ? Colors.red : null)
      ]),
      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('آخر الفواتير', style: _bold)),
      if (recent.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد فواتير بعد'))),
      for (final s in recent)
        Card(
            child: ListTile(
          title: Text('${s.kind == 'rent' ? 'إيجار' : 'فاتورة'} ${s.no}${s.cust.isEmpty ? '' : ' · ${s.cust}'}'),
          subtitle: Text(fd(s.date) + (s.total > s.paid ? ' · آجل' : '')),
          trailing: Text(fm(s.total), style: _bold),
          onTap: () => showInvoice(context, s),
        )),
    ]);
  }
}

// ---------------------------------------------------------------- settings
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> backup(BuildContext c) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/shop-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json');
    await f.writeAsString(store.exportJson());
    await Share.shareXFiles([XFile(f.path)], text: 'نسخة احتياطية - ${store.shop}');
  }

  Future<void> restore(BuildContext c) async {
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

  @override
  Widget build(BuildContext context) {
    final nameC = TextEditingController(text: store.shop);
    final lowC = TextEditingController(text: '${store.low}');
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Live((_) => ListView(padding: const EdgeInsets.all(16), children: [
            const Text('إعدادات المحل', style: _bold),
            const SizedBox(height: 8),
            tf(nameC, 'اسم المحل', onChanged: (v) {
              store.shop = v;
              store.save();
            }),
            const SizedBox(height: 8),
            const Text('مظهر البرنامج', style: _bold),
            const SizedBox(height: 8),
            const Text('لون التطبيق'),
            const SizedBox(height: 6),
            Wrap(spacing: 10, children: [
              for (var i = 0; i < kAccHex.length; i++)
                GestureDetector(
                    onTap: () {
                      store.acc = i;
                      store.save();
                    },
                    child: CircleAvatar(
                        backgroundColor: Color(kAccHex[i]),
                        radius: 20,
                        child: store.acc == i ? const Icon(Icons.check, color: Colors.white) : null)),
            ]),
            const SizedBox(height: 12),
            const Text('النمط'),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'auto', label: Text('تلقائي')),
                ButtonSegment(value: 'light', label: Text('فاتح')),
                ButtonSegment(value: 'dark', label: Text('داكن')),
              ],
              selected: {store.theme},
              onSelectionChanged: (s) {
                store.theme = s.first;
                store.save();
              },
            ),
            const SizedBox(height: 12),
            const Text('حجم الخط'),
            const SizedBox(height: 6),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 14, label: Text('صغير')),
                ButtonSegment(value: 16, label: Text('متوسط')),
                ButtonSegment(value: 18, label: Text('كبير')),
                ButtonSegment(value: 20, label: Text('أكبر')),
              ],
              selected: {store.fs.round()},
              onSelectionChanged: (s) {
                store.fs = s.first.toDouble();
                store.save();
              },
            ),
            const SizedBox(height: 16),
            const Text('المخزون', style: _bold),
            const SizedBox(height: 8),
            tf(lowC, 'حد التنبيه للكمية المنخفضة', isNum: true, onChanged: (v) {
              store.low = int.tryParse(v) ?? 0;
              store.save();
            }),
            const SizedBox(height: 8),
            const Text('نسخة احتياطية', style: _bold),
            const SizedBox(height: 8),
            FilledButton.icon(
                onPressed: () => backup(context),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('حفظ على Google Drive')),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                onPressed: () => restore(context),
                icon: const Icon(Icons.cloud_download),
                label: const Text('استعادة من ملف')),
            const SizedBox(height: 4),
            const Text('اختر Drive من قائمة المشاركة للحفظ، ومن منتقي الملفات للاستعادة. '
                'الملف متوافق مع نسخة المتصفح أيضًا.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 20),
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () async {
                  if (await confirmDlg(context, 'سيتم حذف كل البيانات نهائيًا. متابعة؟')) store.wipe();
                },
                child: const Text('مسح كل البيانات')),
          ])),
    );
  }
}
