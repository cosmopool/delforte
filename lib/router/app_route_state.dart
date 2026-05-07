sealed class AppRoute {
  const AppRoute();
}

class HomeRoute extends AppRoute {
  const HomeRoute();
}

class QuoteFlowRoute extends AppRoute {
  const QuoteFlowRoute(this.step, {this.selectedClientId});
  final QuoteStep step;
  final int? selectedClientId;
}

class ClientCreateRoute extends AppRoute {
  const ClientCreateRoute({this.selectedClientId});
  final int? selectedClientId;
}

class ServiceCreateRoute extends AppRoute {
  const ServiceCreateRoute({this.selectedClientId});
  final int? selectedClientId;
}

class ItemCreateRoute extends AppRoute {
  const ItemCreateRoute({this.selectedClientId});
  final int? selectedClientId;
}

class QuotesListRoute extends AppRoute {
  const QuotesListRoute();
}

class TemplatesRoute extends AppRoute {
  const TemplatesRoute();
}

enum QuoteStep { client, services, items, review, send }

extension QuoteStepX on QuoteStep {
  int get index => switch (this) {
    QuoteStep.client => 0,
    QuoteStep.services => 1,
    QuoteStep.items => 2,
    QuoteStep.review => 3,
    QuoteStep.send => 4,
  };

  String get label => switch (this) {
    QuoteStep.client => "Client",
    QuoteStep.services => "Services",
    QuoteStep.items => "Items",
    QuoteStep.review => "Review",
    QuoteStep.send => "Send",
  };

  QuoteStep? get previous => switch (this) {
    QuoteStep.client => null,
    QuoteStep.services => QuoteStep.client,
    QuoteStep.items => QuoteStep.services,
    QuoteStep.review => QuoteStep.items,
    QuoteStep.send => QuoteStep.review,
  };

  QuoteStep? get next => switch (this) {
    QuoteStep.client => QuoteStep.services,
    QuoteStep.services => QuoteStep.items,
    QuoteStep.items => QuoteStep.review,
    QuoteStep.review => QuoteStep.send,
    QuoteStep.send => null,
  };
}
