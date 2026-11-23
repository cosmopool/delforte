import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:delforte/pdf/quote_pdf.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqlite3/sqlite3.dart";

/// The words a PDF made by `package:pdf` draws, in drawing order, lower-cased.
///
/// Each text run is a hex string of indexes into its font's ToUnicode map, and
/// the font is named after its object number (`/F12 … Tf`), so decoding needs
/// only the objects and their streams.
String pdfText(Uint8List bytes) {
  final String raw = latin1.decode(bytes);
  final Map<int, String> dicts = {};
  final Map<int, String> streams = {};
  for (final RegExpMatch m in RegExp(r"(\d+) 0 obj(.*?)endobj", dotAll: true).allMatches(raw)) {
    final int id = int.parse(m.group(1)!);
    final String body = m.group(2)!;
    final int start = body.indexOf("stream");
    if (start < 0) {
      dicts[id] = body;
      continue;
    }
    final String dict = body.substring(0, start);
    dicts[id] = dict;
    int from = start + "stream".length;
    if (body[from] == "\r") from++;
    if (body[from] == "\n") from++;
    final int length = int.parse(RegExp(r"/Length (\d+)").firstMatch(dict)!.group(1)!);
    final List<int> data = latin1.encode(body.substring(from, from + length));
    streams[id] = latin1.decode(dict.contains("FlateDecode") ? zlib.decode(data) : data);
  }
  final Map<int, Map<int, int>> toUnicode = {};
  dicts.forEach((int id, String dict) {
    final RegExpMatch? ref = RegExp(r"/ToUnicode (\d+) 0 R").firstMatch(dict);
    if (ref == null) return;
    toUnicode[id] = {
      for (final RegExpMatch pair in RegExp(
        r"<([0-9A-Fa-f]{4})> <([0-9A-Fa-f]{4})>",
      ).allMatches(streams[int.parse(ref.group(1)!)]!))
        int.parse(pair.group(1)!, radix: 16): int.parse(pair.group(2)!, radix: 16),
    };
  });
  final List<String> words = [];
  for (final String content in streams.values) {
    Map<int, int> font = const {};
    for (final RegExpMatch op in RegExp(
      r"/F(\d+) [\d.]+ Tf|\[<([0-9A-Fa-f]*)>\]TJ",
    ).allMatches(content)) {
      if (op.group(1) != null) {
        font = toUnicode[int.parse(op.group(1)!)] ?? const {};
        continue;
      }
      final String hex = op.group(2)!;
      words.add(
        String.fromCharCodes([
          for (int i = 0; i < hex.length; i += 4)
            font[int.parse(hex.substring(i, i + 4), radix: 16)] ?? 0x3F,
        ]),
      );
    }
  }
  return words.join(" ").toLowerCase();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadPdfFonts);

  group("buildQuotePdf", () {
    late Directory directory;
    late String path;

    setUp(() {
      directory = Directory.systemTemp.createTempSync("quote_pdf_test_");
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

    int unitId(QuoteStore store, String abbreviation) {
      return store.listUnits().firstWhere((Unit u) => u.abbreviation == abbreviation).id;
    }

    /// A draft for "Residencial Oliveira" with one service and two equipment lines.
    int draftWithLines(QuoteStore store) {
      final int un = unitId(store, "un");
      expect(store.addClient("Residencial Oliveira", "", "", "Rua das Flores, 142", ""), isTrue);
      final int clientId = store.lastClientId();
      expect(store.addService("Instalação de câmeras", "Por ponto", 28000), isTrue);
      final int serviceId = store.lastCatalogId(.service);
      expect(store.addEquipment("Haste de canto", "", 3200, un), isTrue);
      final int hasteId = store.lastCatalogId(.equipment);
      expect(store.addEquipment("Fio de aço inox", "", 900, un), isTrue);
      final int fioId = store.lastCatalogId(.equipment);
      final int draftId = store.createDraft();
      expect(store.setDraftClient(draftId, clientId), isTrue);
      expect(store.addDraftLine(draftId, .service, serviceId, 1), isTrue);
      expect(
        store.setDraftLineDescription(draftId, .service, serviceId, "Quatro pontos com cabeamento"),
        isTrue,
      );
      expect(store.addDraftLine(draftId, .equipment, hasteId, 4), isTrue);
      expect(store.addDraftLine(draftId, .equipment, fioId, 10), isTrue);
      return draftId;
    }

    test(
      "AC-23 the PDF prints Serviço · Valor, the equipment table, the quote's Condições and Observações last",
      () async {
        final QuoteStore store = await openStore();
        expect(store.saveQuoteDefaults("Dinheiro", "7 dias", "1 ano", "Padrão antigo"), isTrue);
        final int draftId = draftWithLines(store);
        expect(
          store.setDraftTexts(
            draftId,
            payment: "Cartão em 3x",
            warranty: "6 meses",
            validity: "15 dias",
            terms: "Visita técnica inclusa",
            notes: "Levar escada extensível",
          ),
          isTrue,
        );
        expect(store.saveQuoteDefaults("Boleto", "60 dias", "2 anos", "Padrão novo"), isTrue);

        final Uint8List? pdf = await buildQuotePdf(store.businessInfo, store.quotePdfData(draftId));

        expect(pdf, isNotNull);
        expect(pdf!.take(4), "%PDF".codeUnits);
        final String text = pdfText(pdf);

        final int servicesHeader = text.indexOf(RegExp(r"serviço\s+(·\s+)?valor"));
        expect(servicesHeader, greaterThanOrEqualTo(0), reason: text);
        final int serviceName = text.indexOf("instalação de câmeras", servicesHeader);
        final int serviceDescription = text.indexOf("quatro pontos com cabeamento", servicesHeader);
        expect(serviceName, greaterThan(servicesHeader), reason: text);
        expect(serviceDescription, greaterThan(serviceName), reason: text);

        final int equipmentHeader = text.indexOf(
          RegExp(r"descrição\s+qtd\s+un\S*\s+preço\s+total"),
        );
        expect(equipmentHeader, greaterThan(serviceDescription), reason: text);
        expect(RegExp("qtd").allMatches(text).length, 1, reason: text);
        expect(text.indexOf("haste de canto", equipmentHeader), greaterThan(equipmentHeader));
        expect(text.indexOf("fio de aço inox", equipmentHeader), greaterThan(equipmentHeader));

        for (final String condition in [
          "cartão em 3x",
          "6 meses",
          "15 dias",
          "visita técnica inclusa",
        ]) {
          expect(text, contains(condition));
        }
        for (final String padrao in [
          "dinheiro",
          "1 ano",
          "7 dias",
          "padrão antigo",
          "boleto",
          "2 anos",
          "60 dias",
          "padrão novo",
        ]) {
          expect(text, isNot(contains(padrao)));
        }

        expect(text, contains("termos"));
        expect(text, isNot(contains("termos e condições")));
        final int terms = text.indexOf("visita técnica inclusa");
        final int notesLabel = text.indexOf("observações");
        final int notes = text.indexOf("levar escada extensível");
        expect(notesLabel, greaterThan(terms), reason: text);
        expect(notes, greaterThan(notesLabel), reason: text);
        expect(notes, greaterThan(text.indexOf("fio de aço inox")), reason: text);
        expect(notes, greaterThan(text.indexOf("cartão em 3x")), reason: text);
      },
    );

    test("AC-24 an empty Garantia or Termos is left out with no fallback text", () async {
      final QuoteStore store = await openStore();
      final int draftId = draftWithLines(store);
      expect(
        store.setDraftTexts(
          draftId,
          payment: "PIX",
          warranty: "",
          validity: "15 dias",
          terms: "",
          notes: "",
        ),
        isTrue,
      );

      final Uint8List? pdf = await buildQuotePdf(store.businessInfo, store.quotePdfData(draftId));

      expect(pdf, isNotNull);
      final String text = pdfText(pdf!);
      expect(text, contains("pix"));
      expect(text, contains("15 dias"));
      expect(text, isNot(contains("garantia")));
      expect(text, isNot(contains("termos")));
      expect(text, isNot(contains("90 dias")));
    });

    test("AC-25 rendering a draft's PDF leaves it a draft", () async {
      final QuoteStore store = await openStore();
      final int draftId = draftWithLines(store);

      final Uint8List? pdf = await buildQuotePdf(store.businessInfo, store.quotePdfData(draftId));

      expect(pdf, isNotNull);
      expect(pdfText(pdf!), contains("residencial oliveira"));
      final QuoteSummary summary = store.listQuotes().single;
      expect(summary.id, draftId);
      expect(summary.isDraft, isTrue);
      expect(store.quotePdfData(draftId).status, "draft");
    });

    test("AC-19 a line whose catalog item was deleted is still printed from its copy", () async {
      final QuoteStore store = await openStore();
      final int draftId = draftWithLines(store);
      final int hasteId = store
          .listCatalog(.equipment)
          .firstWhere((CatalogItem i) => i.name == "Haste de canto")
          .id;

      expect(store.deleteEquipment(hasteId), isTrue);
      final Uint8List? pdf = await buildQuotePdf(store.businessInfo, store.quotePdfData(draftId));

      expect(pdf, isNotNull);
      expect(pdfText(pdf!), contains("haste de canto"));
    });

    test(
      "AC-28, AC-F6 a saved quote renders with its stored renderer version, a draft with the newest, and an unknown version reports an error without writing",
      () async {
        final QuoteStore store = await openStore();
        final int savedId = draftWithLines(store);
        expect(store.finalizeDraft(savedId), isTrue);
        expect(store.quotePdfData(savedId).rendererVersion, newestPdfRenderer);
        final Uint8List? current = await buildQuotePdf(
          store.businessInfo,
          store.quotePdfData(savedId),
        );
        expect(current, isNotNull);
        expect(pdfText(current!), contains("residencial oliveira"));

        // The quote was saved by a renderer this build does not have.
        final Database raw = sqlite3.open(path);
        raw.execute("UPDATE quotes SET renderer_version = 42 WHERE id = ?", [savedId]);
        raw.close();
        final QuotePdfData stored = store.quotePdfData(savedId);
        expect(stored.rendererVersion, 42);
        final QuoteSummary before = store.listQuotes().single;

        final Uint8List? unknown = await buildQuotePdf(store.businessInfo, stored);

        expect(unknown, isNull);
        final QuoteSummary after = store.listQuotes().single;
        expect(after.updatedAt, before.updatedAt);
        expect(after.isDraft, isFalse);
        expect(store.quotePdfData(savedId).rendererVersion, 42);

        // Its Editar copy is a draft, so it renders with the newest version.
        final int copyId = store.copyQuote(savedId);
        expect(copyId, greaterThan(0));
        final QuotePdfData copy = store.quotePdfData(copyId);
        expect(copy.rendererVersion, newestPdfRenderer);
        final Uint8List? copyPdf = await buildQuotePdf(store.businessInfo, copy);
        expect(copyPdf, isNotNull);
        expect(pdfText(copyPdf!), contains("residencial oliveira"));
        expect(store.quotePdfData(savedId).rendererVersion, 42);
      },
    );

    test("the PDF footer renders the company contact items", () async {
      final QuoteStore store = await openStore();
      expect(
        store.saveBusinessInfo(
          "Delforte Sistemas",
          "12.345.678/0001-90",
          "Rua das Palmeiras, 200",
          "São Paulo",
          "SP",
          "+55 (11) 98888-0000",
          "contato@delforte.com.br",
          Uint8List(0),
        ),
        isTrue,
      );
      final int draftId = draftWithLines(store);

      final Uint8List? pdf = await buildQuotePdf(store.businessInfo, store.quotePdfData(draftId));

      expect(pdf, isNotNull);
      expect(pdf!.length, greaterThan(1000));
      expect(pdfText(pdf), contains("contato@delforte.com.br"));
    });
  });
}
