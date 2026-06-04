import "dart:typed_data";

import "package:delforte/store/business_info_data.dart";
import "package:delforte/store/quote_defaults_data.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/services.dart" show rootBundle;
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;

// Palette copied from the PdfPreviewScreen in DelforteApp.jsx.
const PdfColor _navy = PdfColor.fromInt(0xFF0A0F2C);
const PdfColor _accent = PdfColor.fromInt(0xFF1E66E1);
const PdfColor _accentLight = PdfColor.fromInt(0xFF5499EE);
const PdfColor _divider = PdfColor.fromInt(0xFFE8EBF2);
const PdfColor _lightBg = PdfColor.fromInt(0xFFF3F5FB);
const PdfColor _ink = PdfColor.fromInt(0xFF0A0F2C);
const PdfColor _text = PdfColor.fromInt(0xFF2A3050);
const PdfColor _textSec = PdfColor.fromInt(0xFF5A6480);
const PdfColor _textMuted = PdfColor.fromInt(0xFF9AA3BA);

const List<String> _ptMonths = [
  "jan.", "fev.", "mar.", "abr.", "mai.", "jun.",
  "jul.", "ago.", "set.", "out.", "nov.", "dez.",
];

/// The DelforteApp.jsx typefaces: Syne (display), DM Sans (body), DM Mono (numbers).
class _Fonts {
  _Fonts({
    required this.syne,
    required this.sans,
    required this.sansSemi,
    required this.sansBold,
    required this.mono,
    required this.monoMed,
  });

  final pw.Font syne;
  final pw.Font sans;
  final pw.Font sansSemi;
  final pw.Font sansBold;
  final pw.Font mono;
  final pw.Font monoMed;
}

class _Line {
  _Line(this.name, this.qty, this.unit, this.priceCents, this.subtotalCents);
  final String name;
  final int qty;
  final String unit;
  final int priceCents;
  final int subtotalCents;
}

/// Builds the quote PDF for [quoteId], laid out like PdfPreviewScreen.
Future<Uint8List> buildQuotePdf(QuoteStore store, int quoteId) async {
  final _Fonts fonts = _Fonts(
    syne: await _loadFont("assets/fonts/Syne-ExtraBold.ttf"),
    sans: await _loadFont("assets/fonts/DMSans-Regular.ttf"),
    sansSemi: await _loadFont("assets/fonts/DMSans-SemiBold.ttf"),
    sansBold: await _loadFont("assets/fonts/DMSans-Bold.ttf"),
    mono: await _loadFont("assets/fonts/DMMono-Regular.ttf"),
    monoMed: await _loadFont("assets/fonts/DMMono-Medium.ttf"),
  );

  final BusinessInfoData business = store.businessInfo;
  final QuoteDefaultsData defaults = store.quoteDefaults;
  final Client? client = store.clientById(store.draftClientId(quoteId));

  final List<_Line> services = _linesOf(store, quoteId, CatalogItemType.service);
  final List<_Line> equipment = _linesOf(store, quoteId, CatalogItemType.equipment);
  final int subtotalServices = store.quoteSubtotal(quoteId, CatalogItemType.service);
  final int subtotalEquipment = store.quoteSubtotal(quoteId, CatalogItemType.equipment);
  final int total = store.quoteTotal(quoteId);

  final String brand = business.name.isNotEmpty ? business.name.toUpperCase() : "DELFORTE";
  final String code = "#$quoteId";
  final int createdAt = store.quoteCreatedAt(quoteId);
  final String date = _fmtDate(
    createdAt > 0 ? DateTime.fromMillisecondsSinceEpoch(createdAt) : DateTime.now(),
  );
  final String validity = defaults.validity.isNotEmpty ? defaults.validity : "Validade 30 dias";
  final String warranty = defaults.warranty.isNotEmpty ? defaults.warranty : "Garantia 90 dias";

  final pw.Document doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context context) => pw.DecoratedBox(
        decoration: const pw.BoxDecoration(color: PdfColors.white),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _headerBand(brand, code, date, validity, warranty, fonts),
            pw.Container(
              height: 3,
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  begin: pw.Alignment.centerLeft,
                  end: pw.Alignment.centerRight,
                  colors: [_accent, _accentLight],
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _billPaymentRow(client, defaults, fonts),
                    _docDivider(),
                    _linesSection("Services", services, subtotalServices, fonts),
                    _docDivider(),
                    _linesSection("Equipment", equipment, subtotalEquipment, fonts),
                    _docDivider(),
                    _totalBox(total, fonts),
                    pw.SizedBox(height: 12),
                    _termsBox(defaults, fonts),
                    pw.Spacer(),
                  ],
                ),
              ),
            ),
            _footer(business, defaults, code, date, fonts),
          ],
        ),
      ),
    ),
  );
  return doc.save();
}

