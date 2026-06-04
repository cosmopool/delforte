import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/initials_avatar_widget.dart";
import "package:delforte/design_system/widgets/line_group_widget.dart";
import "package:delforte/design_system/widgets/panel_widget.dart";
import "package:delforte/design_system/widgets/total_banner_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class ReviewPage extends StatelessWidget {
  const ReviewPage({required this.store, required this.router, required this.draftId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int draftId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store.quotesNotifier,
      builder: (BuildContext context, Widget? _) {
        final List<QuoteLine> lines = store.listQuoteLines(draftId);
        final int total = store.quoteTotal(draftId);
        final Client? client = store.clientById(store.draftClientId(draftId));
        const FontWeight weight = FontWeight.w700;
        const Color color = VigilColors.textSecondary;
        return AppShell(
          body: Column(
            children: [
              FlowHeader(
                title: strings.review,
                stepIndex: 3,
                continueLabel: strings.looksGood,
                onBack: () => router.goTo(QuoteFlowRoute(QuoteStep.equipment, draftId: draftId)),
                onContinue: (client != null && lines.isNotEmpty)
                    ? () => _saveAndContinue(context)
                    : null,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Panel(
                      title: strings.client,
                      child: Row(
                        children: [
                          InitialsAvatar(
                            text: client != null ? initials(client.name) : "--",
                            selected: false,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client?.name ?? strings.noClientSelected,
                                  style: VigilType.body(
                                    color: VigilColors.textPrimary,
                                    size: 14,
                                    weight: weight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  client?.address ?? strings.returnToClientStep,
                                  style: VigilType.small(
                                    color: color,
                                    size: 11,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: strings.editClient,
                            onPressed: () =>
                                router.goTo(QuoteFlowRoute(QuoteStep.client, draftId: draftId)),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    LineGroup(
                      title: strings.services,
                      lines: _lineViews(lines, .service),
                      onEdit: () =>
                          router.goTo(QuoteFlowRoute(QuoteStep.services, draftId: draftId)),
                    ),
                    const SizedBox(height: 10),
                    LineGroup(
                      title: strings.equipment,
                      lines: _lineViews(lines, .equipment),
                      onEdit: () =>
                          router.goTo(QuoteFlowRoute(QuoteStep.equipment, draftId: draftId)),
                    ),
                    const SizedBox(height: 10),
                    TotalBanner(label: strings.total, amount: formatMoney(total)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveAndContinue(BuildContext context) {
    if (!store.finalizeDraft(draftId)) {
      final String message = store.latestErrorMessage();
      if (message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }
    router.goTo(QuoteFlowRoute(QuoteStep.send, draftId: draftId));
  }

  List<DraftLineView> _lineViews(List<QuoteLine> lines, CatalogItemType type) {
    return [
      for (final QuoteLine line in lines)
        if (line.type == type)
          DraftLineView(
            name: line.name,
            quantity: line.quantity,
            subtotal: formatMoney(line.subtotalCents),
          ),
    ];
  }
}
