import "dart:typed_data";

import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/pdf/quote_pdf.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
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
  late final Future<Uint8List> _doc = buildQuotePdf(widget.store, widget.quoteId);

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: Column(
        children: [
          _header(),
          Expanded(
            child: PdfPreview(
              build: (_) => _doc,
              useActions: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              scrollViewDecoration: const BoxDecoration(color: Color(0xFFE8EBF2)),
              loadingWidget: const Center(
                child: CircularProgressIndicator(color: VigilColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return ColoredBox(
      color: VigilColors.ink,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(
          children: [
            HeaderIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: "Back",
              onPressed: () => widget.router.goTo(widget.back),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "PDF Preview",
                style: VigilType.title(color: VigilColors.surface, size: 17),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: VigilColors.primary,
                foregroundColor: VigilColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              ),
              onPressed: _share,
              icon: const Icon(Icons.ios_share_rounded, size: 16),
              label: const Text("Share"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share() async {
    final Uint8List bytes = await _doc;
    await Printing.sharePdf(bytes: bytes, filename: "orcamento_${widget.quoteId}.pdf");
  }
}
