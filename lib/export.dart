import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'store.dart';

class Doc {
  final String title, file, text;
  final List<List<String>> info, rows, totals;
  final List<String> head;
  Doc(
      {required this.title,
      required this.file,
      required this.text,
      required this.info,
      required this.head,
      required this.rows,
      required this.totals});
}

String _stamp() => DateFormat('yyyyMMdd-HHmm').format(DateTime.now());

// ---------------------------------------------------------------- documents
Doc debtDoc(String n) {
  final l = store.debts[n] ?? <LEntry>[];
  double debt = 0, paid = 0;
  for (final e in l) {
    if (e.t == 'debt') {
      debt += e.amt;
    } else {
      paid += e.amt;
    }
  }
  final ph = store.phoneOf(n);
  final b = StringBuffer('${store.shop}\n');
  if (store.shopPhone.isNotEmpty) b.writeln(store.shopPhone);
  b.writeln('كشف حساب: $n\n------------------');
  for (final e in l) {
    b.writeln('${fd(e.d)} | ${e.t == 'debt' ? 'دين +' : 'استلام دفعة −'}${fm(e.amt)}${e.note.isEmpty ? '' : ' | ${e.note}'}');
  }
  b.write('------------------\nالمتبقي: ${fm(debt - paid)}');
  return Doc(
    title: 'كشف حساب دين',
    file: 'debt-${_stamp()}',
    text: b.toString(),
    info: [
      ['العميل', n],
      if (ph.isNotEmpty) ['الهاتف', ph],
      ['التاريخ', fd(nowMs())],
    ],
    head: ['التاريخ', 'النوع', 'البيان', 'المبلغ'],
    rows: l.map((e) => [fd(e.d), e.t == 'debt' ? 'دين جديد' : 'استلام دفعة', e.note, fm(e.amt)]).toList(),
    totals: [
      ['إجمالي الديون', fm(debt)],
      ['إجمالي المستلم', fm(paid)],
      ['المتبقي', fm(debt - paid)],
    ],
  );
}

Doc rentalDoc(List<Rental> rs, String cust) {
  double tot = 0;
  final rows = <List<String>>[];
  final b = StringBuffer('${store.shop}\n');
  if (store.shopPhone.isNotEmpty) b.writeln(store.shopPhone);
  b.writeln('كشف إيجار: $cust\n------------------');
  for (final r in rs) {
    final days = r.ret != null && r.days > 0 ? r.days : r.daysNow();
    final amt = r.ret != null && r.total > 0 ? r.total : days * r.rate * r.qty;
    tot += amt;
    rows.add([
      r.name,
      '${r.qty}',
      fd(r.start),
      r.ret == null ? 'لم يُسترجع' : fd(r.ret!),
      '$days',
      fm(r.rate),
      fm(amt)
    ]);
    b.writeln('${r.name} × ${r.qty}\n   ${fd(r.start)} ← ${r.ret == null ? 'لم يُسترجع' : fd(r.ret!)}\n   $days يوم × ${fm(r.rate)} = ${fm(amt)}');
  }
  b.write('------------------\nالإجمالي: ${fm(tot)}');
  final ph = store.phoneOf(cust).isNotEmpty
      ? store.phoneOf(cust)
      : rs.map((r) => r.phone).firstWhere((p) => p.isNotEmpty, orElse: () => '');
  final notes = rs.map((r) => r.note).where((n) => n.isNotEmpty).toSet().join('، ');
  final totals = <List<String>>[
    ['إجمالي الإيجار', fm(tot)]
  ];
  if (rs.length == 1) {
    final r = rs.first;
    totals.add([
      'الحالة',
      r.ret == null ? 'قيد الإيجار (حتى الآن)' : r.cash == null ? 'مستلم' : r.cash! ? 'مستلم - دُفع نقدًا' : 'مستلم - على الحساب (دين)'
    ]);
  }
  return Doc(
    title: 'كشف إيجار معدات',
    file: 'rental-${_stamp()}',
    text: b.toString(),
    info: [
      ['المستأجر', cust],
      if (ph.isNotEmpty) ['الهاتف', ph],
      if (notes.isNotEmpty) ['ملاحظات', notes],
      ['التاريخ', fd(nowMs())],
    ],
    head: ['المعدة', 'العدد', 'الاستلام', 'الإرجاع', 'الأيام', 'الأجرة اليومية', 'المبلغ'],
    rows: rows,
    totals: totals,
  );
}

