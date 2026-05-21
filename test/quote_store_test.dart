import "dart:io";
import "dart:typed_data";

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
      expect(store.equipment.count, 0);
      expect(store.services.count, 0);
      expect(store.quotes.count, 0);
      expect(store.clients.idAt(0), 0);
      expect(store.clients.nameAt(0), "");
      expect(store.equipment.priceCentsAt(0), 0);
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

      expect(store.addEquipment("Camera", "4MP", 42000, 0), isTrue);
      expect(store.addService("Install", "Point", 28000, 0), isTrue);
      final int itemId = store.equipment.idAt(0);
      final int serviceId = store.services.idAt(0);

      expect(store.addDraftLine(quoteLineEquipment, itemId, 2), isTrue);
      expect(store.addDraftLine(quoteLineService, serviceId, 1), isTrue);
      expect(store.draft.computeTotals(), 112000);

      expect(store.updateEquipment(itemId, "Camera Pro", "8MP", 50000, 0), isTrue);
      expect(store.nameFor(quoteLineEquipment, itemId), "Camera Pro");
      expect(store.draft.computeTotals(), 128000);

      expect(store.deleteService(serviceId), isTrue);
      expect(store.services.count, 0);
      expect(store.draft.count, 1);
      expect(store.draft.types[0], quoteLineEquipment);
    });

    test("draft golden path computes totals and clamps quantities", () async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);

      expect(store.addEquipment("DVR", "8 canais", 89000, 0), isTrue);
      final int itemId = store.equipment.idAt(0);

      expect(store.addDraftLine(quoteLineEquipment, itemId, 1), isTrue);
      expect(store.addDraftLine(quoteLineEquipment, itemId, 2), isTrue);
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
      expect(store.addEquipment("Camera", "4MP", 42000, 0), isTrue);
      expect(store.addService("Install", "Point", 28000, 0), isTrue);
      expect(store.addDraftLine(quoteLineEquipment, store.equipment.idAt(0), 4), isTrue);
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
      expect(first.addEquipment("Sensor", "Door", 12000, 0), isTrue);
      first.dispose();

      final QuoteStore second = QuoteStore(databasePath: path);
      addTearDown(second.dispose);
      expect(await second.open(), isTrue);
      expect(second.clients.count, 1);
      expect(second.clients.nameAt(0), "Persisted");
      expect(second.equipment.count, 1);
      expect(second.equipment.nameAt(0), "Sensor");
      expect(second.equipment.priceCentsAt(0), 12000);
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

      expect(store.addEquipment("Bad", "", -1, 0), isFalse);
      expect(store.equipment.count, 0);
      expect(store.errors.codeAt(store.errors.count - 1), errInvalidInput);

      expect(store.addDraftLine(quoteLineEquipment, 404, 1), isFalse);
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
      expect(first.addEquipment("Box", "Small", 5000, first.units.idAt(0)), isTrue);
      first.dispose();

      final QuoteStore second = QuoteStore(databasePath: path);
      addTearDown(second.dispose);
      expect(await second.open(), isTrue);
      expect(second.clients.count, 1);
      expect(second.clients.cityAt(0), "Town");
      expect(second.units.count, 1);
      expect(second.units.abbreviationAt(0), "un");
      expect(second.equipment.count, 1);
      expect(second.equipment.unitIdAt(0), second.units.idAt(0));
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

    test("payment method CRUD mirrors SQLite into arrays", () async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);

      var paymentNotifies = 0;
      store.paymentMethodsNotifier.addListener(() => paymentNotifies++);

      expect(store.addPaymentMethod("PIX"), isTrue);
      expect(store.addPaymentMethod("Credit Card"), isTrue);
      expect(store.paymentMethods.count, 2);
      expect(store.paymentMethods.nameAt(0), "PIX");
      expect(paymentNotifies, 2);

      final int pixId = store.paymentMethods.idAt(0);
      expect(store.updatePaymentMethod(pixId, "Bank Transfer (PIX)"), isTrue);
      final int pixIndex = store.paymentMethods.indexOfId(pixId);
      expect(store.paymentMethods.nameAt(pixIndex), "Bank Transfer (PIX)");
      expect(paymentNotifies, 3);

      expect(store.deletePaymentMethod(pixId), isTrue);
      expect(store.paymentMethods.count, 1);
      expect(store.paymentMethods.indexOfId(pixId), -1);
      expect(store.paymentMethods.nameAt(0), "Credit Card");
    });

    test("singleton settings round-trip on reload", () async {
      final QuoteStore first = QuoteStore(databasePath: path);
      expect(await first.open(), isTrue);
      expect(first.saveBusinessInfo(
        "Delforte Sistemas",
        "12.345.678/0001-90",
        "Rua das Palmeiras, 200",
        "São Paulo",
        "SP",
        "+55 (11) 98888-0000",
        "contato@delforte.com.br",
        Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
      ), isTrue);
      expect(first.saveQuoteDefaults(
        "Bank Transfer (PIX)",
        "30 days",
        "90 days — parts & labour",
        "Services subject to prior site visit.",
      ), isTrue);
      expect(first.savePdfSettings("Navy Blue (default)"), isTrue);
      first.dispose();

      final QuoteStore second = QuoteStore(databasePath: path);
      addTearDown(second.dispose);
      expect(await second.open(), isTrue);
      expect(second.businessInfo.hasData, isTrue);
      expect(second.businessInfo.name, "Delforte Sistemas");
      expect(second.businessInfo.cnpj, "12.345.678/0001-90");
      expect(second.businessInfo.address, "Rua das Palmeiras, 200");
      expect(second.businessInfo.city, "São Paulo");
      expect(second.businessInfo.state, "SP");
      expect(second.businessInfo.phone, "+55 (11) 98888-0000");
      expect(second.businessInfo.email, "contato@delforte.com.br");
      expect(second.businessInfo.logo, Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]));
      expect(second.quoteDefaults.hasData, isTrue);
      expect(second.quoteDefaults.paymentMethod, "Bank Transfer (PIX)");
      expect(second.quoteDefaults.validity, "30 days");
      expect(second.quoteDefaults.warranty, "90 days — parts & labour");
      expect(second.quoteDefaults.terms, "Services subject to prior site visit.");
      expect(second.pdfSettings.hasData, isTrue);
      expect(second.pdfSettings.accentColour, "Navy Blue (default)");
    });

    test("payment method errors return false and leave arrays unchanged", () async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);

      expect(store.addPaymentMethod(""), isFalse);
      expect(store.paymentMethods.count, 0);
      expect(store.errors.codeAt(store.errors.count - 1), errInvalidInput);

      expect(store.addPaymentMethod("Cash"), isTrue);
      expect(store.updatePaymentMethod(404, "Missing"), isFalse);
      expect(store.errors.codeAt(store.errors.count - 1), errMissingId);

      expect(store.deletePaymentMethod(404), isFalse);
      expect(store.errors.codeAt(store.errors.count - 1), errMissingId);
    });

    test("search indexes filters and returns all on empty query", () async {
      final QuoteStore store = QuoteStore(databasePath: path);
      addTearDown(store.dispose);
      expect(await store.open(), isTrue);

      expect(store.addEquipment("Camera Pro", "8MP dome", 50000, 0), isTrue);
      expect(store.addEquipment("DVR", "16 channel recorder", 89000, 0), isTrue);
      expect(store.addEquipment("Cable", "RG6 coaxial", 3000, 0), isTrue);

      expect(store.addClient("Alpha Corp", "111", "a@x.com", "Rua A", "City A"), isTrue);
      expect(store.addClient("Beta Ltd", "222", "b@x.com", "Rua B", "City B"), isTrue);

      expect(store.addUnit("h", "Hour"), isTrue);
      expect(store.addUnit("m²", "Square meter"), isTrue);

      expect(store.addPaymentMethod("PIX"), isTrue);
      expect(store.addPaymentMethod("Credit Card"), isTrue);

      expect(store.equipment.searchIndexes(""), [0, 1, 2]);
      expect(store.equipment.searchIndexes("camera"), [0]);
      expect(store.equipment.searchIndexes("recorder"), [1]);
      expect(store.equipment.searchIndexes("MISSING"), isEmpty);

      expect(store.clients.searchIndexes(""), [0, 1]);
      expect(store.clients.searchIndexes("alpha"), [0]);
      expect(store.clients.searchIndexes("222"), [1]);
      expect(store.clients.searchIndexes("a@x.com"), [0]);
      expect(store.clients.searchIndexes("Rua B"), [1]);
      expect(store.clients.searchIndexes("City A"), [0]);
      expect(store.clients.searchIndexes("MISSING"), isEmpty);

      expect(store.units.searchIndexes(""), [0, 1]);
      expect(store.units.searchIndexes("h"), [0]);
      expect(store.units.searchIndexes("square"), [1]);
      expect(store.units.searchIndexes("MISSING"), isEmpty);

      expect(store.paymentMethods.searchIndexes(""), [0, 1]);
      expect(store.paymentMethods.searchIndexes("pix"), [0]);
      expect(store.paymentMethods.searchIndexes("card"), [1]);
      expect(store.paymentMethods.searchIndexes("MISSING"), isEmpty);
    });
  });
}
