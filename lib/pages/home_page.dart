import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/empty_panel.dart";
import "package:delforte/design_system/widgets/quote_card_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class HomePage extends StatelessWidget {
  const HomePage({required this.store, required this.router, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([store.clientsNotifier, store.quotesNotifier]),
      builder: (context, _) {
        final List<QuoteSummary> quotes = store.listRecentQuotes(limit: 3);
        return AppShell(
          body: Column(
            children: [
              _BrandHeader(onSettings: () => router.goTo(const SettingsRoute())),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -16),
                      child: _NewQuoteCard(
                        onTap: () => router.goTo(const QuoteFlowRoute(QuoteStep.client)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionTitle(
                      title: "Recent Quotes",
                      action: "See all",
                      onAction: () => router.goTo(const QuotesListRoute()),
                    ),
                    const SizedBox(height: 12),
                    if (quotes.isEmpty)
                      const EmptyPanel(
                        icon: Icons.receipt_long_rounded,
                        title: "No quotes yet",
                        subtitle: "Start a new quote — drafts and saved quotes appear here.",
                      )
                    else
                      for (final QuoteSummary quote in quotes) _quoteCard(quote),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quoteCard(QuoteSummary quote) {
    return QuoteCard(
      clientName: _clientNameById(quote.clientId),
      meta: "${quote.serviceCount} services · ${quote.equipmentCount} equipment",
      total: formatMoney(quote.totalCents),
      status: quote.isDraft ? "Draft" : "Saved",
      statusColor: quote.isDraft ? VigilColors.textMuted : VigilColors.success,
      statusBg: quote.isDraft ? VigilColors.canvas : VigilColors.successSoft,
      // Drafts resume into the editable flow; saved quotes open their PDF.
      onTap: quote.isDraft
          ? () => router.goTo(QuoteFlowRoute(QuoteStep.services, draftId: quote.id))
          : () => router.goTo(PdfPreviewRoute(quote.id, back: const HomeRoute())),
    );
  }

  String _clientNameById(int id) {
    return store.clientById(id)?.name ?? "Unknown client";
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VigilColors.ink,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Delforte",
              style: TextStyle(
                color: VigilColors.surface,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
            IconButton(
              onPressed: onSettings,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.07),
                foregroundColor: Colors.white.withValues(alpha: 0.60),
                fixedSize: const Size(36, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              icon: const Icon(Icons.settings_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewQuoteCard extends StatelessWidget {
  const _NewQuoteCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: VigilRadius.featureRadius,
      child: Material(
        color: Colors.transparent,
        borderRadius: VigilRadius.featureRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: VigilGradients.primaryAction,
            boxShadow: VigilShadow.primaryLift,
          ),
          child: InkWell(
            borderRadius: VigilRadius.featureRadius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "New Quote",
                          style: VigilType.title(color: VigilColors.surface, size: 19),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Build a quote step by step",
                          style: VigilType.small(
                            color: Colors.white.withValues(alpha: 0.70),
                            size: 12,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: VigilRadius.cardRadius,
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action, required this.onAction});

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    const FontWeight weight = FontWeight.w800;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: VigilType.body(color: VigilColors.textPrimary, size: 14, weight: weight),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
    );
  }
}