Doc saleDoc(Sale s) {
  final kind = s.kind == 'rent' ? 'إيجار' : 'فاتورة';
  return Doc(
    title: '$kind رقم ${s.no}',
    file: 'invoice-${s.no}',
    text: s.text(),
    info: [
      if (s.cust.isNotEmpty) ['العميل', s.cust],
      ['التاريخ', fd(s.date)],
    ],
    head: ['الصنف', 'العدد', 'السعر', 'المبلغ'],
    rows: s.items
        .map((i) => [
              '${i['name']}',
              '${i['qty']}',
              fm((i['price'] ?? 0).toDouble()),
              fm((i['price'] ?? 0).toDouble() * (i['qty'] ?? 0).toDouble())
            ])
        .toList(),
    totals: [
      if (s.disc > 0) ['الخصم', fm(s.disc)],
      ['الإجمالي', fm(s.total)],
      if (s.total - s.paid > 0) ['المدفوع', fm(s.paid)],
      if (s.total - s.paid > 0) ['المتبقي (دين)', fm(s.total - s.paid)],
    ],
  );
}

// ---------------------------------------------------------------- files
PdfColor _shade(int v, double f) =>
    PdfColor(((v >> 16) & 255) * f / 255, ((v >> 8) & 255) * f / 255, (v & 255) * f / 255);

Future<File> toPdf(Doc d) async {
  final reg = pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
  pw.Widget t(String s,
          {bool b = false, double size = 12, PdfColor? col, pw.TextAlign a = pw.TextAlign.right}) =>
      pw.Text(s,
          textDirection: pw.TextDirection.rtl,
          textAlign: a,
          style: pw.TextStyle(font: b ? bold : reg, fontSize: size, color: col));
  pw.Widget cell(String s, {bool b = false}) => pw.Padding(
      padding: const pw.EdgeInsets.all(5), child: t(s, b: b, size: 10.5, a: pw.TextAlign.center));

  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(28),
    build: (ctx) => [
      pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
              color: _shade(kAccHex[store.acc], .62), borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            t(store.shop, b: true, size: 22, col: PdfColors.white),
            if (store.shopPhone.isNotEmpty) t(store.shopPhone, col: PdfColors.white),
            if (store.shopAddr.isNotEmpty) t(store.shopAddr, col: PdfColors.white),
          ])),
      pw.SizedBox(height: 14),
      t(d.title, b: true, size: 17),
      pw.SizedBox(height: 6),
      for (final i in d.info) t('${i[0]}: ${i[1]}'),
      pw.SizedBox(height: 10),
      pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey500, width: .5),
          children: [
            pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: d.head.reversed.map((h) => cell(h, b: true)).toList()),
            for (final r in d.rows) pw.TableRow(children: r.reversed.map((x) => cell(x)).toList()),
          ]),
      pw.SizedBox(height: 12),
      for (final x in d.totals) t('${x[0]}: ${x[1]}', b: true, size: 14),
      if (store.footer.isNotEmpty) ...[
        pw.SizedBox(height: 26),
        t(store.footer, a: pw.TextAlign.center),
      ],
    ],
  ));
  final f = File('${(await getTemporaryDirectory()).path}/${d.file}.pdf');
  await f.writeAsBytes(await doc.save());
  return f;
}

Future<File> toXlsx(Doc d) async {
  final ex = xl.Excel.createExcel();
  final sh = ex['Sheet1'];
  void row(List<String> r) => sh.appendRow(r.map((e) => xl.TextCellValue(e)).toList());
  row([store.shop]);
  if (store.shopPhone.isNotEmpty) row([store.shopPhone]);
  row([d.title]);
  row([]);
  for (final i in d.info) {
    row(i);
  }
  row([]);
  row(d.head);
  for (final r in d.rows) {
    row(r);
  }
  row([]);
  for (final t in d.totals) {
    row(t);
  }
  final bytes = ex.encode();
  final f = File('${(await getTemporaryDirectory()).path}/${d.file}.xlsx');
  await f.writeAsBytes(bytes!);
  return f;
}

Future<void> shareDoc(BuildContext c, Doc d, String fmt) async {
  try {
    if (fmt == 'text') {
      await Share.share(d.text);
      return;
    }
    final f = fmt == 'pdf' ? await toPdf(d) : await toXlsx(d);
    await Share.shareXFiles([XFile(f.path)], text: d.title);
  } catch (e) {
    if (c.mounted) {
      ScaffoldMessenger.of(c)
          .showSnackBar(SnackBar(content: Text('تعذر إنشاء الملف: $e')));
    }
  }
}

/// Three share buttons: PDF / Excel / plain text.
Widget shareRow(BuildContext c, Doc Function() make) => Wrap(spacing: 6, runSpacing: 6, children: [
      for (final o in const [
        ['pdf', 'PDF', Icons.picture_as_pdf],
        ['xlsx', 'Excel', Icons.table_chart],
        ['text', 'نص', Icons.share],
      ])
        OutlinedButton.icon(
            onPressed: () => shareDoc(c, make(), o[0] as String),
            icon: Icon(o[2] as IconData, size: 18),
            label: Text(o[1] as String)),
    ]);
