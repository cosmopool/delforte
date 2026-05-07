import "dart:io";

import "package:delforte/store/quote_store.dart";
import "package:delforte/store/store_errors.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqlite3/sqlite3.dart";

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

    test("open creates empty bounded buffers", () async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);

      expect(await store.open(), isTrue);
      expect(store.clients.count, 0);
      expect(store.items.count, 0);
      expect(store.services.count, 0);
      expect(store.quotes.count, 0);
      expect(store.clients.idAt(0), 0);
      expect(store.clients.nameAt(0), "");
      expect(store.items.priceCentsAt(0), 0);
      expect(store.errors.count, 0);
    });

    test("client CRUD mirrors SQLite into arrays", () async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);

      var clientNotifies = 0;
      store.clientsNotifier.addListener(() => clientNotifies++);

      expect(store.addClient("Alpha", "111", "a@x.com", "Rua A", "City A"), isTrue);
      expect(store.addClient("Beta", "222", "b@x.com", "Rua B", "City B"), isTrue);
      expect(store.clients.count, 2);
      expect(store.clients.nameAt(0), "Alpha");
      expect(clientNotifies, 2);

      final int alphaId = store.clients.idAt(0);
      expect(store.updateClient(alphaId, "Alpha 2", "333", "z@x.com", "Rua Z", "City Z"), isTrue);
      final int alphaIndex = store.clients.indexOfId(alphaId);
      expect(store.clients.nameAt(alphaIndex), "Alpha 2");
      expect(store.clients.phoneAt(alphaIndex), "333");
      expect(store.clients.cityAt(alphaIndex), "City Z");

      expect(store.deleteClient(alphaId), isTrue);
      expect(store.clients.count, 1);
      expect(store.clients.indexOfId(alphaId), -1);
      expect(store.clients.nameAt(0), "Beta");
    });

    test("catalog CRUD updates draft prices and removes deleted refs", () async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);

      expect(store.addItem("Camera", "4MP", 42000, 0), isTrue);
      expect(store.addService("Install", "Point", 28000, 0), isTrue);
      final int itemId = store.items.idAt(0);
      final int serviceId = store.services.idAt(0);

      expect(store.addDraftLine(quoteLineItem, itemId, 2), isTrue);
      expect(store.addDraftLine(quoteLineService, serviceId, 1), isTrue);
      expect(store.draft.computeTotals(), 112000);

      expect(store.updateItem(itemId, "Camera Pro", "8MP", 50000, 0), isTrue);
      expect(store.nameFor(quoteLineItem, itemId), "Camera Pro");
      expect(store.draft.computeTotals(), 128000);

      expect(store.deleteService(serviceId), isTrue);
      expect(store.services.count, 0);
      expect(store.draft.count, 1);
      expect(store.draft.types[0], quoteLineItem);
    });

    test("draft golden path computes totals and clamps quantities", () async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);

      expect(store.addItem("DVR", "8 canais", 89000, 0), isTrue);
      final int itemId = store.items.idAt(0);

      expect(store.addDraftLine(quoteLineItem, itemId, 1), isTrue);
      expect(store.addDraftLine(quoteLineItem, itemId, 2), isTrue);
      expect(store.draft.count, 1);
      expect(store.draft.quantities[0], 3);
      expect(store.draft.subtotalCents[0], 267000);

      expect(store.changeDraftQuantity(0, -99), isTrue);
      expect(store.draft.quantities[0], 1);
      expect(store.changeDraftQuantity(0, 20000), isTrue);
      expect(store.draft.quantities[0], 9999);

      expect(store.removeDraftLine(0), isTrue);
      expect(store.draft.count, 0);
      expect(store.draft.refIds[0], 0);
    });

    test("saveQuote writes quote and quote_lines in one success path", () async {
      final QuoteStore store = QuoteStore(databasePath: path);
      expect(await store.open(), isTrue);

      expect(store.addClient("Client", "999", "", "Street", ""), isTrue);
      expect(store.addItem("Camera", "4MP", 42000, 0), isTrue);
      expect(store.addService("Install", "Point", 28000, 0), isTrue);
      expect(store.addDraftLine(quoteLineItem, store.items.idAt(0), 4), isTrue);
      expect(store.addDraftLine(quoteLineService, store.services.idAt(0), 4), isTrue);

      final int clientId = store.clients.idAt(0);
      expect(store.saveQuote(clientId), isTrue);
      expect(store.quotes.count, 1);
      expect(store.quotes.clientIdAt(0), clientId);
      expect(store.quotes.totalCentsAt(0), 280000);
      store.dispose();

      final Database db = sqlite3.open(path);
      addTearDown(db.dispose);
      final ResultSet lineRows = db.select(
        "SELECT COUNT(*) AS c, SUM(subtotal_cents) AS total FROM quote_lines",
      );
      expect(lineRows.first["c"], 2);
      expect(lineRows.first["total"], 280000);
    });

    test("reload loads persisted rows into arrays", () async {
      final QuoteStore first = QuoteStore(databasePath: path);
      expect(await first.open(), isTrue);
      expect(first.addClient("Persisted", "555", "", "Addr", "Town"), isTrue);
      expect(first.addItem("Sensor", "Door", 12000, 0), isTrue);
      first.dispose();

      final QuoteStore second = QuoteStore(databasePath: path);
      addTearDown(second.dispose);
      expect(await second.open(), isTrue);
      expect(second.clients.count, 1);
      expect(second.clients.nameAt(0), "Persisted");
      expect(second.items.count, 1);
      expect(second.items.nameAt(0), "Sensor");
      expect(second.items.priceCentsAt(0), 12000);
    });

    test("error cases return false and leave arrays unchanged", () async {
      final QuoteStore unopened = QuoteStore(databasePath: path);
      addTearDown(unopened.dispose);
      expect(unopened.addClient("No DB", "", "", "", ""), isFalse);
      expect(unopened.errors.codeAt(0), errDbOpen);
      expect(unopened.clients.count, 0);

      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);

      expect(store.addClient("", "", "", "", ""), isFalse);
      expect(store.errors.codeAt(store.errors.count - 1), errInvalidInput);
      expect(store.clients.count, 0);

      expect(store.updateClient(404, "Missing", "", "", "", ""), isFalse);
      expect(store.errors.codeAt(store.errors.count - 1), errMissingId);

      expect(store.addItem("Bad", "", -1, 0), isFalse);
      expect(store.items.count, 0);
      expect(store.errors.codeAt(store.errors.count - 1), errInvalidInput);

      expect(store.addDraftLine(quoteLineItem, 404, 1), isFalse);
      expect(store.draft.count, 0);
      expect(store.errors.codeAt(store.errors.count - 1), errMissingId);

      expect(store.saveQuote(404), isFalse);
      expect(store.quotes.count, 0);
      expect(store.errors.codeAt(store.errors.count - 1), errMissingId);
    });

    test("unit CRUD mirrors SQLite into arrays", () async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);

      var unitNotifies = 0;
      store.unitsNotifier.addListener(() => unitNotifies++);

      expect(store.addUnit("h", "Hour"), isTrue);
      expect(store.addUnit("m²", "Square meter"), isTrue);
      expect(store.units.count, 2);
      expect(store.units.abbreviationAt(0), "h");
      expect(store.units.descriptionAt(0), "Hour");
      expect(unitNotifies, 2);

      final int hourId = store.units.idAt(0);
      expect(store.updateUnit(hourId, "hr", "Hour revised"), isTrue);
      final int hourIndex = store.units.indexOfId(hourId);
      expect(store.units.abbreviationAt(hourIndex), "hr");
      expect(store.units.descriptionAt(hourIndex), "Hour revised");

      expect(store.deleteUnit(hourId), isTrue);
      expect(store.units.count, 1);
      expect(store.units.indexOfId(hourId), -1);
      expect(store.units.abbreviationAt(0), "m²");
    });

    test("reload loads units and new client fields", () async {
      final QuoteStore first = QuoteStore(databasePath: path);
      expect(await first.open(), isTrue);
      expect(first.addClient("CityTest", "", "", "St", "Town"), isTrue);
      expect(first.addUnit("un", "Unit"), isTrue);
      expect(first.addItem("Box", "Small", 5000, first.units.idAt(0)), isTrue);
      first.dispose();

      final QuoteStore second = QuoteStore(databasePath: path);
      addTearDown(second.dispose);
      expect(await second.open(), isTrue);
      expect(second.clients.count, 1);
      expect(second.clients.cityAt(0), "Town");
      expect(second.units.count, 1);
      expect(second.units.abbreviationAt(0), "un");
      expect(second.items.count, 1);
      expect(second.items.unitIdAt(0), second.units.idAt(0));
    });

    test("saveQuote rejects empty draft for valid client", () async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);
      expect(store.addClient("Client", "", "", "", ""), isTrue);

      expect(store.saveQuote(store.clients.idAt(0)), isFalse);
      expect(store.quotes.count, 0);
      expect(store.errors.codeAt(store.errors.count - 1), errQuoteEmpty);
    });
  });
}
