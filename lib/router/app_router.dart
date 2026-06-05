import "package:delforte/pages/catalog_page.dart";
import "package:delforte/pages/client_create_page.dart";
import "package:delforte/pages/client_select_page.dart";
import "package:delforte/pages/clients_page.dart";
import "package:delforte/pages/equipment_create_page.dart";
import "package:delforte/pages/equipment_page.dart";
import "package:delforte/pages/home_page.dart";
import "package:delforte/pages/pdf_preview_page.dart";
import "package:delforte/pages/quotes_list_page.dart";
import "package:delforte/pages/review_page.dart";
import "package:delforte/pages/send_page.dart";
import "package:delforte/pages/service_create_page.dart";
import "package:delforte/pages/services_page.dart";
import "package:delforte/pages/settings_page.dart";
import "package:delforte/pages/templates_page.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";

class AppRouterDelegate extends RouterDelegate<AppRoute> with ChangeNotifier {
  AppRouterDelegate({required this.store});

  final QuoteStore store;

  AppRoute _currentRoute = const HomeRoute();

  void goTo(AppRoute route) {
    _currentRoute = route;
    notifyListeners();
  }

  @override
  AppRoute get currentConfiguration => _currentRoute;

  @override
  Widget build(BuildContext context) {
    return switch (_currentRoute) {
      HomeRoute() => HomePage(store: store, router: this),
      QuoteFlowRoute(:final QuoteStep step, :final int? draftId) => _buildQuoteFlow(step, draftId),
      ClientCreateRoute(:final int? draftId, :final AppRoute? back) => ClientCreatePage(
        store: store,
        router: this,
        draftId: draftId,
        back: back,
      ),
      ClientsRoute() => ClientsPage(store: store, router: this),
      ServiceCreateRoute(:final int? draftId) => ServiceCreatePage(
        store: store,
        router: this,
        draftId: draftId,
      ),
      EquipmentCreateRoute(:final int? draftId) => EquipmentCreatePage(
        store: store,
        router: this,
        draftId: draftId,
      ),
      QuotesListRoute() => QuotesListPage(store: store, router: this),
      CatalogRoute() => CatalogPage(store: store, router: this),
      PdfPreviewRoute(:final int quoteId, :final AppRoute back) => PdfPreviewPage(
        store: store,
        router: this,
        quoteId: quoteId,
        back: back,
      ),
      TemplatesRoute() => TemplatesPage(router: this),
      SettingsRoute() => SettingsPage(store: store, router: this),
    };
  }

  Widget _buildQuoteFlow(QuoteStep step, int? draftId) {
    return switch (step) {
      QuoteStep.client => ClientSelectPage(store: store, router: this, draftId: draftId),
      QuoteStep.services => ServicesPage(store: store, router: this, draftId: draftId ?? 0),
      QuoteStep.equipment => EquipmentPage(store: store, router: this, draftId: draftId ?? 0),
      QuoteStep.review => ReviewPage(store: store, router: this, draftId: draftId ?? 0),
      QuoteStep.send => SendPage(store: store, router: this, draftId: draftId ?? 0),
    };
  }

  @override
  Future<void> setNewRoutePath(AppRoute configuration) async {
    _currentRoute = configuration;
    notifyListeners();
  }

  @override
  Future<bool> popRoute() {
    switch (_currentRoute) {
      case HomeRoute():
        return Future.value(false);
      case QuoteFlowRoute(:final QuoteStep step, :final int? draftId):
        final QuoteStep? previous = step.previous;
        if (previous == null) {
          if (draftId != null) store.deleteDraftIfEmpty(draftId);
          _currentRoute = const HomeRoute();
        } else {
          _currentRoute = QuoteFlowRoute(previous, draftId: draftId);
        }
        notifyListeners();
        return Future.value(true);
      case ClientCreateRoute(:final int? draftId, :final AppRoute? back):
        _currentRoute = back ?? QuoteFlowRoute(QuoteStep.client, draftId: draftId);
        notifyListeners();
        return Future.value(true);
      case ServiceCreateRoute(:final int? draftId):
        _currentRoute = draftId == null
            ? const CatalogRoute()
            : QuoteFlowRoute(QuoteStep.services, draftId: draftId);
        notifyListeners();
        return Future.value(true);
      case EquipmentCreateRoute(:final int? draftId):
        _currentRoute = draftId == null
            ? const CatalogRoute()
            : QuoteFlowRoute(QuoteStep.equipment, draftId: draftId);
        notifyListeners();
        return Future.value(true);
      case PdfPreviewRoute(:final AppRoute back):
        _currentRoute = back;
        notifyListeners();
        return Future.value(true);
      case QuotesListRoute():
      case CatalogRoute():
      case ClientsRoute():
      case TemplatesRoute():
      case SettingsRoute():
        _currentRoute = const HomeRoute();
        notifyListeners();
        return Future.value(true);
    }
  }
}
