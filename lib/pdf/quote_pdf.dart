import "dart:typed_data";

import "package:delforte/l10n/localization.dart";
import "package:delforte/store/business_info_data.dart";
import "package:delforte/store/quote_defaults_data.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/services.dart" show rootBundle;
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;

// Smartphone-width page (414 pt, iPhone-class) with a dynamic height: passing
// double.infinity makes the pdf package shrink the page to fit the content
// exactly — one continuous mobile-style sheet, no trailing whitespace. The
// content Columns must size to their content (MainAxisSize.min, no Expanded or
// Spacer) since the page height is unbounded during layout.
const PdfPageFormat _phonePage = PdfPageFormat(414, double.infinity);

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
Future<Uint8List> buildQuotePdf(
  BusinessInfoData business,
  QuoteDefaultsData defaults,
  QuotePdfData data,
  int quoteId,
) async {
  final _Fonts fonts = await _loadFonts();

  final Client? client = data.client;

  final List<_Line> services = _linesOf(data, CatalogItemType.service);
  final List<_Line> equipment = _linesOf(data, CatalogItemType.equipment);
  final int subtotalServices = services.fold(0, (sum, line) => sum + line.subtotalCents);
  final int subtotalEquipment = equipment.fold(0, (sum, line) => sum + line.subtotalCents);
  final int total = subtotalServices + subtotalEquipment;

  final String brand = business.name.isNotEmpty
      ? business.name.toUpperCase()
      : strings.appName.toUpperCase();
  final pw.MemoryImage? logo = business.logo.isNotEmpty ? pw.MemoryImage(business.logo) : null;
  final String code = "#$quoteId";
  final int createdAt = data.createdAt;
  final String date = _fmtDate(
    createdAt > 0 ? DateTime.fromMillisecondsSinceEpoch(createdAt) : DateTime.now(),
  );
  final String validity = defaults.validity.isNotEmpty
      ? defaults.validity
      : strings.pdfDefaultValidity;
  final String warranty = defaults.warranty.isNotEmpty
      ? defaults.warranty
      : strings.pdfDefaultWarranty;

  final pw.Document doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: _phonePage,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context context) => pw.DecoratedBox(
        decoration: const pw.BoxDecoration(color: PdfColors.white),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _headerBand(brand, logo, code, date, validity, warranty, fonts),
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
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _billPaymentRow(client, defaults, fonts),
                  _docDivider(),
                  _linesSection(strings.services, services, subtotalServices, fonts),
                  _docDivider(),
                  _linesSection(strings.equipment, equipment, subtotalEquipment, fonts),
                  _docDivider(),
                  _totalBox(total, fonts),
                  pw.SizedBox(height: 12),
                  _termsBox(defaults, fonts),
                ],
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

/// The PDF fonts, loaded from assets once and reused across every quote PDF.
/// Caching the future also collapses concurrent first calls into one load.
Future<_Fonts>? _fontsFuture;

Future<_Fonts> _loadFonts() => _fontsFuture ??= _buildFonts();

Future<_Fonts> _buildFonts() async => _Fonts(
  syne: pw.Font.ttf(await rootBundle.load("assets/fonts/Syne-ExtraBold.ttf")),
  sans: pw.Font.ttf(await rootBundle.load("assets/fonts/DMSans-Regular.ttf")),
  sansSemi: pw.Font.ttf(await rootBundle.load("assets/fonts/DMSans-SemiBold.ttf")),
  sansBold: pw.Font.ttf(await rootBundle.load("assets/fonts/DMSans-Bold.ttf")),
  mono: pw.Font.ttf(await rootBundle.load("assets/fonts/DMMono-Regular.ttf")),
  monoMed: pw.Font.ttf(await rootBundle.load("assets/fonts/DMMono-Medium.ttf")),
);

List<_Line> _linesOf(QuotePdfData data, CatalogItemType type) {
  return [
    for (final QuotePdfLine line in data.lines)
      if (line.type == type)
        _Line(line.name, line.quantity, line.unit, line.unitPriceCents, line.subtotalCents),
  ];
}

String _fmtDate(DateTime d) => "${d.day} ${strings.monthAbbreviations[d.month - 1]} ${d.year}";

