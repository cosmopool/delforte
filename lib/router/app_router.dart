import "package:delforte/pages/client_select_page.dart";
import "package:delforte/pages/home_page.dart";
import "package:delforte/pages/items_page.dart";
import "package:delforte/pages/quotes_list_page.dart";
import "package:delforte/pages/review_page.dart";
import "package:delforte/pages/send_page.dart";
import "package:delforte/pages/services_page.dart";
import "package:delforte/pages/templates_page.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/store.dart";
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
      QuoteFlowRoute(:final QuoteStep step, :final int? selectedClientId) => _buildQuoteFlow(
        step,
        selectedClientId,
      ),
      QuotesListRoute() => QuotesListPage(store: store, router: this),
      TemplatesRoute() => TemplatesPage(router: this),
    };
  }

  Widget _buildQuoteFlow(QuoteStep step, int? selectedClientId) {
    return switch (step) {
      QuoteStep.client => ClientSelectPage(
        store: store,
        router: this,
        selectedClientId: selectedClientId,
      ),
      QuoteStep.services => ServicesPage(
        store: store,
        router: this,
        selectedClientId: selectedClientId,
      ),
      QuoteStep.items => ItemsPage(store: store, router: this, selectedClientId: selectedClientId),
      QuoteStep.review => ReviewPage(
        store: store,
        router: this,
        selectedClientId: selectedClientId,
      ),
      QuoteStep.send => SendPage(store: store, router: this, selectedClientId: selectedClientId),
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
      case QuoteFlowRoute(:final QuoteStep step, :final int? selectedClientId):
        final QuoteStep? previous = step.previous;
        if (previous == null) {
          _currentRoute = const HomeRoute();
        } else {
          _currentRoute = QuoteFlowRoute(previous, selectedClientId: selectedClientId);
        }
        notifyListeners();
        return Future.value(true);
      case QuotesListRoute():
      case TemplatesRoute():
        _currentRoute = const HomeRoute();
        notifyListeners();
        return Future.value(true);
    }
  }
}
