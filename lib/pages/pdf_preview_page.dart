import "dart:typed_data";

import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/pdf/quote_pdf.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/business_info_data.dart";
import "package:delforte/store/quote_defaults_data.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";
import "package:printing/printing.dart";

/// Renders a quote as a PDF document and lets the user share it.
///
/// Mirrors the PdfPreviewScreen in DelforteApp.jsx: a navy header with a blue
/// Share action over the rendered document. The document itself is built by
/// [buildQuotePdf].
class PdfPreviewPage extends StatefulWidget {
  const PdfPreviewPage({
    required this.store,
    required this.router,
    required this.quoteId,
    required this.back,
    super.key,
  });

  final QuoteStore store;
  final AppRouterDelegate router;
  final int quoteId;

  /// The screen the PDF was opened from, returned to on back.
  final AppRoute back;

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  late final BusinessInfoData business = widget.store.businessInfo;
  late final QuoteDefaultsData defaults = widget.store.quoteDefaults;
  late final QuotePdfData pdfData = widget.store.quotePdfData(widget.quoteId);
  late Future<Uint8List>? _doc = buildQuotePdf(business, defaults, pdfData, widget.quoteId);

  Future<void> _share() async {
    final Uint8List bytes = (await _doc)!;
    await Printing.sharePdf(bytes: bytes, filename: "orcamento_${widget.quoteId}.pdf");
  }

  @override
  void dispose() {
    _doc = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: Column(
        children: [
          FlowHeader(
            title: strings.pdfPreview,
            onBack: () => widget.router.goTo(widget.back),
            continueLabel: strings.share,
            continueIcon: Icons.ios_share_rounded,
            onContinue: _share,
          ),
          Expanded(
            child: PdfPreview(
              build: (_) => _doc!,
              useActions: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              scrollViewDecoration: const BoxDecoration(color: Color(0xFFE8EBF2)),
              previewPageMargin: const EdgeInsets.fromLTRB(12, 16, 12, 24),
              // The page is clipped to rounded transparent corners in the PDF,
              // so this white, rounded, shadowed card shows through them —
              // copied from the preview card in DelforteApp.jsx
              // (borderRadius 10/16, boxShadow 0 4px 24px rgba(0,0,0,0.12)).
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              loadingWidget: const Center(
                child: CircularProgressIndicator(color: VigilColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
