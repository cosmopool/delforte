import "dart:io";
import "dart:typed_data";

import "package:delforte/store/quote_store.dart";
import "package:delforte/store/store_errors.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqlite3/sqlite3.dart";

/// The schema every app build before the single page shipped, at `user_version` 1.
const String v1Schema = """
CREATE TABLE clients (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT NOT NULL DEFAULT '', email TEXT NOT NULL DEFAULT '', address TEXT NOT NULL DEFAULT '', city TEXT NOT NULL DEFAULT '');
CREATE TABLE units (id INTEGER PRIMARY KEY AUTOINCREMENT, abbreviation TEXT NOT NULL, description TEXT NOT NULL DEFAULT '');
CREATE TABLE equipments (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', price_cents INTEGER NOT NULL DEFAULT 0, unit_id INTEGER NOT NULL DEFAULT 0);
CREATE TABLE services (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', price_cents INTEGER NOT NULL DEFAULT 0, unit_id INTEGER NOT NULL DEFAULT 0);
CREATE TABLE quotes (id INTEGER PRIMARY KEY AUTOINCREMENT, client_id INTEGER NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL DEFAULT 0, total_cents INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'draft');
CREATE TABLE quote_lines (quote_id INTEGER NOT NULL, line_type INTEGER NOT NULL, ref_id INTEGER NOT NULL, quantity INTEGER NOT NULL, unit_price_cents INTEGER NOT NULL, subtotal_cents INTEGER NOT NULL);
CREATE INDEX idx_quote_lines_quote ON quote_lines(quote_id);
CREATE UNIQUE INDEX idx_quote_lines_unique ON quote_lines(quote_id, line_type, ref_id);
CREATE TABLE business_info (id INTEGER PRIMARY KEY, name TEXT NOT NULL DEFAULT '', cnpj TEXT NOT NULL DEFAULT '', address TEXT NOT NULL DEFAULT '', city TEXT NOT NULL DEFAULT '', state TEXT NOT NULL DEFAULT '', phone TEXT NOT NULL DEFAULT '', email TEXT NOT NULL DEFAULT '', logo BLOB);
CREATE TABLE payment_methods (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL);
CREATE TABLE quote_defaults (id INTEGER PRIMARY KEY, payment_method TEXT NOT NULL DEFAULT '', validity TEXT NOT NULL DEFAULT '', warranty TEXT NOT NULL DEFAULT '', terms TEXT NOT NULL DEFAULT '');
CREATE TABLE pdf_settings (id INTEGER PRIMARY KEY, accent_colour TEXT NOT NULL DEFAULT '');
INSERT INTO business_info (id, name) VALUES (1, 'Empresa Antiga');
INSERT INTO quote_defaults (id, payment_method) VALUES (1, 'PIX');
INSERT INTO pdf_settings (id) VALUES (1);
INSERT INTO clients (name, address) VALUES ('Cliente Antigo', 'Rua Velha, 1');
INSERT INTO units (abbreviation, description) VALUES ('h', 'Hora');
INSERT INTO equipments (name, price_cents, unit_id) VALUES ('Camera', 42000, 1);
INSERT INTO services (name, price_cents, unit_id) VALUES ('Instalacao', 28000, 1);
INSERT INTO payment_methods (name) VALUES ('Boleto');
INSERT INTO quotes (client_id, created_at, updated_at, total_cents, status) VALUES (1, 1700000000000, 1700000000000, 84000, 'saved');
INSERT INTO quote_lines VALUES (1, 0, 1, 2, 42000, 84000);
PRAGMA user_version = 1;
""";

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

    /// Writes a v1 database file at [filePath], as an old app build left it.
    void writeV1Database(String filePath) {
      final Database db = sqlite3.open(filePath);
      db.execute(v1Schema);
      db.close();
    }

    /// Holds the SQLite write lock from a second connection, so every write the
    /// store attempts is rejected by the database until the test ends.
    void rejectWrites() {
      final Database lock = sqlite3.open(path);
      lock.execute("BEGIN IMMEDIATE");
      addTearDown(() {
        lock.execute("ROLLBACK");
        lock.close();
      });
    }

    int unitId(QuoteStore store, String abbreviation) {
      return store.listUnits().firstWhere((Unit u) => u.abbreviation == abbreviation).id;
    }

    /// Everything a quote shows, flattened so two reads can be compared.
    String quoteDocument(QuoteStore store, int quoteId) {
      final QuotePdfData data = store.quotePdfData(quoteId);
      final Client? client = data.client;
      return [
        "client ${client?.name}|${client?.phone}|${client?.email}|${client?.address}|${client?.city}",
        "conditions ${data.payment}|${data.warranty}|${data.validity}|${data.terms}",
        "notes ${data.notes}",
        "equipment price ${data.showUnitPrice}|${data.equipmentPriceMode}|${data.closedTotalCents}|${data.markupPercent}",
        for (final QuoteLine line in store.listQuoteLines(quoteId))
          "line ${line.type}|${line.refId}|${line.name}|${line.description}|${line.unit}|${line.quantity}|${line.unitPriceCents}|${line.subtotalCents}|${line.isNew}",
        "total ${store.quoteTotal(quoteId)}",
      ].join("\n");
    }

    test("AC-3 opening a v1 database wipes it to an empty v2 with the seeded units", () async {
      writeV1Database(path);

      final QuoteStore store = await openStore();

      final Database raw = sqlite3.open(path);
      addTearDown(raw.close);
      expect(raw.select("PRAGMA user_version").first["user_version"], 2);
      expect(store.listClients(), isEmpty);
      expect(store.listCatalog(.equipment), isEmpty);
      expect(store.listCatalog(.service), isEmpty);
      expect(store.listQuotes(), isEmpty);
      expect(store.listPaymentMethods(), isEmpty);
      expect(store.businessInfo.name, "");
      expect(store.quoteDefaults.paymentMethod, "");
      expect(store.listUnits().map((Unit u) => u.abbreviation).toSet(), {"un", "m", "cx", "kit"});
      expect(store.errors.count, 0);
    });

    test("AC-4 a fresh database defaults to showing the unit price in the PDF", () async {
      final QuoteStore store = await openStore();

      expect(store.quoteDefaults.showUnitPrice, isTrue);
      expect(store.listClients(), isEmpty);
      expect(store.listQuotes(), isEmpty);
      expect(store.listUnits().map((Unit u) => u.abbreviation).toSet(), {"un", "m", "cx", "kit"});
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

    test("AC-101 a draft is born without a client, with its own copy of the Padrões", () async {
      final QuoteStore store = await openStore();
      expect(store.saveQuoteDefaults("PIX", "30 dias", "90 dias", "T"), isTrue);

      final int draftId = store.createDraft();
      expect(draftId, greaterThan(0));
      expect(store.saveQuoteDefaults("Boleto", "60 dias", "1 ano", "Outro"), isTrue);

      expect(store.quoteClient(draftId), isNull);
      final QuotePdfData data = store.quotePdfData(draftId);
      expect(data.status, "draft");
      expect(data.client, isNull);
      expect(data.payment, "PIX");
      expect(data.warranty, "90 dias");
      expect(data.validity, "30 dias");
      expect(data.terms, "T");
      expect(data.notes, "");
      expect(data.showUnitPrice, isTrue);
      expect(data.closedTotalCents, 0);
      expect(data.markupPercent, 0);
      expect(data.rendererVersion, newestPdfRenderer);

      final QuoteSummary summary = store.listQuotes().single;
      expect(summary.id, draftId);
      expect(summary.isDraft, isTrue);
      expect(summary.clientName, "");
    });

    test("AC-102 the empty-draft discard looks only at the client and the lines", () async {
      final QuoteStore store = await openStore();
      expect(store.addClient("Residencial Oliveira", "", "", "Rua das Flores, 142", ""), isTrue);
      final int clientId = store.lastClientId();
      expect(store.addEquipment("Haste de canto", "", 3200, 0), isTrue);
      final int itemId = store.lastCatalogId(.equipment);

      final int notesOnly = store.createDraft();
      expect(store.setDraftTexts(notesOnly, notes: "Levar escada"), isTrue);
      store.deleteDraftIfEmpty(notesOnly);
      expect(store.listQuotes().where((QuoteSummary q) => q.id == notesOnly), isEmpty);

      final int withClient = store.createDraft();
      expect(store.setDraftClient(withClient, clientId), isTrue);
      store.deleteDraftIfEmpty(withClient);

      final int withLine = store.createDraft();
      expect(store.addDraftLine(withLine, .equipment, itemId, 1), isTrue);
      store.deleteDraftIfEmpty(withLine);

      expect(store.listQuotes().map((QuoteSummary q) => q.id).toSet(), {withClient, withLine});
    });

    test(
      "AC-9 a draft keeps the client as it was when set, after the client is edited or deleted",
      () async {
        final QuoteStore store = await openStore();
        expect(
          store.addClient(
            "Residencial Oliveira",
            "(11) 98888-1010",
            "oliveira@x.com",
            "Rua das Flores, 142",
            "São Paulo",
          ),
          isTrue,
        );
        final int clientId = store.lastClientId();
        final int draftId = store.createDraft();

        expect(store.setDraftClient(draftId, clientId), isTrue);
        expect(
          store.updateClient(
            clientId,
            "Oliveira Ltda",
            "000",
            "novo@x.com",
            "Av. Nova, 9",
            "Campinas",
          ),
          isTrue,
        );

        for (final Client? client in [
          store.quoteClient(draftId),
          store.quotePdfData(draftId).client,
        ]) {
          expect(client, isNotNull);
          expect(client!.name, "Residencial Oliveira");
          expect(client.phone, "(11) 98888-1010");
          expect(client.email, "oliveira@x.com");
          expect(client.address, "Rua das Flores, 142");
          expect(client.city, "São Paulo");
        }

        expect(store.deleteClient(clientId), isTrue);
        expect(store.quoteClient(draftId)?.address, "Rua das Flores, 142");
        expect(store.quotePdfData(draftId).client?.name, "Residencial Oliveira");
        expect(store.listQuotes().single.clientName, "Residencial Oliveira");
      },
    );

    test(
      "AC-21 Condições and Observações change only on that quote and Pagamento is a text copy",
      () async {
        final QuoteStore store = await openStore();
        expect(store.saveQuoteDefaults("PIX", "30 dias", "90 dias", "T"), isTrue);
        expect(store.addPaymentMethod("PIX"), isTrue);
        expect(store.addPaymentMethod("Cartão em 3x"), isTrue);
        final PaymentMethod card = store.listPaymentMethods().firstWhere(
          (PaymentMethod p) => p.name == "Cartão em 3x",
        );
        final int edited = store.createDraft();
        final int other = store.createDraft();

        expect(
          store.setDraftTexts(
            edited,
            payment: card.name,
            warranty: "6 meses",
            validity: "15 dias",
            terms: "Sem visita técnica",
            notes: "Portão lateral",
          ),
          isTrue,
        );
        expect(store.updatePaymentMethod(card.id, "Cartão de crédito"), isTrue);
        expect(store.deletePaymentMethod(card.id), isTrue);

        final QuotePdfData data = store.quotePdfData(edited);
        expect(data.payment, "Cartão em 3x");
        expect(data.warranty, "6 meses");
        expect(data.validity, "15 dias");
        expect(data.terms, "Sem visita técnica");
        expect(data.notes, "Portão lateral");

        final QuotePdfData untouched = store.quotePdfData(other);
        expect(untouched.payment, "PIX");
        expect(untouched.warranty, "90 dias");
        expect(untouched.validity, "30 dias");
        expect(untouched.terms, "T");
        expect(untouched.notes, "");

        expect(store.quoteDefaults.paymentMethod, "PIX");
        expect(store.quoteDefaults.warranty, "90 dias");
        expect(store.quoteDefaults.validity, "30 dias");
        expect(store.quoteDefaults.terms, "T");
      },
    );

    test(
      "AC-10 catalog search ignores accents and case and matches anywhere in the name",
      () async {
        final QuoteStore store = await openStore();
        expect(store.addEquipment("Haste de canto", "", 3200, 0), isTrue);
        expect(store.addEquipment("Fio de aço inox", "", 900, 0), isTrue);
        expect(store.addEquipment("Cabo coaxial", "RG6", 300, 0), isTrue);

        expect(store.searchCatalog(.equipment, "HASTE").single.name, "Haste de canto");
        expect(store.searchCatalog(.equipment, "haste").single.name, "Haste de canto");
        expect(store.searchCatalog(.equipment, "aco").single.name, "Fio de aço inox");
        expect(store.searchCatalog(.equipment, "INOX").single.name, "Fio de aço inox");
        expect(store.searchCatalog(.equipment, "").length, 3);
        expect(store.searchCatalog(.equipment, "MISSING"), isEmpty);
      },
    );

    test(
      "AC-11, AC-12 an equipment line keeps its own copy and price, and repeats sum up to 9999",
      () async {
        final QuoteStore store = await openStore();
        final int un = unitId(store, "un");
        expect(store.addEquipment("Haste de canto", "Aço galvanizado", 3200, un), isTrue);
        final int itemId = store.lastCatalogId(.equipment);
        final int draftId = store.createDraft();

        expect(store.addDraftLine(draftId, .equipment, itemId, 4), isTrue);
        expect(store.setDraftLineUnitPrice(draftId, .equipment, itemId, 3000), isTrue);

        QuoteLine line = store.listQuoteLines(draftId).single;
        expect(line.type, CatalogItemType.equipment);
        expect(line.refId, itemId);
        expect(line.name, "Haste de canto");
        expect(line.unit, "un");
        expect(line.quantity, 4);
        expect(line.unitPriceCents, 3000);
        expect(line.subtotalCents, 12000);
        expect(store.quoteTotal(draftId), 12000);
        expect(store.catalogById(.equipment, itemId)!.priceCents, 3200);

        expect(store.addDraftLine(draftId, .equipment, itemId, 9998), isTrue);

        line = store.listQuoteLines(draftId).single;
        expect(line.quantity, 9999);
        expect(line.unitPriceCents, 3000);
        expect(line.subtotalCents, 9999 * 3000);
        expect(store.catalogById(.equipment, itemId)!.priceCents, 3200);
      },
    );

    test("draft line quantities change, clamp, and remove", () async {
      final QuoteStore store = await openStore();
      final int draftId = store.createDraft();
      expect(store.addEquipment("DVR", "8 canais", 89000, 0), isTrue);
      final int itemId = store.lastCatalogId(.equipment);

      expect(store.addDraftLine(draftId, .equipment, itemId, 1), isTrue);
      expect(store.addDraftLine(draftId, .equipment, itemId, 2), isTrue);
      expect(store.listQuoteLines(draftId).single.quantity, 3);
      expect(store.listQuoteLines(draftId).single.subtotalCents, 267000);

      expect(store.changeDraftLineQuantity(draftId, .equipment, itemId, -99), isTrue);
      expect(store.listQuoteLines(draftId), isEmpty);
      expect(store.addDraftLine(draftId, .equipment, itemId, 1), isTrue);
      expect(store.changeDraftLineQuantity(draftId, .equipment, itemId, 20000), isTrue);
      expect(store.listQuoteLines(draftId).single.quantity, 9999);

      expect(store.removeDraftLine(draftId, .equipment, itemId), isTrue);
      expect(store.listQuoteLines(draftId), isEmpty);
    });

    test(
      "AC-13, AC-14 a service line is edited only on the quote and is never added twice",
      () async {
        final QuoteStore store = await openStore();
        expect(store.addService("Instalação de câmeras", "Por ponto", 28000), isTrue);
        final int serviceId = store.lastCatalogId(.service);
        final int draftId = store.createDraft();

        expect(store.addDraftLine(draftId, .service, serviceId, 1), isTrue);
        expect(
          store.setDraftLineDescription(
            draftId,
            .service,
            serviceId,
            "Quatro pontos com cabeamento",
          ),
          isTrue,
        );
        expect(store.setDraftLineUnitPrice(draftId, .service, serviceId, 35000), isTrue);

        QuoteLine line = store.listQuoteLines(draftId).single;
        expect(line.type, CatalogItemType.service);
        expect(line.name, "Instalação de câmeras");
        expect(line.description, "Quatro pontos com cabeamento");
        expect(line.unitPriceCents, 35000);
        expect(line.subtotalCents, 35000);
        expect(line.quantity, 1);
        expect(line.unit, "");

        final CatalogItem catalog = store.catalogById(.service, serviceId)!;
        expect(catalog.description, "Por ponto");
        expect(catalog.priceCents, 28000);

        expect(store.addDraftLine(draftId, .service, serviceId, 1), isTrue);

        final List<QuoteLine> lines = store.listQuoteLines(draftId);
        expect(lines.length, 1);
        line = lines.singleWhere(
          (QuoteLine l) => l.type == CatalogItemType.service && l.refId == serviceId,
        );
        expect(line.quantity, 1);
        expect(line.description, "Quatro pontos com cabeamento");
        expect(line.unitPriceCents, 35000);
        expect(store.quoteTotal(draftId), 35000);
      },
    );

    test(
      "AC-15, AC-16, AC-17 an Item novo lands in the catalog, is flagged until saved, and survives its line",
      () async {
        final QuoteStore store = await openStore();
        final int un = unitId(store, "un");
        expect(store.addClient("Residencial Oliveira", "", "", "", ""), isTrue);
        final int clientId = store.lastClientId();
        expect(store.addEquipment("Haste de canto", "", 3200, un), isTrue);
        final int hasteId = store.lastCatalogId(.equipment);
        expect(store.searchCatalog(.equipment, "placa de advertencia"), isEmpty);

        final int draftId = store.createDraft();
        expect(store.setDraftClient(draftId, clientId), isTrue);
        expect(store.addDraftLine(draftId, .equipment, hasteId, 1), isTrue);
        expect(
          store.addNewCatalogLine(draftId, .equipment, "placa de advertencia", "", 640, un, 2),
          isTrue,
        );

        final CatalogItem created = store
            .listCatalog(.equipment)
            .singleWhere((CatalogItem i) => i.id != hasteId);
        expect(created.name, "Placa de advertencia");
        expect(created.unitId, un);
        expect(created.priceCents, 640);

        final QuoteLine flagged = store
            .listQuoteLines(draftId)
            .singleWhere((QuoteLine l) => l.refId == created.id);
        expect(flagged.type, CatalogItemType.equipment);
        expect(flagged.name, "Placa de advertencia");
        expect(flagged.unit, "un");
        expect(flagged.quantity, 2);
        expect(flagged.unitPriceCents, 640);
        expect(flagged.isNew, isTrue);
        expect(
          store.listQuoteLines(draftId).singleWhere((QuoteLine l) => l.refId == hasteId).isNew,
          isFalse,
        );

        // AC-17: removing the flagged line drops its subtotal and keeps the item.
        final int before = store.quoteTotal(draftId);
        expect(store.removeDraftLine(draftId, .equipment, created.id), isTrue);
        expect(store.quoteTotal(draftId), before - flagged.subtotalCents);
        expect(store.catalogById(.equipment, created.id), isNotNull);

        // AC-16: saving clears the flag, and another quote never shows it.
        expect(
          store.addNewCatalogLine(draftId, .equipment, "sirene externa", "", 4500, un, 1),
          isTrue,
        );
        expect(store.listQuoteLines(draftId).where((QuoteLine l) => l.isNew).length, 1);
        expect(store.finalizeDraft(draftId), isTrue);
        expect(store.listQuoteLines(draftId).where((QuoteLine l) => l.isNew), isEmpty);
        expect(store.listQuoteLines(draftId).length, 2);

        final int sireneId = store
            .listCatalog(.equipment)
            .firstWhere((CatalogItem i) => i.name == "Sirene externa")
            .id;
        final int another = store.createDraft();
        expect(store.addDraftLine(another, .equipment, sireneId, 1), isTrue);
        expect(store.listQuoteLines(another).single.isNew, isFalse);

        // Discarding a draft leaves its Item novo in the catalog too.
        final int discarded = store.createDraft();
        expect(
          store.addNewCatalogLine(discarded, .equipment, "bateria 12v", "", 9000, un, 1),
          isTrue,
        );
        expect(store.deleteQuote(discarded), isTrue);
        expect(store.searchCatalog(.equipment, "bateria").single.name, "Bateria 12v");
      },
    );

    test("AC-18, AC-19 editing or deleting a catalog item never changes a draft line", () async {
      final QuoteStore store = await openStore();
      final int un = unitId(store, "un");
      expect(store.addEquipment("Camera", "4MP", 42000, un), isTrue);
      final int cameraId = store.lastCatalogId(.equipment);
      expect(store.addService("Instalação", "Por ponto", 28000), isTrue);
      final int serviceId = store.lastCatalogId(.service);
      final int draftId = store.createDraft();
      expect(store.addDraftLine(draftId, .equipment, cameraId, 2), isTrue);
      expect(store.addDraftLine(draftId, .service, serviceId, 1), isTrue);
      final String before = quoteDocument(store, draftId);

      expect(store.updateEquipment(cameraId, "Camera Pro", "8MP", 50000, un), isTrue);
      expect(store.updateService(serviceId, "Instalação Premium", "Kit", 30000), isTrue);
      expect(store.catalogById(.equipment, cameraId)!.name, "Camera Pro");
      expect(quoteDocument(store, draftId), before);
      expect(store.quoteTotal(draftId), 112000);

      expect(store.deleteEquipment(cameraId), isTrue);
      expect(store.deleteService(serviceId), isTrue);
      expect(store.listCatalog(.equipment), isEmpty);
      expect(store.listCatalog(.service), isEmpty);
      expect(quoteDocument(store, draftId), before);

      final List<QuotePdfLine> pdfLines = store.quotePdfData(draftId).lines;
      expect(pdfLines.length, 2);
      final QuotePdfLine camera = pdfLines.singleWhere(
        (QuotePdfLine l) => l.type == CatalogItemType.equipment,
      );
      expect(camera.name, "Camera");
      expect(camera.description, "4MP");
      expect(camera.unit, "un");
      expect(camera.quantity, 2);
      expect(camera.unitPriceCents, 42000);
      expect(camera.subtotalCents, 84000);
      final QuotePdfLine service = pdfLines.singleWhere(
        (QuotePdfLine l) => l.type == CatalogItemType.service,
      );
      expect(service.name, "Instalação");
      expect(service.description, "Por ponto");
      expect(service.unit, "");
    });

    test("AC-20 services are stored without a unit", () async {
      final QuoteStore store = await openStore();

      expect(store.addService("Instalação", "Por ponto", 28000), isTrue);
      final int serviceId = store.lastCatalogId(.service);
      expect(store.catalogById(.service, serviceId)!.unitId, 0);

      expect(store.updateService(serviceId, "Instalação 2", "Kit", 30000), isTrue);
      final CatalogItem service = store.catalogById(.service, serviceId)!;
      expect(service.name, "Instalação 2");
      expect(service.priceCents, 30000);
      expect(service.unitId, 0);
    });

    test(
      "AC-26 saving needs a client and a line, allows a zero total and stamps the newest renderer",
      () async {
        final QuoteStore store = await openStore();
        expect(store.addClient("Residencial Oliveira", "", "", "", ""), isTrue);
        final int clientId = store.lastClientId();
        expect(store.addEquipment("Brinde", "", 0, 0), isTrue);
        final int freeId = store.lastCatalogId(.equipment);

        final int noLines = store.createDraft();
        expect(store.setDraftClient(noLines, clientId), isTrue);
        expect(store.finalizeDraft(noLines), isFalse);
        expect(store.latestErrorMessage(), isNotEmpty);

        final int noClient = store.createDraft();
        expect(store.addDraftLine(noClient, .equipment, freeId, 1), isTrue);
        expect(store.finalizeDraft(noClient), isFalse);
        expect(store.listQuotes(status: "saved"), isEmpty);

        final int draftId = store.createDraft();
        expect(store.setDraftClient(draftId, clientId), isTrue);
        expect(store.addDraftLine(draftId, .equipment, freeId, 3), isTrue);
        expect(store.finalizeDraft(draftId), isTrue);

        final QuoteSummary saved = store.listQuotes(status: "saved").single;
        expect(saved.id, draftId);
        expect(saved.isDraft, isFalse);
        expect(saved.totalCents, 0);
        expect(saved.clientName, "Residencial Oliveira");
        expect(saved.equipmentCount, 1);
        final QuotePdfData data = store.quotePdfData(draftId);
        expect(data.status, "saved");
        expect(data.rendererVersion, newestPdfRenderer);
        expect(store.listQuotes(status: "draft").map((QuoteSummary q) => q.id).toSet(), {
          noLines,
          noClient,
        });
      },
    );

    test("AC-29 a saved quote refuses every write to its client, lines and texts", () async {
      final QuoteStore store = await openStore();
      final int un = unitId(store, "un");
      expect(store.addClient("Residencial Oliveira", "", "", "Rua das Flores, 142", ""), isTrue);
      final int clientId = store.lastClientId();
      expect(store.addClient("Comercio Santos", "", "", "Av. Central, 88", ""), isTrue);
      final int otherClientId = store.lastClientId();
      expect(store.addEquipment("Camera", "4MP", 42000, un), isTrue);
      final int cameraId = store.lastCatalogId(.equipment);
      expect(store.addEquipment("DVR", "8 canais", 89000, un), isTrue);
      final int dvrId = store.lastCatalogId(.equipment);
      expect(store.addService("Instalação", "Por ponto", 28000), isTrue);
      final int serviceId = store.lastCatalogId(.service);

      final int quoteId = store.createDraft();
      expect(store.setDraftClient(quoteId, clientId), isTrue);
      expect(store.addDraftLine(quoteId, .equipment, cameraId, 2), isTrue);
      expect(store.addDraftLine(quoteId, .service, serviceId, 1), isTrue);
      expect(store.setDraftTexts(quoteId, notes: "Original"), isTrue);
      expect(store.finalizeDraft(quoteId), isTrue);
      final String saved = quoteDocument(store, quoteId);

      expect(store.setDraftClient(quoteId, otherClientId), isFalse);
      expect(store.addDraftLine(quoteId, .equipment, dvrId, 1), isFalse);
      expect(store.addDraftLine(quoteId, .equipment, cameraId, 1), isFalse);
      expect(store.changeDraftLineQuantity(quoteId, .equipment, cameraId, 1), isFalse);
      expect(store.setDraftLineUnitPrice(quoteId, .equipment, cameraId, 1), isFalse);
      expect(store.setDraftLineDescription(quoteId, .service, serviceId, "Outra"), isFalse);
      expect(store.removeDraftLine(quoteId, .service, serviceId), isFalse);
      expect(
        store.setDraftTexts(
          quoteId,
          payment: "Boleto",
          warranty: "1 ano",
          validity: "5 dias",
          terms: "Novo",
          notes: "Mudou",
        ),
        isFalse,
      );
      expect(store.addNewCatalogLine(quoteId, .equipment, "sirene", "", 4500, un, 1), isFalse);

      expect(quoteDocument(store, quoteId), saved);
      expect(store.quotePdfData(quoteId).status, "saved");
    });

    test("AC-31 Editar copies a saved quote into an independent draft created today", () async {
      final QuoteStore store = await openStore();
      final int un = unitId(store, "un");
      expect(store.saveQuoteDefaults("PIX", "30 dias", "90 dias", "T"), isTrue);
      expect(
        store.addClient("Residencial Oliveira", "111", "o@x.com", "Rua das Flores, 142", "SP"),
        isTrue,
      );
      final int clientId = store.lastClientId();
      expect(store.addEquipment("Camera", "4MP", 42000, un), isTrue);
      final int cameraId = store.lastCatalogId(.equipment);
      expect(store.addService("Instalação", "Por ponto", 28000), isTrue);
      final int serviceId = store.lastCatalogId(.service);

      final int originalId = store.createDraft();
      expect(store.setDraftClient(originalId, clientId), isTrue);
      expect(store.addDraftLine(originalId, .equipment, cameraId, 2), isTrue);
      expect(store.setDraftLineUnitPrice(originalId, .equipment, cameraId, 40000), isTrue);
      expect(store.addDraftLine(originalId, .service, serviceId, 1), isTrue);
      expect(store.setDraftLineDescription(originalId, .service, serviceId, "Dois pontos"), isTrue);
      expect(store.addNewCatalogLine(originalId, .equipment, "placa", "", 640, un, 3), isTrue);
      expect(
        store.setDraftTexts(
          originalId,
          payment: "Cartão",
          warranty: "6 meses",
          validity: "15 dias",
          terms: "Termo próprio",
          notes: "Portão lateral",
        ),
        isTrue,
      );
      expect(store.finalizeDraft(originalId), isTrue);

      // The original was made long ago, and its client has changed since.
      final Database raw = sqlite3.open(path);
      raw.execute("UPDATE quotes SET created_at = ? WHERE id = ?", [
        DateTime(2020, 3, 4).millisecondsSinceEpoch,
        originalId,
      ]);
      raw.close();
      expect(store.updateClient(clientId, "Outro Nome", "999", "", "Av. Nova, 9", ""), isTrue);
      final String original = quoteDocument(store, originalId);
      final int originalCreatedAt = store.quotePdfData(originalId).createdAt;

      final int copyId = store.copyQuote(originalId);
      expect(copyId, greaterThan(0));
      expect(copyId, isNot(originalId));

      final QuotePdfData copy = store.quotePdfData(copyId);
      expect(copy.status, "draft");
      expect(copy.rendererVersion, newestPdfRenderer);
      final DateTime created = DateTime.fromMillisecondsSinceEpoch(copy.createdAt);
      final DateTime today = DateTime.now();
      expect([created.year, created.month, created.day], [today.year, today.month, today.day]);
      expect(quoteDocument(store, copyId), original);
      expect(store.quoteClient(copyId)?.address, "Rua das Flores, 142");
      expect(store.listQuoteLines(copyId).length, 3);
      expect(store.listQuoteLines(copyId).where((QuoteLine l) => l.isNew), isEmpty);

      expect(store.setDraftTexts(copyId, notes: "Mudou na cópia", payment: "Boleto"), isTrue);
      expect(store.setDraftLineUnitPrice(copyId, .equipment, cameraId, 1000), isTrue);
      expect(store.removeDraftLine(copyId, .service, serviceId), isTrue);
      expect(store.addClient("Comercio Santos", "", "", "", ""), isTrue);
      expect(store.setDraftClient(copyId, store.lastClientId()), isTrue);

      expect(quoteDocument(store, originalId), original);
      final QuotePdfData after = store.quotePdfData(originalId);
      expect(after.status, "saved");
      expect(after.createdAt, originalCreatedAt);
      expect(store.listQuotes(status: "saved").single.id, originalId);
    });

    test("AC-32 deleting a saved quote or a draft removes it and its lines", () async {
      final QuoteStore store = await openStore();
      expect(store.addClient("Residencial Oliveira", "", "", "", ""), isTrue);
      final int clientId = store.lastClientId();
      expect(store.addEquipment("Camera", "4MP", 42000, 0), isTrue);
      final int cameraId = store.lastCatalogId(.equipment);

      final int savedId = store.createDraft();
      expect(store.setDraftClient(savedId, clientId), isTrue);
      expect(store.addDraftLine(savedId, .equipment, cameraId, 1), isTrue);
      expect(store.finalizeDraft(savedId), isTrue);
      final int draftId = store.createDraft();
      expect(store.addDraftLine(draftId, .equipment, cameraId, 2), isTrue);
      final int keptId = store.createDraft();
      expect(store.addDraftLine(keptId, .equipment, cameraId, 3), isTrue);

      expect(store.deleteQuote(savedId), isTrue);
      expect(store.deleteQuote(draftId), isTrue);

      expect(store.listQuotes().single.id, keptId);
      expect(store.listQuoteLines(savedId), isEmpty);
      expect(store.listQuoteLines(draftId), isEmpty);
      expect(store.listQuoteLines(keptId).single.quantity, 3);
    });

    test("drafts persist across reopen and resume editable", () async {
      final QuoteStore first = QuoteStore(databasePath: path);
      expect(await first.open(), isTrue);
      expect(first.addClient("Persisted", "555", "", "Addr", "Town"), isTrue);
      final int clientId = first.lastClientId();
      expect(first.addEquipment("Sensor", "Door", 12000, 0), isTrue);
      final int draftId = first.createDraft();
      expect(first.setDraftClient(draftId, clientId), isTrue);
      expect(first.addDraftLine(draftId, .equipment, first.lastCatalogId(.equipment), 3), isTrue);
      expect(first.setDraftTexts(draftId, notes: "Persistente"), isTrue);
      first.dispose();

      final QuoteStore second = QuoteStore(databasePath: path);
      addTearDown(second.dispose);
      expect(await second.open(), isTrue);
      final QuoteSummary draft = second.listRecentQuotes().single;
      expect(draft.id, draftId);
      expect(draft.isDraft, isTrue);
      expect(draft.clientName, "Persisted");
      expect(draft.equipmentCount, 1);
      expect(second.listQuoteLines(draftId).single.quantity, 3);
      expect(second.quoteClient(draftId)?.name, "Persisted");
      expect(second.quotePdfData(draftId).notes, "Persistente");
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

      final int draftId = store.createDraft();
      expect(store.addDraftLine(draftId, .equipment, 404, 1), isFalse);
      expect(store.errors.codeAt(store.errors.count - 1), errMissingId);
    });

    test("unit CRUD and lookups", () async {
      final QuoteStore store = await openStore();
      final int seeded = store.listUnits().length;
      expect(store.addUnit("h", "Hour"), isTrue);
      expect(store.addUnit("m²", "Square meter"), isTrue);
      expect(store.listUnits().length, seeded + 2);
      final int hourId = store.listUnits().firstWhere((u) => u.abbreviation == "h").id;
      expect(store.unitById(hourId)!.abbreviation, "h");

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
      expect(second.quoteDefaults.showUnitPrice, isTrue);
      expect(second.pdfSettings.accentColour, "Navy Blue (default)");
    });

    test("database backup exports and restores through public store API", () async {
      final QuoteStore source = await openStore();
      expect(
        source.saveBusinessInfo(
          "Backup Co",
          "12.345.678/0001-90",
          "Rua Um, 10",
          "São Paulo",
          "SP",
          "111",
          "backup@co.com",
          Uint8List.fromList([1, 2, 3]),
        ),
        isTrue,
      );
      expect(source.saveQuoteDefaults("PIX", "15 days", "30 days", "Terms"), isTrue);
      expect(source.addClient("Backup Client", "", "", "", ""), isTrue);
      final int clientId = source.lastClientId();
      final int un = unitId(source, "un");
      expect(source.addEquipment("Backup Camera", "4MP", 42000, un), isTrue);
      final int itemId = source.lastCatalogId(.equipment);
      final int draftId = source.createDraft();
      expect(source.setDraftClient(draftId, clientId), isTrue);
      expect(source.addDraftLine(draftId, .equipment, itemId, 2), isTrue);
      expect(source.setDraftTexts(draftId, notes: "Backup notes"), isTrue);
      expect(source.finalizeDraft(draftId), isTrue);

      final Uint8List? backup = await source.exportBackupBytes();
      expect(backup, isNotNull);
      expect(String.fromCharCodes(backup!.take(13)), "SQLite format");

      final QuoteStore restored = QuoteStore(databasePath: "${directory.path}/restored.sqlite");
      addTearDown(restored.dispose);
      expect(await restored.open(), isTrue);
      expect(restored.addClient("Old Client", "", "", "", ""), isTrue);
      expect(await restored.importBackupBytes(backup), isTrue);

      expect(restored.businessInfo.name, "Backup Co");
      expect(restored.businessInfo.logo, Uint8List.fromList([1, 2, 3]));
      expect(restored.quoteDefaults.paymentMethod, "PIX");
      expect(restored.listClients().single.name, "Backup Client");
      expect(restored.listCatalog(.equipment).single.name, "Backup Camera");
      expect(restored.listQuotes(status: "saved").single.id, draftId);
      expect(restored.quoteTotal(draftId), 84000);
      expect(restored.quotePdfData(draftId).notes, "Backup notes");
      expect(restored.quoteClient(draftId)?.name, "Backup Client");
    });

    test("AC-F3 a v1 backup is refused with its own error and leaves the data untouched", () async {
      final String backupPath = "${directory.path}/old_backup.sqlite";
      writeV1Database(backupPath);
      final Uint8List backup = File(backupPath).readAsBytesSync();
      final QuoteStore store = await openStore();
      expect(store.addClient("Cliente Atual", "", "", "", ""), isTrue);
      final int draftId = store.createDraft();
      expect(store.setDraftTexts(draftId, notes: "Atual"), isTrue);

      expect(await store.importBackupBytes(backup), isFalse);

      expect(store.errors.codeAt(store.errors.count - 1), errBackupTooOld);
      expect(store.listClients().single.name, "Cliente Atual");
      expect(store.listQuotes().single.id, draftId);
      expect(store.quotePdfData(draftId).notes, "Atual");
      expect(store.listCatalog(.equipment), isEmpty);
    });

    test("search filters clients and returns all on empty query", () async {
      final QuoteStore store = await openStore();
      expect(store.addClient("Alpha Corp", "111", "a@x.com", "Rua A", "City A"), isTrue);
      expect(store.addClient("Beta Ltd", "222", "b@x.com", "Rua B", "City B"), isTrue);

      expect(store.searchClients("").length, 2);
      expect(store.searchClients("alpha").single.name, "Alpha Corp");
      expect(store.searchClients("222").single.name, "Beta Ltd");
      expect(store.searchClients("City A").single.name, "Alpha Corp");
      expect(store.searchClients("MISSING"), isEmpty);
    });

    test(
      "AC-F1 when the database rejects writes, quote edits and saving fail and change nothing",
      () async {
        final QuoteStore store = await openStore();
        final int un = unitId(store, "un");
        expect(store.addClient("Residencial Oliveira", "", "", "Rua das Flores, 142", ""), isTrue);
        final int clientId = store.lastClientId();
        expect(store.addClient("Comercio Santos", "", "", "Av. Central, 88", ""), isTrue);
        final int otherClientId = store.lastClientId();
        expect(store.addEquipment("Camera", "4MP", 42000, un), isTrue);
        final int cameraId = store.lastCatalogId(.equipment);
        expect(store.addEquipment("DVR", "8 canais", 89000, un), isTrue);
        final int dvrId = store.lastCatalogId(.equipment);
        final int draftId = store.createDraft();
        expect(store.setDraftClient(draftId, clientId), isTrue);
        expect(store.addDraftLine(draftId, .equipment, cameraId, 2), isTrue);
        final String before = quoteDocument(store, draftId);
        final int catalogSize = store.listCatalog(.equipment).length;

        rejectWrites();

        expect(store.addDraftLine(draftId, .equipment, dvrId, 1), isFalse);
        expect(store.latestErrorMessage(), contains("locked"));
        expect(store.addNewCatalogLine(draftId, .equipment, "sirene", "", 4500, un, 1), isFalse);
        expect(store.latestErrorMessage(), contains("locked"));
        expect(store.setDraftClient(draftId, otherClientId), isFalse);
        expect(store.latestErrorMessage(), contains("locked"));
        expect(store.setDraftTexts(draftId, warranty: "1 ano", notes: "Nova"), isFalse);
        expect(store.latestErrorMessage(), contains("locked"));
        expect(store.finalizeDraft(draftId), isFalse);
        expect(store.latestErrorMessage(), contains("locked"));

        expect(quoteDocument(store, draftId), before);
        expect(store.quotePdfData(draftId).status, "draft");
        expect(store.listCatalog(.equipment).length, catalogSize);
      },
    );

    test(
      "AC-F7 when the database rejects writes, copy and delete fail and no quote appears or goes",
      () async {
        final QuoteStore store = await openStore();
        expect(store.addClient("Residencial Oliveira", "", "", "", ""), isTrue);
        final int clientId = store.lastClientId();
        expect(store.addEquipment("Camera", "4MP", 42000, 0), isTrue);
        final int cameraId = store.lastCatalogId(.equipment);
        final int savedId = store.createDraft();
        expect(store.setDraftClient(savedId, clientId), isTrue);
        expect(store.addDraftLine(savedId, .equipment, cameraId, 1), isTrue);
        expect(store.finalizeDraft(savedId), isTrue);
        final int draftId = store.createDraft();
        expect(store.addDraftLine(draftId, .equipment, cameraId, 2), isTrue);
        final Set<int> ids = store.listQuotes().map((QuoteSummary q) => q.id).toSet();
        final String saved = quoteDocument(store, savedId);
        final String draft = quoteDocument(store, draftId);

        rejectWrites();

        expect(store.copyQuote(savedId), 0);
        expect(store.latestErrorMessage(), contains("locked"));
        expect(store.deleteQuote(savedId), isFalse);
        expect(store.deleteQuote(draftId), isFalse);
        expect(store.latestErrorMessage(), contains("locked"));

        expect(store.listQuotes().map((QuoteSummary q) => q.id).toSet(), ids);
        expect(quoteDocument(store, savedId), saved);
        expect(quoteDocument(store, draftId), draft);
      },
    );

    test("AC-F4 open returns false when the database cannot be opened or recreated", () async {
      final QuoteStore missingDirectory = QuoteStore(
        databasePath: "${directory.path}/missing/quotes.sqlite",
      );
      addTearDown(missingDirectory.dispose);
      expect(await missingDirectory.open(), isFalse);
      expect(missingDirectory.latestErrorMessage(), isNotEmpty);

      // A v1 file another connection holds exclusively cannot be wiped.
      writeV1Database(path);
      final Database holder = sqlite3.open(path);
      holder.execute("BEGIN EXCLUSIVE");
      holder.execute("INSERT INTO payment_methods (name) VALUES ('Dinheiro')");
      final QuoteStore blocked = QuoteStore(databasePath: path);
      addTearDown(blocked.dispose);
      expect(await blocked.open(), isFalse);
      expect(blocked.latestErrorMessage(), isNotEmpty);
      holder.execute("ROLLBACK");
      holder.close();

      final QuoteStore retried = await openStore();
      expect(retried.listClients(), isEmpty);
      expect(retried.listQuotes(), isEmpty);
    });
  });
}