Future<pw.Font> _loadFont(String asset) async => pw.Font.ttf(await rootBundle.load(asset));

List<_Line> _linesOf(QuoteStore store, int quoteId, CatalogItemType type) {
  return [
    for (final QuoteLine line in store.listQuoteLines(quoteId))
      if (line.type == type)
        _Line(
          line.name,
          line.quantity,
          store.unitAbbreviationFor(store.catalogById(type, line.refId)?.unitId ?? 0),
          line.unitPriceCents,
          line.subtotalCents,
        ),
  ];
}

String _fmtDate(DateTime d) => "${d.day} ${_ptMonths[d.month - 1]} ${d.year}";

PdfColor _alpha(double a) => PdfColor(1, 1, 1, a);

pw.Widget _headerBand(
  String brand,
  String code,
  String date,
  String validity,
  String warranty,
  _Fonts fonts,
) {
  return pw.Container(
    color: _navy,
    padding: const pw.EdgeInsets.fromLTRB(28, 26, 28, 24),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              brand,
              style: pw.TextStyle(
                font: fonts.syne,
                fontSize: 22,
                color: PdfColors.white,
                letterSpacing: -0.3,
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  "QUOTE",
                  style: pw.TextStyle(font: fonts.sans, fontSize: 9, color: _alpha(0.35), letterSpacing: 0.5),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  code,
                  style: pw.TextStyle(font: fonts.monoMed, fontSize: 14, color: PdfColors.white),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          children: [
            _metaItem(date, fonts),
            pw.SizedBox(width: 18),
            _metaItem(validity, fonts),
            pw.SizedBox(width: 18),
            _metaItem(warranty, fonts),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _metaItem(String text, _Fonts fonts) => pw.Text(
  text,
  style: pw.TextStyle(font: fonts.sans, fontSize: 9, color: _alpha(0.5)),
);

pw.Widget _docDivider() =>
    pw.Container(height: 1, color: _divider, margin: const pw.EdgeInsets.symmetric(vertical: 14));

pw.Widget _label(String text, _Fonts fonts, {PdfColor color = _textMuted}) => pw.Text(
  text.toUpperCase(),
  style: pw.TextStyle(font: fonts.sansBold, fontSize: 9, color: color, letterSpacing: 0.6),
);

pw.Widget _billPaymentRow(Client? client, QuoteDefaultsData defaults, _Fonts fonts) {
  final String payment = defaults.paymentMethod.isNotEmpty ? defaults.paymentMethod : "—";
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _label("Bill To", fonts),
            pw.SizedBox(height: 6),
            pw.Text(
              client?.name ?? "—",
              style: pw.TextStyle(font: fonts.sansBold, fontSize: 12, color: _ink),
            ),
            if (client != null && client.address.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                client.address,
                style: pw.TextStyle(font: fonts.sans, fontSize: 10, color: _textSec),
              ),
            ],
          ],
        ),
      ),
      pw.SizedBox(width: 16),
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _label("Payment", fonts),
            pw.SizedBox(height: 6),
            pw.Text(
              payment,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: fonts.sans, fontSize: 10, color: _text),
            ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _linesSection(String title, List<_Line> lines, int subtotalCents, _Fonts fonts) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      _label(title, fonts, color: _ink),
      pw.SizedBox(height: 8),
      pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(4),
          1: pw.FlexColumnWidth(1),
          2: pw.FlexColumnWidth(1),
          3: pw.FlexColumnWidth(2),
          4: pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 1.5)),
            ),
            children: [
              _th("Description", fonts, pw.TextAlign.left),
              _th("Qty", fonts, pw.TextAlign.left),
              _th("Unit", fonts, pw.TextAlign.right),
              _th("Price", fonts, pw.TextAlign.right),
              _th("Total", fonts, pw.TextAlign.right),
            ],
          ),
          for (var i = 0; i < lines.length; i++)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: i < lines.length - 1 ? _divider : PdfColors.white,
                    width: 1,
                  ),
                ),
              ),
              children: [
                _td(lines[i].name, fonts.sans, _text, pw.TextAlign.left),
                _td("${lines[i].qty}", fonts.mono, _textSec, pw.TextAlign.right),
                _td(lines[i].unit, fonts.sans, _textMuted, pw.TextAlign.right),
                _td(formatMoney(lines[i].priceCents), fonts.mono, _textSec, pw.TextAlign.right),
                _td(formatMoney(lines[i].subtotalCents), fonts.monoMed, _ink, pw.TextAlign.right),
              ],
            ),
        ],
      ),
      pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _divider, width: 1)),
        ),
        padding: const pw.EdgeInsets.only(top: 6),
        alignment: pw.Alignment.centerRight,
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: "Subtotal  ",
                style: pw.TextStyle(font: fonts.mono, fontSize: 10, color: _textSec),
              ),
              pw.TextSpan(
                text: formatMoney(subtotalCents),
                style: pw.TextStyle(font: fonts.monoMed, fontSize: 10, color: _ink),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

pw.Widget _th(String text, _Fonts fonts, pw.TextAlign align) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 5),
  child: pw.Text(
    text.toUpperCase(),
    textAlign: align,
    style: pw.TextStyle(font: fonts.sansBold, fontSize: 9, color: _ink, letterSpacing: 0.5),
  ),
);

