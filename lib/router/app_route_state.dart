sealed class AppRoute {
  const AppRoute();
}

class HomeRoute extends AppRoute {
  const HomeRoute();
}

class QuoteFlowRoute extends AppRoute {
  const QuoteFlowRoute(this.step, {this.draftId});

  /// The draft quote being edited, or `null` at the initial client step of a
  /// brand-new quote (the draft is created lazily once a client is chosen).
  final QuoteStep step;
  final int? draftId;
}

class ClientCreateRoute extends AppRoute {
  const ClientCreateRoute({this.draftId});
  final int? draftId;
}

class ServiceCreateRoute extends AppRoute {
  const ServiceCreateRoute({this.draftId});
  final int? draftId;
}

class EquipmentCreateRoute extends AppRoute {
  const EquipmentCreateRoute({this.draftId});
  final int? draftId;
}

class QuotesListRoute extends AppRoute {
  const QuotesListRoute();
}

class PdfPreviewRoute extends AppRoute {
  const PdfPreviewRoute(this.quoteId, {this.back = const HomeRoute()});

  /// The quote being rendered to PDF.
  final int quoteId;

  /// Where back navigation returns to (the screen the PDF was opened from).
  final AppRoute back;
}

class TemplatesRoute extends AppRoute {
  const TemplatesRoute();
}

class SettingsRoute extends AppRoute {
  const SettingsRoute();
}

enum QuoteStep { client, services, equipment, review, send }

extension QuoteStepX on QuoteStep {
  int get index => switch (this) {
    QuoteStep.client => 0,
    QuoteStep.services => 1,
    QuoteStep.equipment => 2,
    QuoteStep.review => 3,
    QuoteStep.send => 4,
  };

  String get label => switch (this) {
    QuoteStep.client => "Client",
    QuoteStep.services => "Services",
    QuoteStep.equipment => "Equipment",
    QuoteStep.review => "Review",
    QuoteStep.send => "Send",
  };

  QuoteStep? get previous => switch (this) {
    QuoteStep.client => null,
    QuoteStep.services => QuoteStep.client,
    QuoteStep.equipment => QuoteStep.services,
    QuoteStep.review => QuoteStep.equipment,
    QuoteStep.send => QuoteStep.review,
  };

  QuoteStep? get next => switch (this) {
    QuoteStep.client => QuoteStep.services,
    QuoteStep.services => QuoteStep.equipment,
    QuoteStep.equipment => QuoteStep.review,
    QuoteStep.review => QuoteStep.send,
    QuoteStep.send => null,
  };
}
