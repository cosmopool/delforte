import "dart:io";

import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/destructive_icon_button.dart";
import "package:delforte/design_system/widgets/round_button_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync("repro_r1_1_"));
  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  testWidgets(
    "AC-18 D-20 a draft line whose catalog item was deleted still shows on its wizard step and can be removed",
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
      expect(store.addClient("Residencial Oliveira", "", "", "Rua das Flores, 142", ""), isTrue);
      expect(store.addService("Instalação de câmeras", "Por ponto", 28000), isTrue);
      await tester.pumpAndSettle();

      // 1. New quote: pick the client, add the service on the services step.
      await tester.tap(find.text(strings.newQuote));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Residencial Oliveira"));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.continueLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), "instal");
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.tap(find.text("Instalação de câmeras"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(RoundButton, Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.text("Instalação de câmeras"), findsOneWidget);

      // 2. Go Home; the draft stays. 3. Delete the service in Catálogo.
      router.goTo(const HomeRoute());
      await tester.pumpAndSettle();
      router.goTo(const CatalogRoute());
      await tester.pumpAndSettle();
      await tester.tap(find.text("Instalação de câmeras"));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DestructiveIconButton));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, strings.delete));
      await tester.pumpAndSettle();
      expect(store.listCatalog(.service), isEmpty);

      // 4. Open the draft from Home; it resumes on the services step.
      router.goTo(const HomeRoute());
      await tester.pumpAndSettle();
      await tester.tap(find.text("Residencial Oliveira"));
      await tester.pumpAndSettle();

      // The header counts the kept line...
      expect(find.text(formatMoney(28000)), findsWidgets);
      // ...so the step must show it, with its own copy, and let the user remove it.
      expect(find.text("Instalação de câmeras"), findsOneWidget);
      await tester.tap(find.text("Instalação de câmeras"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(RoundButton, Icons.remove_rounded));
      await tester.pumpAndSettle();
      final int draftId = store.listQuotes().single.id;
      expect(store.quoteSubtotal(draftId, .service), 0);
    },
  );
}
