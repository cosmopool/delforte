import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/initials_avatar_widget.dart";
import "package:delforte/design_system/widgets/line_group_widget.dart";
import "package:delforte/design_system/widgets/panel_widget.dart";
import "package:delforte/design_system/widgets/total_banner_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class ReviewPage extends StatelessWidget {
  const ReviewPage({required this.store, required this.router, this.selectedClientId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int? selectedClientId;

  @override
  Widget build(BuildContext context) {
    final int total = store.draft.computeTotals();
    final int clientIndex = selectedClientId == null
        ? -1
        : store.clients.indexOfId(selectedClientId!);

    return AppShell(
      body: (int total, int clientIndex) {
        const FontWeight weight = FontWeight.w700;
        const Color color = VigilColors.textSecondary;
        return Column(
          children: [
            FlowHeader(
              title: "Review",
              stepIndex: 3,
              continueLabel: "Looks Good",
              onBack: () =>
                  router.goTo(QuoteFlowRoute(QuoteStep.equipment, selectedClientId: selectedClientId)),
              onContinue: _canSaveQuote ? () => _saveAndContinue(total) : null,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Panel(
                    title: "Client",
                    child: Row(
                      children: [
                        InitialsAvatar(
                          text: clientIndex >= 0
                              ? initials(store.clients.nameAt(clientIndex))
                              : "--",
                          selected: false,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientIndex >= 0
                                    ? store.clients.nameAt(clientIndex)
                                    : "No client selected",
                                style: VigilType.body(
                                  color: VigilColors.textPrimary,
                                  size: 14,
                                  weight: weight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                clientIndex >= 0
                                    ? store.clients.addressAt(clientIndex)
                                    : "Return to client step",
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
                          tooltip: "Edit client",
                          onPressed: () => router.goTo(
                            QuoteFlowRoute(QuoteStep.client, selectedClientId: selectedClientId),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  LineGroup(
                    title: "Services",
                    lines: _draftLines(.service),
                    onEdit: () => router.goTo(
                      QuoteFlowRoute(QuoteStep.services, selectedClientId: selectedClientId),
                    ),
                  ),
                  const SizedBox(height: 10),
                  LineGroup(
                    title: "Equipment",
                    lines: _draftLines(.equipment),
                    onEdit: () => router.goTo(
                      QuoteFlowRoute(QuoteStep.equipment, selectedClientId: selectedClientId),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TotalBanner(label: "Total", amount: formatMoney(total)),
                ],
              ),
            ),
          ],
        );
      }(total, clientIndex),
    );
  }

  bool get _canSaveQuote => selectedClientId != null && store.draft.count > 0;

  void _saveAndContinue(int total) {
    if (selectedClientId == null) return;
    final bool saved = store.saveQuote(selectedClientId!);
    if (!saved) {
      // Show error - but we're in a StatelessWidget, need context
      return;
    }
    router.goTo(QuoteFlowRoute(QuoteStep.send, selectedClientId: selectedClientId));
  }

  List<DraftLineView> _draftLines(CatalogItemType type) {
    return [
      for (var i = 0; i < store.draft.count; i++)
        if (store.draft.types[i] == type.index)
          DraftLineView(
            name: store.nameFor(type, store.draft.refIds[i]),
            quantity: store.draft.quantities[i],
            subtotal: formatMoney(store.draft.subtotalCents[i]),
          ),
    ];
  }
}
