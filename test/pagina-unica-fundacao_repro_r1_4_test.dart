import "dart:io";

import "package:delforte/store/quote_store.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqlite3/sqlite3.dart";

void main() {
  late Directory directory;
  late String path;

  setUp(() {
    directory = Directory.systemTemp.createTempSync("repro_r1_4_");
    path = "${directory.path}/quotes.sqlite";
  });
  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  Future<(QuoteStore, int)> storeWithSavedQuote() async {
    final QuoteStore store = QuoteStore(databasePath: path);
    addTearDown(store.dispose);
    expect(await store.open(), isTrue);
    expect(store.addClient("Residencial Oliveira", "", "", "", ""), isTrue);
    final int clientId = store.lastClientId();
    expect(store.addEquipment("Camera", "4MP", 42000, 0), isTrue);
    final int cameraId = store.lastCatalogId(.equipment);
    final int savedId = store.createDraft();
    expect(store.setDraftClient(savedId, clientId), isTrue);
    expect(store.addDraftLine(savedId, .equipment, cameraId, 1), isTrue);
    expect(store.finalizeDraft(savedId), isTrue);
    return (store, savedId);
  }

  /// The database rejects the second statement of a compound write, as it does
  /// when the disk fills or an I/O error hits mid-operation.
  void rejectStatement(String trigger) {
    final Database other = sqlite3.open(path);
    other.execute(trigger);
    other.close();
  }

  String quotes(QuoteStore store) => store
      .listQuotes()
      .map((QuoteSummary q) => "${q.id}:${q.status}:${q.clientName}:${q.equipmentCount}")
      .join(", ");

  test("AC-F7 a copy that the database rejects midway creates no quote", () async {
    final (QuoteStore store, int savedId) = await storeWithSavedQuote();
    final String before = quotes(store);
    rejectStatement(
      "CREATE TRIGGER fail_lines BEFORE INSERT ON quote_lines BEGIN SELECT RAISE(ABORT, 'disk full'); END",
    );

    expect(store.copyQuote(savedId), 0);
    expect(quotes(store), before);
  });

  test("AC-F7 a delete that the database rejects midway leaves the saved quote whole", () async {
    final (QuoteStore store, int savedId) = await storeWithSavedQuote();
    final String before = quotes(store);
    final int totalBefore = store.quoteTotal(savedId);
    rejectStatement(
      "CREATE TRIGGER fail_quotes BEFORE DELETE ON quotes BEGIN SELECT RAISE(ABORT, 'disk full'); END",
    );

    expect(store.deleteQuote(savedId), isFalse);
    expect(quotes(store), before);
    expect(store.listQuoteLines(savedId), hasLength(1));
    expect(store.quoteTotal(savedId), totalBefore);
  });
}
