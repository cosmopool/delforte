import "dart:io";

import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/destructive_icon_button.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync("repro_r1_3_"));
  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  testWidgets(
    "a draft whose client was deleted still continues from the client step to Serviços",
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final QuoteStore store = QuoteStore(databasePath: "${directory.path}/quotes.sqlite");
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
      expect(store.addClient("Casa Joao Silva", "", "", "Rua A, 1", ""), isTrue);
      await tester.pumpAndSettle();

      // 1. Create a draft with the client, then go back to Home.
      await tester.tap(find.text(strings.newQuote));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Casa Joao Silva"));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.continueLabel));
      await tester.pumpAndSettle();
      expect(find.text(strings.selectClient), findsNothing);
      await tester.tap(find.byTooltip(strings.back));
      await tester.pumpAndSettle();
      expect(find.text(strings.selectClient), findsOneWidget);
      await tester.tap(find.byTooltip(strings.back));
      await tester.pumpAndSettle();
      expect(find.text(strings.newQuote), findsOneWidget);

      // 2. Delete the client in Clientes.
      await tester.tap(find.text(strings.clients));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Casa Joao Silva"));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(DestructiveIconButton));
      await tester.tap(find.byType(DestructiveIconButton));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, strings.delete));
      await tester.pumpAndSettle();
      expect(store.listClients(), isEmpty);
      await tester.tap(find.byTooltip(strings.back));
      await tester.pumpAndSettle();

      // 3. Open the draft from Home (services step) and go back to the client step.
      await tester.tap(find.text("Casa Joao Silva"));
      await tester.pumpAndSettle();
      expect(find.text(strings.selectClient), findsNothing);
      await tester.tap(find.byTooltip(strings.back));
      await tester.pumpAndSettle();
      expect(find.text(strings.selectClient), findsOneWidget);

      // 4. Continuar must reach Serviços without an error, keeping the client copy.
      await tester.tap(find.text(strings.continueLabel));
      await tester.pumpAndSettle();
      expect(find.textContaining("NOT NULL"), findsNothing);
      expect(find.text(strings.selectClient), findsNothing);
      final int draftId = store.listRecentQuotes().single.id;
      expect(store.quoteClient(draftId)?.name, "Casa Joao Silva");
    },
  );
}
