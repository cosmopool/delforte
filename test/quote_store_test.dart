import "dart:io";
import "dart:typed_data";

import "package:delforte/store/quote_store.dart";
import "package:delforte/store/store_errors.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("QuoteStore", () {
    late Directory directory;
    late String path;

    setUp(() {
      directory = Directory.systemTemp.createTempSync("quote_store_test_");
      path = "${directory.path}/quotes.sqlite";
    });

    tearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    Future<QuoteStore> openStore() async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);
      return store;
    }

    test("open creates an empty database", () async {
      final QuoteStore store = await openStore();
      expect(store.listClients(), isEmpty);
      expect(store.listCatalog(.equipment), isEmpty);
      expect(store.listCatalog(.service), isEmpty);
      expect(store.listQuotes(), isEmpty);
      expect(store.clientById(1), isNull);
      expect(store.errors.count, 0);
    });

    test("client CRUD round-trips through SQLite", () async {
      final QuoteStore store = await openStore();
      var notifies = 0;
      store.clientsNotifier.addListener(() => notifies++);

      expect(store.addClient("Alpha", "111", "a@x.com", "Rua A", "City A"), isTrue);
      expect(store.addClient("Beta", "222", "b@x.com", "Rua B", "City B"), isTrue);
      expect(store.listClients().length, 2);
      expect(store.listClients().first.name, "Beta"); // newest first
      expect(notifies, 2);

      final int alphaId = store.listClients().firstWhere((c) => c.name == "Alpha").id;
      expect(store.updateClient(alphaId, "Alpha 2", "333", "z@x.com", "Rua Z", "City Z"), isTrue);
      final Client alpha = store.clientById(alphaId)!;
      expect(alpha.name, "Alpha 2");
      expect(alpha.phone, "333");
      expect(alpha.city, "City Z");

      expect(store.deleteClient(alphaId), isTrue);
      expect(store.listClients().length, 1);
      expect(store.clientById(alphaId), isNull);
    });

    test("catalog edit propagates to draft lines; delete removes them", () async {
      final QuoteStore store = await openStore();
      expect(store.addClient("Client", "", "", "", ""), isTrue);
      final int clientId = store.lastClientId();

      expect(store.addEquipment("Camera", "4MP", 42000, 0), isTrue);
      final int itemId = store.lastCatalogId(.equipment);
      expect(store.addService("Install", "Point", 28000, 0), isTrue);
      final int serviceId = store.lastCatalogId(.service);

      final int draftId = store.createDraft(clientId);
      expect(draftId, greaterThan(0));
      expect(store.addDraftLine(draftId, .equipment, itemId, 2), isTrue);
      expect(store.addDraftLine(draftId, .service, serviceId, 1), isTrue);
      expect(store.quoteTotal(draftId), 112000);

      // Editing the catalog price updates the open draft line.
      expect(store.updateEquipment(itemId, "Camera Pro", "8MP", 50000, 0), isTrue);
      expect(store.nameFor(.equipment, itemId), "Camera Pro");
      expect(store.quoteTotal(draftId), 128000);

      // Deleting a catalog row drops its draft lines.
      expect(store.deleteService(serviceId), isTrue);
      expect(store.listCatalog(.service), isEmpty);
      final List<QuoteLine> lines = store.listQuoteLines(draftId);
      expect(lines.length, 1);
      expect(lines.first.type, CatalogItemType.equipment);
    });

    test("draft lines increment, clamp, and remove", () async {
      final QuoteStore store = await openStore();
      expect(store.addClient("Client", "", "", "", ""), isTrue);
      final int draftId = store.createDraft(store.lastClientId());
      expect(store.addEquipment("DVR", "8 canais", 89000, 0), isTrue);
      final int itemId = store.lastCatalogId(.equipment);

      expect(store.addDraftLine(draftId, .equipment, itemId, 1), isTrue);
      expect(store.addDraftLine(draftId, .equipment, itemId, 2), isTrue);
      final List<QuoteLine> lines = store.listQuoteLines(draftId);
      expect(lines.length, 1);
      expect(lines.first.quantity, 3);
      expect(lines.first.subtotalCents, 267000);

      expect(store.changeDraftLineQuantity(draftId, .equipment, itemId, -99), isTrue);
      expect(store.listQuoteLines(draftId).first.quantity, 1);
      expect(store.changeDraftLineQuantity(draftId, .equipment, itemId, 20000), isTrue);
      expect(store.listQuoteLines(draftId).first.quantity, 9999);

      expect(store.removeDraftLine(draftId, .equipment, itemId), isTrue);
      expect(store.listQuoteLines(draftId), isEmpty);
    });

    test("finalizeDraft saves the quote and shows in summaries", () async {
      final QuoteStore store = await openStore();
      expect(store.addClient("Client", "999", "", "Street", ""), isTrue);
      final int clientId = store.lastClientId();
      expect(store.addEquipment("Camera", "4MP", 42000, 0), isTrue);
      expect(store.addService("Install", "Point", 28000, 0), isTrue);

      final int draftId = store.createDraft(clientId);
      expect(store.addDraftLine(draftId, .equipment, store.lastCatalogId(.equipment), 4), isTrue);
      expect(store.addDraftLine(draftId, .service, store.lastCatalogId(.service), 4), isTrue);

      // Before finalize it is a draft.
      final QuoteSummary draftSummary = store.listRecentQuotes().single;
      expect(draftSummary.isDraft, isTrue);
      expect(draftSummary.serviceCount, 1);
      expect(draftSummary.equipmentCount, 1);

      expect(store.finalizeDraft(draftId), isTrue);
      final QuoteSummary saved = store.listQuotes(status: "saved").single;
      expect(saved.id, draftId);
      expect(saved.clientId, clientId);
      expect(saved.totalCents, 280000);
      expect(saved.isDraft, isFalse);
      expect(store.listQuotes(status: "draft"), isEmpty);
    });

    test("drafts persist across reopen and resume editable", () async {
      final QuoteStore first = QuoteStore(databasePath: path);
      expect(await first.open(), isTrue);
      expect(first.addClient("Persisted", "555", "", "Addr", "Town"), isTrue);
      final int clientId = first.lastClientId();
      expect(first.addEquipment("Sensor", "Door", 12000, 0), isTrue);
      final int draftId = first.createDraft(clientId);
      expect(first.addDraftLine(draftId, .equipment, first.lastCatalogId(.equipment), 3), isTrue);
      first.dispose();

      final QuoteStore second = QuoteStore(databasePath: path);
      addTearDown(second.dispose);
      expect(await second.open(), isTrue);
      final QuoteSummary draft = second.listRecentQuotes().single;
      expect(draft.id, draftId);
      expect(draft.isDraft, isTrue);
      expect(draft.equipmentCount, 1);
      expect(second.listQuoteLines(draftId).single.quantity, 3);
      expect(second.draftClientId(draftId), clientId);
    });

    test("deleteDraftIfEmpty removes only lineless drafts", () async {
      final QuoteStore store = await openStore();
      expect(store.addClient("Client", "", "", "", ""), isTrue);
      final int clientId = store.lastClientId();
      expect(store.addEquipment("Camera", "4MP", 42000, 0), isTrue);

      final int empty = store.createDraft(clientId);
      store.deleteDraftIfEmpty(empty);
      expect(store.listQuotes(), isEmpty);

      final int withLine = store.createDraft(clientId);
      expect(store.addDraftLine(withLine, .equipment, store.lastCatalogId(.equipment), 1), isTrue);
      store.deleteDraftIfEmpty(withLine);
      expect(store.listQuotes().length, 1);
    });

    test("error cases return false with the right code", () async {
      final QuoteStore unopened = QuoteStore(databasePath: path);
      addTearDown(unopened.dispose);
      expect(unopened.addClient("No DB", "", "", "", ""), isFalse);
      expect(unopened.errors.codeAt(0), errDbOpen);

      final QuoteStore store = await openStore();
      expect(store.addClient("", "", "", "", ""), isFalse);
      expect(store.errors.codeAt(store.errors.count - 1), errInvalidInput);

      expect(store.addEquipment("Bad", "", -1, 0), isFalse);
      expect(store.errors.codeAt(store.errors.count - 1), errInvalidInput);

      expect(store.addClient("Client", "", "", "", ""), isTrue);
      final int draftId = store.createDraft(store.lastClientId());
      expect(store.addDraftLine(draftId, .equipment, 404, 1), isFalse);
      expect(store.errors.codeAt(store.errors.count - 1), errMissingId);

      // Finalize with no lines.
      expect(store.finalizeDraft(draftId), isFalse);
      expect(store.errors.codeAt(store.errors.count - 1), errQuoteEmpty);

      // Finalize a draft without a client.
      final int clientless = store.createDraft(0);
      expect(store.finalizeDraft(clientless), isFalse);
      expect(store.errors.codeAt(store.errors.count - 1), errMissingId);
    });

    test("unit CRUD and lookups", () async {
      final QuoteStore store = await openStore();
      expect(store.addUnit("h", "Hour"), isTrue);
      expect(store.addUnit("m²", "Square meter"), isTrue);
      expect(store.listUnits().length, 2);
      final int hourId = store.listUnits().firstWhere((u) => u.abbreviation == "h").id;
      expect(store.unitAbbreviationFor(hourId), "h");

      expect(store.updateUnit(hourId, "hr", "Hour revised"), isTrue);
      expect(store.unitById(hourId)!.abbreviation, "hr");
      expect(store.deleteUnit(hourId), isTrue);
      expect(store.unitById(hourId), isNull);
    });

    test("payment method CRUD", () async {
      final QuoteStore store = await openStore();
      expect(store.addPaymentMethod("PIX"), isTrue);
      expect(store.addPaymentMethod("Credit Card"), isTrue);
      expect(store.listPaymentMethods().length, 2);
      final int pixId = store.listPaymentMethods().firstWhere((p) => p.name == "PIX").id;
      expect(store.updatePaymentMethod(pixId, "Bank Transfer (PIX)"), isTrue);
      expect(
        store.listPaymentMethods().firstWhere((p) => p.id == pixId).name,
        "Bank Transfer (PIX)",
      );
      expect(store.deletePaymentMethod(pixId), isTrue);
      expect(store.listPaymentMethods().length, 1);
    });

    test("singleton settings round-trip on reload", () async {
      final QuoteStore first = QuoteStore(databasePath: path);
      expect(await first.open(), isTrue);
      expect(
        first.saveBusinessInfo(
          "Delforte Sistemas",
          "12.345.678/0001-90",
          "Rua das Palmeiras, 200",
          "São Paulo",
          "SP",
          "+55 (11) 98888-0000",
          "contato@delforte.com.br",
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
        ),
        isTrue,
      );
      expect(first.saveQuoteDefaults("PIX", "30 days", "90 days", "Site visit first."), isTrue);
      expect(first.savePdfSettings("Navy Blue (default)"), isTrue);
      first.dispose();

      final QuoteStore second = QuoteStore(databasePath: path);
      addTearDown(second.dispose);
      expect(await second.open(), isTrue);
      expect(second.businessInfo.name, "Delforte Sistemas");
      expect(second.businessInfo.logo, Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]));
      expect(second.quoteDefaults.paymentMethod, "PIX");
      expect(second.pdfSettings.accentColour, "Navy Blue (default)");
    });

    test("search filters and returns all on empty query", () async {
      final QuoteStore store = await openStore();
      expect(store.addEquipment("Camera Pro", "8MP dome", 50000, 0), isTrue);
      expect(store.addEquipment("DVR", "16 channel recorder", 89000, 0), isTrue);
      expect(store.addEquipment("Cable", "RG6 coaxial", 3000, 0), isTrue);
      expect(store.addClient("Alpha Corp", "111", "a@x.com", "Rua A", "City A"), isTrue);
      expect(store.addClient("Beta Ltd", "222", "b@x.com", "Rua B", "City B"), isTrue);

      expect(store.searchCatalog(.equipment, "").length, 3);
      expect(store.searchCatalog(.equipment, "camera").single.name, "Camera Pro");
      expect(store.searchCatalog(.equipment, "recorder").single.name, "DVR");
      expect(store.searchCatalog(.equipment, "MISSING"), isEmpty);

      expect(store.searchClients("").length, 2);
      expect(store.searchClients("alpha").single.name, "Alpha Corp");
      expect(store.searchClients("222").single.name, "Beta Ltd");
      expect(store.searchClients("City A").single.name, "Alpha Corp");
      expect(store.searchClients("MISSING"), isEmpty);
    });
  });
}
