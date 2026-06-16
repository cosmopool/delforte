import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/empty_panel.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/quote_card_widget.dart";
import "package:delforte/l10n/localization.dart";
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
              // Pulled up to float over the header's bottom edge.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Transform.translate(
                  offset: const Offset(0, -16),
                  child: _NewQuoteCard(
                    onTap: () => router.goTo(const QuoteFlowRoute(QuoteStep.client)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      _QuickActions(router: router),
                      const SizedBox(height: 12),
                      _SectionTitle(
                        title: strings.recentQuotes,
                        action: strings.seeAll,
                        onAction: () => router.goTo(const QuotesListRoute()),
                      ),
                      const SizedBox(height: 12),
                      if (quotes.isEmpty)
                        EmptyPanel(
                          icon: Icons.receipt_long_rounded,
                          title: strings.noQuotesYet,
                          subtitle: strings.noQuotesYetSubtitle,
                        )
                      else
                        for (final QuoteSummary quote in quotes) _quoteCard(quote),
                    ],
                  ),
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
      meta: strings.quoteMeta(quote.serviceCount, quote.equipmentCount),
      total: formatMoney(quote.totalCents),
      status: quote.isDraft ? strings.statusDraft : strings.statusSaved,
      statusColor: quote.isDraft ? VigilColors.textMuted : VigilColors.success,
      statusBg: quote.isDraft ? VigilColors.canvas : VigilColors.successSoft,
      // Drafts resume into the editable flow; saved quotes open their PDF.
      onTap: quote.isDraft
          ? () => router.goTo(QuoteFlowRoute(QuoteStep.services, draftId: quote.id))
          : () => router.goTo(PdfPreviewRoute(quote.id, back: const HomeRoute())),
    );
  }

  String _clientNameById(int id) {
    return store.clientById(id)?.name ?? strings.unknownClient;
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
            Expanded(
              child: HeaderFittedText(
                text: strings.appName,
                style: VigilType.title(color: VigilColors.surface, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: onSettings,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.07),
                foregroundColor: Colors.white.withValues(alpha: 0.60),
                fixedSize: const Size(36, 36),
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                          strings.newQuote,
                          style: VigilType.title(color: VigilColors.surface, size: 19),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.newQuoteSubtitle,
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.router});

  final AppRouterDelegate router;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.people_alt_rounded,
            label: strings.clients,
            subtitle: strings.clientsSubtitle,
            onTap: () => router.goTo(const ClientsRoute()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.layers_rounded,
            label: strings.templates,
            subtitle: strings.templatesSubtitle,
            onTap: () => router.goTo(const TemplatesRoute()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.inventory_2_rounded,
            label: strings.catalog,
            subtitle: strings.catalogSubtitle,
            onTap: () => router.goTo(const CatalogRoute()),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VigilColors.surface,
      borderRadius: VigilRadius.cardRadius,
      child: InkWell(
        borderRadius: VigilRadius.cardRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: VigilRadius.cardRadius,
            border: Border.all(color: VigilColors.border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VigilIconBox(
                icon: icon,
                color: VigilColors.textSecondary,
                background: VigilColors.canvas,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: VigilType.body(
                  color: VigilColors.textPrimary,
                  size: 14,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VigilType.small(
                  color: VigilColors.textMuted,
                  size: 11,
                  weight: FontWeight.w500,
                ),
              ),
            ],
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
        TextButton(
          onPressed: onAction,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(action),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 15),
            ],
          ),
        ),
      ],
    );
  }
}
