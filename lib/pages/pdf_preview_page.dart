import "dart:typed_data";

import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/l10n/localization.dart";
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

  Future<void> _share() async {
    final Uint8List bytes = await _doc;
    await Printing.sharePdf(bytes: bytes, filename: "orcamento_${widget.quoteId}.pdf");
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: Column(
        children: [
          ColoredBox(
            color: VigilColors.ink,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(
                children: [
                  HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: strings.back,
                    onPressed: () => widget.router.goTo(widget.back),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.pdfPreview,
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
                    label: Text(strings.share),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (_) => _doc,
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
                borderRadius: BorderRadius.circular(16),
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