PdfColor _alpha(double a) => PdfColor(1, 1, 1, a);

pw.Widget _headerBand(
  String brand,
  pw.MemoryImage? logo,
  String code,
  String date,
  String validity,
  String warranty,
  _Fonts fonts,
) {
  pw.Widget brandArea;
  if (logo == null) {
    brandArea = pw.Text(
      brand,
      maxLines: 1,
      softWrap: false,
      overflow: pw.TextOverflow.clip,
      style: pw.TextStyle(
        font: fonts.syne,
        fontSize: 22,
        color: PdfColors.white,
        letterSpacing: -0.3,
      ),
    );
  } else {
    // Fit by height: fixed tall, width follows the logo's own aspect ratio.
    // Passing both width and height (instead of height alone) gives the image a
    // bounded box so it can't overflow the Row and get clipped on the right.
    const double height = 56;
    final double ratio = (logo.width ?? 1) / (logo.height ?? 1);
    final double width = height * ratio;
    brandArea = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Image(logo, width: width, height: height, fit: .fitHeight),
        pw.SizedBox(width: 12),
        pw.Flexible(
          child: pw.Text(
            brand,
            maxLines: 1,
            softWrap: false,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              font: fonts.syne,
              fontSize: 13,
              color: PdfColors.white,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
  return pw.Container(
    color: _navy,
    padding: const pw.EdgeInsets.fromLTRB(28, 26, 28, 24),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Brand area owns the full header height and centers in it, so the logo
        // expands vertically against the taller QUOTE / #code / meta stack.
        pw.Expanded(child: brandArea),
        pw.SizedBox(width: 12),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              strings.pdfQuote,
              style: pw.TextStyle(
                font: fonts.sans,
                fontSize: 9,
                color: _alpha(0.35),
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              code,
              style: pw.TextStyle(font: fonts.monoMed, fontSize: 14, color: PdfColors.white),
            ),
            pw.SizedBox(height: 12),
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
            _label(strings.pdfBillTo, fonts),
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
            _label(strings.pdfPayment, fonts),
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
              _th(strings.description, fonts, pw.TextAlign.left),
              _th(strings.pdfQty, fonts, pw.TextAlign.left),
              _th(strings.unit, fonts, pw.TextAlign.right),
              _th(strings.pdfPrice, fonts, pw.TextAlign.right),
              _th(strings.total, fonts, pw.TextAlign.right),
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
                text: "${strings.pdfSubtotal}  ",
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
  child: pw.Text(
    text,
    textAlign: align,
    style: pw.TextStyle(font: font, fontSize: 10, color: color),
  ),
);

pw.Widget _totalBox(int total, _Fonts fonts) => pw.Container(
  decoration: pw.BoxDecoration(color: _ink, borderRadius: pw.BorderRadius.circular(10)),
  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 13),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        strings.total,
        style: pw.TextStyle(font: fonts.sansSemi, fontSize: 11, color: _alpha(0.7)),
      ),
      pw.Text(
        formatMoney(total),
        style: pw.TextStyle(font: fonts.monoMed, fontSize: 18, color: PdfColors.white),
      ),
    ],
  ),
);

pw.Widget _termsBox(QuoteDefaultsData defaults, _Fonts fonts) {
  final String terms = defaults.terms.isNotEmpty ? defaults.terms : strings.pdfDefaultTerms;
  return pw.Container(
    decoration: pw.BoxDecoration(color: _lightBg, borderRadius: pw.BorderRadius.circular(8)),
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _label(strings.termsConditions, fonts),
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
    if (business.cnpj.isNotEmpty) strings.cnpjLabel(business.cnpj),
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
                pw.Text(
                  c,
                  style: pw.TextStyle(font: fonts.sans, fontSize: 8.5, color: _alpha(0.35)),
                ),
            ],
          ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            strings.pdfGeneratedBy(
              business.name.isNotEmpty ? business.name : strings.appName,
              code,
              date,
            ),
            style: pw.TextStyle(font: fonts.sans, fontSize: 8, color: _alpha(0.18)),
          ),
        ),
      ],
    ),
  );
}
