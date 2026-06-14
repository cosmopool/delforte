import "package:delforte/design_system/widgets/quote_catalog_step_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";

class ServicesPage extends StatelessWidget {
  const ServicesPage({required this.store, required this.router, required this.draftId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int draftId;

  @override
  Widget build(BuildContext context) {
    return QuoteCatalogStep(
      store: store,
      draftId: draftId,
      type: .service,
      onBack: () => router.goTo(QuoteFlowRoute(QuoteStep.client, draftId: draftId)),
      onContinue: () => router.goTo(QuoteFlowRoute(QuoteStep.equipment, draftId: draftId)),
      onCreate: () => router.goTo(ServiceCreateRoute(draftId: draftId)),
    );
  }
}
