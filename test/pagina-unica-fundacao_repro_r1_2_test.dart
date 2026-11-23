import "dart:io";

import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/round_button_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync("repro_r1_2_"));
  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  testWidgets(
    "D-20 going back from Enviar to Revisar and pressing Looks good again returns to Enviar",
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

      // 1. Pick a client, add a service, skip equipment, press "Looks good".
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
      await tester.tap(find.text(strings.continueLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.continueLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.looksGood));
      await tester.pumpAndSettle();
      expect(find.text(strings.exportPdf), findsOneWidget);

      // 2. Back from Enviar lands on Revisar.
      await tester.tap(find.byTooltip(strings.back));
      await tester.pumpAndSettle();
      expect(find.text(strings.looksGood), findsOneWidget);

      // 3. "Looks good" again must reach Enviar, with no error SnackBar.
      await tester.tap(find.text(strings.looksGood));
      await tester.pumpAndSettle();
      expect(find.text("Quote is not a draft"), findsNothing);
      expect(find.text(strings.exportPdf), findsOneWidget);
    },
  );
}
