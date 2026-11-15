import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

const kCats = ['كهربائيات', 'إنشائيات', 'أخرى'];
const kAccHex = [
  0xFFF2B705, 0xFFE8590C, 0xFF1C7ED6, 0xFF2F9E44,
  0xFF7048E8, 0xFFD6336C, 0xFF0CA678, 0xFF495057
];
// colors available for the "new operation" / "receipt" operations
const kOpHex = [0xFF1C7ED6, 0xFFE03131, 0xFF2F9E44, 0xFFF08C00, 0xFF7048E8, 0xFF0CA678];

String fm(num n) => '${NumberFormat('#,##0').format(n.round())} ${store.cur}';
String fd(int ms) => DateFormat('yyyy/MM/dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ms));
int nowMs() => DateTime.now().millisecondsSinceEpoch;
double _d(dynamic v) => (v ?? 0).toDouble();
int _i(dynamic v) => (v ?? 0).toInt();
String norm(String s) => s.trim().toLowerCase().replaceAllMapped(
    RegExp('[٠-٩]'), (m) => '٠١٢٣٤٥٦٧٨٩'.indexOf(m[0]!).toString());

final _imgCache = <String, Uint8List>{};
Uint8List imgBytes(String s) => _imgCache.putIfAbsent(s, () => base64Decode(s));

class Product {
  int id, qty;
  String name, cat, img;
  double price, cost;
  Product(
      {required this.id,
      required this.name,
      required this.cat,
      required this.price,
      this.cost = 0,
      required this.qty,
      this.img = ''});
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'cat': cat, 'price': price, 'cost': cost, 'qty': qty, 'img': img};
  factory Product.fromJson(Map<String, dynamic> j) => Product(
      id: _i(j['id']),
      name: j['name'],
      cat: j['cat'] ?? kCats[0],
      price: _d(j['price']),
      cost: _d(j['cost']),
      qty: _i(j['qty']),
      img: (j['img'] ?? '').toString());
}

class CartLine {
  Product p;
  int qty;
  CartLine(this.p, this.qty);
}

class Sale {
  int no, date;
  String cust, kind;
  double disc, total, paid;
  List<Map<String, dynamic>> items;
  Sale(
      {required this.no,
      required this.date,
      required this.cust,
      required this.kind,
      required this.disc,
      required this.total,
      required this.paid,
      required this.items});
  Map<String, dynamic> toJson() => {
        'no': no,
        'date': date,
        'cust': cust,
        'kind': kind,
        'disc': disc,
        'total': total,
        'paid': paid,
        'items': items
      };
  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
      no: _i(j['no']),
      date: _i(j['date']),
      cust: (j['cust'] ?? '').toString(),
      kind: (j['kind'] ?? 'sale').toString(),
      disc: _d(j['disc']),
      total: _d(j['total']),
      paid: _d(j['paid']),
      items: ((j['items'] ?? []) as List).map((e) => Map<String, dynamic>.from(e)).toList());
  String text() {
    final b = StringBuffer('${store.shop}\n');
    if (store.shopPhone.isNotEmpty) b.writeln(store.shopPhone);
    b.writeln('${kind == 'rent' ? 'إيجار' : 'فاتورة'} رقم $no\n${fd(date)}');
    if (cust.isNotEmpty) b.writeln('العميل: $cust');
    b.writeln('------------------');
    for (final i in items) {
      b.writeln('${i['name']}\n   ${i['qty']} × ${fm(_d(i['price']))} = ${fm(_d(i['qty']) * _d(i['price']))}');
    }
    b.writeln('------------------');
    if (disc > 0) b.writeln('الخصم: ${fm(disc)}');
    b.write('الإجمالي: ${fm(total)}');
    if (total - paid > 0) {
      b.write('\nالمدفوع: ${fm(paid)}\nالمتبقي (دين): ${fm(total - paid)}');
    }
    if (store.footer.isNotEmpty) b.write('\n${store.footer}');
    return b.toString();
  }
}

class LEntry {
  int d;
  String t, note;
  double amt;
  LEntry(this.d, this.t, this.amt, this.note);
  Map<String, dynamic> toJson() => {'d': d, 't': t, 'amt': amt, 'note': note};
  factory LEntry.fromJson(Map<String, dynamic> j) =>
      LEntry(_i(j['d']), (j['t'] ?? 'debt').toString(), _d(j['amt']), (j['note'] ?? '').toString());
}

class RItem {
  int id, qty;
  String name;
  double rate;
  RItem({required this.id, required this.name, required this.rate, required this.qty});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'rate': rate, 'qty': qty};
  factory RItem.fromJson(Map<String, dynamic> j) =>
      RItem(id: _i(j['id']), name: j['name'], rate: _d(j['rate']), qty: _i(j['qty']));
}

