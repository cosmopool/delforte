import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/empty_panel.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/quote_card_widget.dart";
import "package:delforte/design_system/widgets/search_field_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class QuotesListPage extends StatefulWidget {
  const QuotesListPage({required this.store, required this.router, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;

  @override
  State<QuotesListPage> createState() => _QuotesListPageState();
}

class _QuotesListPageState extends State<QuotesListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<QuoteSummary> quotes = [
      for (final QuoteSummary quote in widget.store.listQuotes())
        if (query.isEmpty || _clientNameById(quote.clientId).toLowerCase().contains(query)) quote,
    ];

    return AppShell(
      body: Column(
        children: [
          FlowHeader(title: strings.quotes, onBack: () => widget.router.goTo(const HomeRoute())),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SearchField(
                  controller: _searchController,
                  hintText: strings.searchQuotes,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                if (quotes.isEmpty)
                  EmptyPanel(
                    icon: Icons.receipt_long_rounded,
                    title: strings.noQuotesFound,
                    subtitle: strings.noQuotesFoundSubtitle,
                  )
                else
                  for (final QuoteSummary quote in quotes)
                    QuoteCard(
                      clientName: _clientNameById(quote.clientId),
                      meta: strings.quoteMeta(quote.serviceCount, quote.equipmentCount),
                      total: formatMoney(quote.totalCents),
                      status: quote.isDraft ? strings.statusDraft : strings.statusSaved,
                      statusColor: quote.isDraft ? VigilColors.textMuted : VigilColors.success,
                      statusBg: quote.isDraft ? VigilColors.canvas : VigilColors.successSoft,
                      onTap: quote.isDraft
                          ? () => widget.router.goTo(
                              QuoteFlowRoute(QuoteStep.services, draftId: quote.id),
                            )
                          : null,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _clientNameById(int id) {
    return widget.store.clientById(id)?.name ?? strings.unknownClient;
  }
}
