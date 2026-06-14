import "package:delforte/design_system/widgets/quote_catalog_step_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";

class EquipmentPage extends StatelessWidget {
  const EquipmentPage({
    required this.store,
    required this.router,
    required this.draftId,
    super.key,
  });

  final QuoteStore store;
  final AppRouterDelegate router;
  final int draftId;

  @override
  Widget build(BuildContext context) {
    return QuoteCatalogStep(
      store: store,
      draftId: draftId,
      type: .equipment,
      onBack: () => router.goTo(QuoteFlowRoute(QuoteStep.services, draftId: draftId)),
      onContinue: () => router.goTo(QuoteFlowRoute(QuoteStep.review, draftId: draftId)),
      onCreate: () => router.goTo(EquipmentCreateRoute(draftId: draftId)),
    );
  }
}