class Rental {
  int id, item, qty, start, days;
  int? ret;
  String name, cust, phone, note;
  double rate, total;
  bool? cash;
  Rental(
      {required this.id,
      required this.item,
      required this.name,
      required this.rate,
      required this.qty,
      required this.cust,
      this.phone = '',
      this.note = '',
      required this.start,
      this.ret,
      this.total = 0,
      this.days = 0,
      this.cash});
  int daysNow() => max(store.minDays, (((ret ?? nowMs()) - start) / 86400000).ceil());
  Map<String, dynamic> toJson() => {
        'id': id,
        'item': item,
        'name': name,
        'rate': rate,
        'qty': qty,
        'cust': cust,
        'phone': phone,
        'note': note,
        'start': start,
        'ret': ret,
        'total': total,
        'days': days,
        'cash': cash
      };
  factory Rental.fromJson(Map<String, dynamic> j) => Rental(
      id: _i(j['id']),
      item: _i(j['item']),
      name: j['name'],
      rate: _d(j['rate']),
      qty: _i(j['qty']),
      cust: (j['cust'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      note: (j['note'] ?? '').toString(),
      start: _i(j['start']),
      ret: j['ret'] == null ? null : _i(j['ret']),
      total: _d(j['total']),
      days: _i(j['days']),
      cash: j['cash'] as bool?);
}

class Store extends ChangeNotifier {
  // ---- settings ----
  String shop = 'محل الكهربائيات والإنشائيات',
      shopPhone = '',
      shopAddr = '',
      footer = 'شكرًا لتعاملكم معنا',
      cur = 'د.ع',
      theme = 'auto',
      bkMode = 'manual'; // manual | remind | auto
  int acc = 0, rad = 1, newCol = 0, recvCol = 1, low = 5, minDays = 1;
  int bkEvery = 7, bkKeep = 7, lastBk = 0, lastDrive = 0, no = 1000;
  double fs = 16;
  bool showStock = true,
      showDebt = true,
      showRent = true,
      showQuick = true,
      qDebt = true,
      qRent = true,
      qStock = true,
      qSell = false,
      defCredit = false,
      autoInvoice = true;

  // ---- data ----
  List<Product> prods = [];
  List<RItem> ritems = [];
  List<Rental> rentals = [];
  List<Sale> sales = [];
  Map<String, List<LEntry>> debts = {};
  Map<String, Map<String, String>> cinfo = {};

  // current cart (not saved)
  List<CartLine> cart = [];
  double disc = 0, paid = 0;
  bool credit = false;
  String cust = '';
  Sale? lastSale;

  late Directory _dir;
  late File _f;

  void touch() => notifyListeners();
  void upd(VoidCallback f) {
    f();
    save();
  }

  Future<void> init() async {
    _dir = await getApplicationDocumentsDirectory();
    _f = File('${_dir.path}/shop.json');
    if (await _f.exists()) {
      try {
        load(jsonDecode(await _f.readAsString()));
        return;
      } catch (_) {}
    }
    seed();
    lastDrive = nowMs();
  }

  void seed() {
    prods = [
      Product(id: 1, name: 'سلك نحاس 2.5 ملم (لفة 100م)', cat: kCats[0], price: 70000, cost: 60000, qty: 20),
      Product(id: 2, name: 'مفتاح إضاءة مفرد', cat: kCats[0], price: 1500, cost: 1000, qty: 100),
      Product(id: 3, name: 'لمبة LED 12 واط', cat: kCats[0], price: 2500, cost: 1700, qty: 80),
      Product(id: 4, name: 'قاطع كهرباء 32 أمبير', cat: kCats[0], price: 7500, cost: 5500, qty: 30),
      Product(id: 5, name: 'أسمنت (كيس 50 كغم)', cat: kCats[1], price: 6500, cost: 5800, qty: 60),
      Product(id: 6, name: 'حديد تسليح 12 ملم (طن)', cat: kCats[1], price: 900000, cost: 840000, qty: 3),
      Product(id: 7, name: 'دهان بلاستك 18 لتر', cat: kCats[1], price: 45000, cost: 36000, qty: 12),
      Product(id: 8, name: 'أنبوب PVC 4 إنش', cat: kCats[1], price: 12000, cost: 9000, qty: 40),
    ];
    ritems = [
      RItem(id: 1, name: 'سقالة حديد', rate: 2000, qty: 30),
      RItem(id: 2, name: 'خلاطة كونكريت', rate: 15000, qty: 3),
      RItem(id: 3, name: 'مثقاب هدم', rate: 10000, qty: 4),
      RItem(id: 4, name: 'سلم المنيوم', rate: 5000, qty: 6),
    ];
    rentals = [];
    sales = [];
    debts = {};
    cinfo = {};
    no = 1000;
  }

  // The JSON format is shared with the web version, so backups are interchangeable.
  void load(Map j) {
    final s = (j['set'] ?? {}) as Map;
    String S(String k, String d) => s[k] == null ? d : s[k].toString();
    int I(String k, int d) => s[k] == null ? d : _i(s[k]);
    bool B(String k, bool d) => s[k] == null ? d : s[k] == true;
    shop = S('shop', shop);
    shopPhone = S('shopPhone', '');
    shopAddr = S('shopAddr', '');
    footer = S('footer', 'شكرًا لتعاملكم معنا');
    cur = S('cur', 'د.ع');
    theme = S('theme', 'auto');
    bkMode = S('bkMode', 'manual');
    acc = I('acc', 0).clamp(0, kAccHex.length - 1).toInt();
    rad = I('rad', 1).clamp(0, 2).toInt();
    newCol = I('newCol', 0).clamp(0, kOpHex.length - 1).toInt();
    recvCol = I('recvCol', 1).clamp(0, kOpHex.length - 1).toInt();
    low = I('low', 5);
    minDays = I('minDays', 1);
    bkEvery = I('bkEvery', 7);
    bkKeep = I('bkKeep', 7);
    lastBk = I('lastBk', 0);
    lastDrive = I('lastDrive', 0);
    if (lastDrive == 0) lastDrive = nowMs();
    fs = s['fs'] == null ? 16 : _d(s['fs']);
    showStock = B('showStock', true);
    showDebt = B('showDebt', true);
    showRent = B('showRent', true);
    showQuick = B('showQuick', true);
    qDebt = B('qDebt', true);
    qRent = B('qRent', true);
    qStock = B('qStock', true);
    qSell = B('qSell', false);
    defCredit = B('defCredit', false);
    autoInvoice = B('autoInvoice', true);
    credit = defCredit;
    no = j['no'] == null ? 1000 : _i(j['no']);
    List<Map<String, dynamic>> L(dynamic v) =>
        ((v ?? []) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    prods = L(j['prods']).map(Product.fromJson).toList();
    ritems = L(j['ritems']).map(RItem.fromJson).toList();
    rentals = L(j['rentals']).map(Rental.fromJson).toList();
    sales = L(j['sales']).map(Sale.fromJson).toList();
    debts = {};
    ((j['debts'] ?? {}) as Map).forEach((k, v) {
      debts[k.toString()] = L(v).map(LEntry.fromJson).toList();
    });
    cinfo = {};
    ((j['cinfo'] ?? {}) as Map).forEach((k, v) {
      cinfo[k.toString()] = {
        'phone': ((v as Map)['phone'] ?? '').toString(),
        'img': (v['img'] ?? '').toString()
      }..removeWhere((_, x) => x.isEmpty);
    });
  }

  Map<String, dynamic> toJson() => {
        'set': {
          'shop': shop,
          'shopPhone': shopPhone,
          'shopAddr': shopAddr,
          'footer': footer,
          'cur': cur,
          'theme': theme,
          'bkMode': bkMode,
          'acc': acc,
          'rad': rad,
          'newCol': newCol,
          'recvCol': recvCol,
          'low': low,
          'minDays': minDays,
          'bkEvery': bkEvery,
          'bkKeep': bkKeep,
          'lastBk': lastBk,
          'lastDrive': lastDrive,
          'fs': fs,
          'showStock': showStock,
          'showDebt': showDebt,
          'showRent': showRent,
          'showQuick': showQuick,
          'qDebt': qDebt,
          'qRent': qRent,
          'qStock': qStock,
          'qSell': qSell,
          'defCredit': defCredit,
          'autoInvoice': autoInvoice,
        },
        'no': no,
        'prods': prods.map((e) => e.toJson()).toList(),
        'ritems': ritems.map((e) => e.toJson()).toList(),
        'rentals': rentals.map((e) => e.toJson()).toList(),
        'sales': sales.map((e) => e.toJson()).toList(),
        'debts': debts.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
        'cinfo': cinfo,
      };

  String exportJson() => jsonEncode(toJson());

  void importJson(String s) {
    final j = jsonDecode(s);
    if (j is! Map || j['prods'] == null || j['set'] == null) throw const FormatException();
    load(j);
    save();
  }

  void wipe() {
    seed();
    save();
  }

  void save() {
    _f.writeAsString(jsonEncode(toJson()));
    notifyListeners();
  }

  // ---------- backups ----------
  Directory get _bdir => Directory('${_dir.path}/backups');

  Future<List<File>> backups() async {
    if (!await _bdir.exists()) return [];
    final l = _bdir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
    l.sort((a, b) => b.path.compareTo(a.path));
    return l;
  }

  Future<void> localBackup() async {
    await _bdir.create(recursive: true);
    final f = File('${_bdir.path}/auto-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}.json');
    await f.writeAsString(exportJson());
    final l = await backups();
    for (final o in l.skip(max(1, bkKeep))) {
      try {
        await o.delete();
      } catch (_) {}
    }
    lastBk = nowMs();
    save();
  }

  Future<void> autoBackupIfDue() async {
    if (bkMode != 'auto') return;
    if (nowMs() - lastBk > bkEvery * 86400000) await localBackup();
  }

  bool get driveDue => bkMode != 'manual' && nowMs() - lastDrive > bkEvery * 86400000;

  void markDrive() {
    lastDrive = nowMs();
    save();
  }

  // ---------- customers & debts ----------
  double bal(String n) =>
      (debts[n] ?? []).fold(0.0, (a, e) => a + (e.t == 'debt' ? e.amt : -e.amt));
  void addL(String n, String t, double amt, String note) =>
      (debts[n] ??= []).add(LEntry(nowMs(), t, amt, note));
  String phoneOf(String n) => cinfo[n]?['phone'] ?? '';
  String imgOf(String n) => cinfo[n]?['img'] ?? '';
  void setInfo(String n, String phone, String img) {
    final m = cinfo.putIfAbsent(n, () => <String, String>{});
    if (phone.isNotEmpty) m['phone'] = phone;
    if (img.isNotEmpty) m['img'] = img;
  }

  // ---------- cart ----------
  double get cartTotal => cart.fold(0.0, (a, c) => a + c.p.price * c.qty);
  double get net => cartTotal - min(disc, cartTotal);

  String? addToCart(Product p) {
    final i = cart.indexWhere((c) => c.p.id == p.id);
    final cur = i < 0 ? 0 : cart[i].qty;
    if (cur + 1 > p.qty) return 'الكمية المتوفرة غير كافية';
    if (i < 0) {
      cart.add(CartLine(p, 1));
    } else {
      cart[i].qty++;
    }
    touch();
    return null;
  }

  String? change(CartLine c, int d) {
    if (d > 0 && c.qty + 1 > c.p.qty) return 'الكمية المتوفرة غير كافية';
    c.qty += d;
    if (c.qty <= 0) cart.remove(c);
    touch();
    return null;
  }

  String? checkout() {
    final c = cust.trim();
    if (credit && c.isEmpty) return 'اكتب اسم العميل للبيع الآجل';
    final t = cartTotal, d = min(disc, t), n = t - d;
    final p = credit ? min(paid, n) : n;
    no++;
    final s = Sale(
        no: no,
        date: nowMs(),
        cust: c,
        kind: 'sale',
        disc: d,
        total: n,
        paid: p,
        items: cart
            .map((l) => {'name': l.p.name, 'price': l.p.price, 'cost': l.p.cost, 'qty': l.qty})
            .toList());
    for (final l in cart) {
      l.p.qty -= l.qty;
    }
    if (n - p > 0) addL(c, 'debt', n - p, 'فاتورة $no');
    sales.add(s);
    lastSale = s;
    cart = [];
    disc = 0;
    paid = 0;
    credit = defCredit;
    cust = '';
    save();
    return null;
  }

  // ---------- rentals ----------
  int avail(RItem r) =>
      r.qty - rentals.where((x) => x.ret == null && x.item == r.id).fold(0, (a, x) => a + x.qty);

  String? addRental(RItem r, int q, String c, String phone, String note, String img) {
    if (c.isEmpty || q <= 0) return 'أكمل البيانات';
    if (q > avail(r)) return 'العدد المتاح أقل';
    final ph = phone.isNotEmpty ? phone : phoneOf(c);
    setInfo(c, ph, img);
    rentals.add(Rental(
        id: nowMs(),
        item: r.id,
        name: r.name,
        rate: r.rate,
        qty: q,
        cust: c,
        phone: ph,
        note: note,
        start: nowMs()));
    save();
    return null;
  }

  Sale returnRental(Rental r, bool cash) {
    final n = r.daysNow(), t = n * r.rate * r.qty;
    r.ret = nowMs();
    r.total = t;
    r.days = n;
    r.cash = cash;
    no++;
    final s = Sale(
        no: no,
        date: nowMs(),
        cust: r.cust,
        kind: 'rent',
        disc: 0,
        total: t,
        paid: cash ? t : 0,
        items: [
          {'name': 'إيجار ${r.name} × ${r.qty} ($n يوم)', 'price': t, 'cost': 0.0, 'qty': 1}
        ]);
    if (!cash) addL(r.cust, 'debt', t, 'إيجار ${r.name}');
    sales.add(s);
    save();
    return s;
  }
}

final store = Store();
