import "dart:io";
import "dart:typed_data";

import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/form_field_widget.dart";
import "package:delforte/design_system/widgets/round_button_widget.dart";
import "package:delforte/design_system/widgets/unit_dropdown_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/main.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/store/store_errors.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqlite3/sqlite3.dart";

void main() {
  late Directory directory;
  late String path;

  setUp(() {
    directory = Directory.systemTemp.createTempSync("app_test_");
    path = "${directory.path}/quotes.sqlite";
  });

  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  /// A phone-sized screen, an opened store and the app router showing [route].
  Future<(QuoteStore, AppRouterDelegate)> openApp(WidgetTester tester, AppRoute route) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final QuoteStore store = QuoteStore(databasePath: path);
    addTearDown(store.dispose);
    expect(await store.open(), isTrue);
    final AppRouterDelegate router = AppRouterDelegate(store: store);
    addTearDown(router.dispose);
    router.goTo(route);
    await tester.pumpWidget(
      MaterialApp(
        theme: VigilTheme.light(),
        home: Router<AppRoute>(routerDelegate: router),
      ),
    );
    return (store, router);
  }

  /// Lets real file I/O started by a handler finish, frame by frame.
  Future<void> settleIo(WidgetTester tester, Finder until) async {
    for (int i = 0; i < 50 && until.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
  }

  testWidgets("AC-20 the Catálogo service forms have no Unit field", (WidgetTester tester) async {
    final (QuoteStore store, AppRouterDelegate router) = await openApp(
      tester,
      const ServiceCreateRoute(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(UnitDropdownWidget), findsNothing);
    expect(find.text(strings.unit), findsNothing);

    await tester.enterText(
      find.descendant(
        of: find.widgetWithText(FormFieldWidget, strings.serviceName),
        matching: find.byType(TextField),
      ),
      "Instalação de câmeras",
    );
    await tester.tap(find.text(strings.saveService));
    await tester.pumpAndSettle();

    final CatalogItem created = store.listCatalog(.service).single;
    expect(created.name, "Instalação de câmeras");
    expect(created.unitId, 0);

    router.goTo(const CatalogRoute());
    await tester.pumpAndSettle();
    await tester.tap(find.text("Instalação de câmeras"));
    await tester.pumpAndSettle();
    expect(find.text(strings.defaultPrice), findsOneWidget);
    expect(find.byType(UnitDropdownWidget), findsNothing);
    expect(find.text(strings.unit), findsNothing);
  });

  testWidgets(
    "AC-103 the adapted wizard picks a client, adds lines, saves in Revisar and lists the quote as Salvo",
    (WidgetTester tester) async {
      final (QuoteStore store, AppRouterDelegate router) = await openApp(tester, const HomeRoute());
      expect(store.addClient("Residencial Oliveira", "", "", "Rua das Flores, 142", ""), isTrue);
      expect(store.addService("Instalação de câmeras", "Por ponto", 28000), isTrue);
      final int un = store.listUnits().firstWhere((Unit u) => u.abbreviation == "un").id;
      expect(store.addEquipment("Haste de canto", "", 3200, un), isTrue);
      await tester.pumpAndSettle();

      Future<void> addFromCatalog(String search, String name) async {
        await tester.enterText(find.byType(TextField), search);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithIcon(RoundButton, Icons.add_rounded));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text(strings.newQuote));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Residencial Oliveira"));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.continueLabel));
      await tester.pumpAndSettle();
      await addFromCatalog("instal", "Instalação de câmeras");
      await tester.tap(find.text(strings.continueLabel));
      await tester.pumpAndSettle();
      await addFromCatalog("haste", "Haste de canto");
      await tester.tap(find.text(strings.continueLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.looksGood));
      await tester.pumpAndSettle();

      final QuoteSummary saved = store.listQuotes().single;
      expect(saved.isDraft, isFalse);
      expect(saved.clientName, "Residencial Oliveira");
      expect(saved.totalCents, 28000 + 3200);
      final QuotePdfData pdf = store.quotePdfData(saved.id);
      expect(pdf.client?.name, "Residencial Oliveira");
      expect(pdf.client?.address, "Rua das Flores, 142");
      expect(pdf.lines.map((QuotePdfLine l) => l.name).toSet(), {
        "Instalação de câmeras",
        "Haste de canto",
      });

      router.goTo(const QuotesListRoute());
      await tester.pumpAndSettle();
      expect(find.text("Residencial Oliveira"), findsOneWidget);
      expect(
        find.textContaining(RegExp(strings.statusSaved, caseSensitive: false)),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    "AC-F3 importing a v1 backup in Configurações shows the older-version SnackBar and keeps the data",
    (WidgetTester tester) async {
      // A real backup, stamped as written by the v1 app.
      final QuoteStore source = QuoteStore(databasePath: "${directory.path}/source.sqlite");
      expect(await source.open(), isTrue);
      expect(source.addClient("Cliente do Backup", "", "", "", ""), isTrue);
      final Uint8List exported = (await tester.runAsync<Uint8List?>(source.exportBackupBytes))!;
      source.dispose();
      final String backupPath = "${directory.path}/old_backup.sqlite";
      File(backupPath).writeAsBytesSync(exported);
      final Database stamp = sqlite3.open(backupPath);
      stamp.execute("PRAGMA user_version = 1");
      stamp.close();
      final Uint8List backup = File(backupPath).readAsBytesSync();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel("miguelruivo.flutter.plugins.filepicker"),
        (MethodCall call) async => [
          {"name": "old_backup.sqlite", "path": null, "bytes": backup, "size": backup.length},
        ],
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel("miguelruivo.flutter.plugins.filepicker"),
          null,
        ),
      );

      final (QuoteStore store, AppRouterDelegate _) = await openApp(tester, const SettingsRoute());
      expect(store.addClient("Cliente Atual", "", "", "", ""), isTrue);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(strings.importBackupAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.importBackupAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.replaceBackup));
      await settleIo(tester, find.byType(SnackBar));

      expect(find.text(strings.backupTooOld), findsOneWidget);
      expect(find.text(strings.backupImportFailed), findsNothing);
      expect(store.errors.codeAt(store.errors.count - 1), errBackupTooOld);
      expect(store.listClients().single.name, "Cliente Atual");
    },
  );

  testWidgets(
    "AC-F4 when the database cannot be recreated the app shows the error screen and Tentar de novo recovers",
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      // A v1 database in the documents directory, held exclusively by another process.
      final String appPath = "${directory.path}/delforte_quotes.sqlite";
      final Database holder = sqlite3.open(appPath);
      holder.execute(
        "CREATE TABLE clients (id INTEGER PRIMARY KEY, name TEXT); PRAGMA user_version = 1;",
      );
      holder.execute("BEGIN EXCLUSIVE");
      holder.execute("INSERT INTO clients (name) VALUES ('Cliente Antigo')");
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel("plugins.flutter.io/path_provider"),
        (MethodCall call) async => directory.path,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel("plugins.flutter.io/path_provider"),
          null,
        ),
      );

      await tester.pumpWidget(const MainApp());
      await tester.pump();
      await tester.pump();

      expect(find.text(strings.tryAgain), findsOneWidget);
      expect(find.text(strings.newQuote), findsNothing);

      holder.execute("ROLLBACK");
      holder.close();
      await tester.tap(find.text(strings.tryAgain));
      await tester.pump();
      await tester.pump();

      expect(find.text(strings.tryAgain), findsNothing);
      expect(find.text(strings.newQuote), findsOneWidget);
    },
  );
}
