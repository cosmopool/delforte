import "dart:io";

import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/destructive_icon_button.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/pages/services_page.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  late Directory directory;
  late String path;

  setUp(() {
    directory = Directory.systemTemp.createTempSync("repro_r1_5_");
    path = "${directory.path}/quotes.sqlite";
  });
  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  testWidgets(
    "AC-9 a draft whose client was deleted continues past the client step with its copied client",
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);
      final AppRouterDelegate router = AppRouterDelegate(store: store);
      addTearDown(router.dispose);
      router.goTo(const HomeRoute());
      await tester.pumpWidget(
        MaterialApp(
          theme: VigilTheme.light(),
          home: Router<AppRoute>(routerDelegate: router),
        ),
      );
      expect(store.addClient("Residencial Oliveira", "", "", "Rua das Flores, 142", ""), isTrue);
      await tester.pumpAndSettle();

      // Start a quote, pick the client, reach services.
      await tester.tap(find.text(strings.newQuote));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Residencial Oliveira"));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.continueLabel));
      await tester.pumpAndSettle();
      expect(find.byType(ServicesPage), findsOneWidget);
      final int draftId = store.listQuotes().single.id;

      // Leave to Home; the draft stays because it has a client. Delete the client in Clientes.
      router.goTo(const ClientsRoute());
      await tester.pumpAndSettle();
      await tester.tap(find.text("Residencial Oliveira"));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DestructiveIconButton));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, strings.delete));
      await tester.pumpAndSettle();
      expect(store.listClients(), isEmpty);
      expect(store.quoteClient(draftId)?.name, "Residencial Oliveira");

      // Reopen the draft and go back to the client step, as Review's edit-client button does.
      router.goTo(QuoteFlowRoute(QuoteStep.client, draftId: draftId));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.continueLabel));
      await tester.pumpAndSettle();

      expect(find.textContaining("NOT NULL constraint failed"), findsNothing);
      expect(find.byType(ServicesPage), findsOneWidget);
      expect(store.quoteClient(draftId)?.name, "Residencial Oliveira");
    },
  );
}