pw.Widget _td(String text, pw.Font font, PdfColor color, pw.TextAlign align) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 6),
  child: pw.Text(text, textAlign: align, style: pw.TextStyle(font: font, fontSize: 10, color: color)),
);

pw.Widget _totalBox(int total, _Fonts fonts) => pw.Container(
  decoration: pw.BoxDecoration(color: _ink, borderRadius: pw.BorderRadius.circular(10)),
  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 13),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text("Total", style: pw.TextStyle(font: fonts.sansSemi, fontSize: 11, color: _alpha(0.7))),
      pw.Text(
        formatMoney(total),
        style: pw.TextStyle(font: fonts.monoMed, fontSize: 18, color: PdfColors.white),
      ),
    ],
  ),
);

pw.Widget _termsBox(QuoteDefaultsData defaults, _Fonts fonts) {
  final String terms = defaults.terms.isNotEmpty
      ? defaults.terms
      : "Serviços sujeitos a visita técnica prévia. Os preços podem variar após a inspeção. "
            "A instalação inclui apenas os materiais listados acima.";
  return pw.Container(
    decoration: pw.BoxDecoration(color: _lightBg, borderRadius: pw.BorderRadius.circular(8)),
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _label("Terms & Conditions", fonts),
        pw.SizedBox(height: 4),
        pw.Text(
          terms,
          style: pw.TextStyle(font: fonts.sans, fontSize: 9, color: _textSec, lineSpacing: 2),
        ),
      ],
    ),
  );
}

pw.Widget _footer(
  BusinessInfoData business,
  QuoteDefaultsData defaults,
  String code,
  String date,
  _Fonts fonts,
) {
  final List<String> contacts = [
    [business.address, business.city, business.state].where((s) => s.isNotEmpty).join(" — "),
    if (business.phone.isNotEmpty) business.phone,
    if (business.email.isNotEmpty) business.email,
    if (defaults.paymentMethod.isNotEmpty) defaults.paymentMethod,
    if (defaults.warranty.isNotEmpty) defaults.warranty,
    if (business.cnpj.isNotEmpty) "CNPJ ${business.cnpj}",
  ].where((s) => s.isNotEmpty).toList();

  return pw.Container(
    color: _navy,
    padding: const pw.EdgeInsets.fromLTRB(28, 14, 28, 14),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (contacts.isNotEmpty)
          pw.Wrap(
            spacing: 16,
            runSpacing: 5,
            children: [
              for (final String c in contacts)
                pw.Text(c, style: pw.TextStyle(font: fonts.sans, fontSize: 8.5, color: _alpha(0.35))),
            ],
          ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            "Generated by ${business.name.isNotEmpty ? business.name : "Delforte"} · $code · $date",
            style: pw.TextStyle(font: fonts.sans, fontSize: 8, color: _alpha(0.18)),
          ),
        ),
      ],
    ),
  );
}
