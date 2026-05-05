import "dart:io";

import "package:delforte/design_system.dart";
import "package:delforte/pages/catalog_create_page.dart";
import "package:delforte/store.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("CatalogCreateBody", () {
    late Directory directory;
    late String path;

    setUp(() {
      directory = Directory.systemTemp.createTempSync("catalog_create_page_test_");
      path = "${directory.path}/quotes.sqlite";
    });

    tearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    testWidgets("saves a service, adds it to the draft, and returns", (tester) async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);

      var saved = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: VigilTheme.light(),
          home: Scaffold(
            body: CatalogCreateBody(
              store: store,
              isService: true,
              onBack: () {},
              onSaved: () => saved++,
            ),
          ),
        ),
      );

      await tester.enterText(find.widgetWithText(TextField, "Name"), "Rack install");
      await tester.enterText(find.widgetWithText(TextField, "Description"), "Wall mount");
      await tester.enterText(find.widgetWithText(TextField, "Price"), "250,00");
      await tester.tap(find.text("Save and Add to Quote"));
      await tester.pump();

      expect(saved, 1);
      expect(store.services.count, 1);
      expect(store.services.nameAt(0), "Rack install");
      expect(store.draft.count, 1);
      expect(store.draft.types[0], quoteLineService);
      expect(store.draft.refIds[0], store.services.idAt(0));
      expect(store.draft.quantities[0], 1);
      expect(store.draft.subtotalCents[0], 25000);
    });

    testWidgets("saves equipment, adds it to the draft, and returns", (tester) async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);

      var saved = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: VigilTheme.light(),
          home: Scaffold(
            body: CatalogCreateBody(
              store: store,
              isService: false,
              onBack: () {},
              onSaved: () => saved++,
            ),
          ),
        ),
      );

      await tester.enterText(find.widgetWithText(TextField, "Name"), "Outdoor camera");
      await tester.enterText(find.widgetWithText(TextField, "Description"), "4MP infrared");
      await tester.enterText(find.widgetWithText(TextField, "Price"), "350,00");
      await tester.tap(find.text("Save and Add to Quote"));
      await tester.pump();

      expect(saved, 1);
      expect(store.items.count, 1);
      expect(store.items.nameAt(0), "Outdoor camera");
      expect(store.draft.count, 1);
      expect(store.draft.types[0], quoteLineItem);
      expect(store.draft.refIds[0], store.items.idAt(0));
      expect(store.draft.quantities[0], 1);
      expect(store.draft.subtotalCents[0], 35000);
    });
  });
}
