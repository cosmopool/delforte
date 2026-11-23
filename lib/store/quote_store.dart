import "dart:io";
import "dart:math" as math;

import "package:delforte/store/business_info_data.dart";
import "package:delforte/store/models.dart";
import "package:delforte/store/pdf_settings_data.dart";
import "package:delforte/store/quote_defaults_data.dart";
import "package:delforte/store/store_errors.dart";
import "package:flutter/foundation.dart";
import "package:path_provider/path_provider.dart";
import "package:sqlite3/sqlite3.dart";

export "package:delforte/store/models.dart";

/// Public notifier wrapper used by store tables.
class StoreNotifier extends ChangeNotifier {
  /// Notifies listeners that the associated store data changed.
  void markChanged() => notifyListeners();
}

/// SQLite-backed quote module store.
///
/// SQLite is the single source of truth; every read is a query and every write
/// goes straight to the database, then fires the matching notifier so listening
/// widgets re-query.
class QuoteStore {
  /// Creates a store.
  ///
  /// If [databasePath] is omitted, [open] uses the app documents directory.
  QuoteStore({String? databasePath})
    : _databasePath = databasePath,
      errors = ErrorLogBuffer(256),
      businessInfo = BusinessInfoData(),
      quoteDefaults = QuoteDefaultsData(),
      pdfSettings = PdfSettingsData();

  /// Error side-channel for failed operations.
  final ErrorLogBuffer errors;

  /// Business info singleton mirrored from SQLite.
  final BusinessInfoData businessInfo;

  /// Quote defaults singleton mirrored from SQLite.
  final QuoteDefaultsData quoteDefaults;

  /// PDF appearance settings singleton mirrored from SQLite.
  final PdfSettingsData pdfSettings;

  /// Notifies when equipment rows change.
  final StoreNotifier equipmentNotifier = StoreNotifier();

  /// Notifies when service rows change.
  final StoreNotifier servicesNotifier = StoreNotifier();

  /// Notifies when client rows change.
  final StoreNotifier clientsNotifier = StoreNotifier();

  /// Notifies when quote or draft rows change.
  final StoreNotifier quotesNotifier = StoreNotifier();

  /// Notifies when unit rows change.
  final StoreNotifier unitsNotifier = StoreNotifier();

  /// Notifies when [errors] changes.
  final StoreNotifier errorsNotifier = StoreNotifier();

  /// Notifies when payment method rows change.
  final StoreNotifier paymentMethodsNotifier = StoreNotifier();

  /// Notifies when any singleton settings change.
  final StoreNotifier settingsNotifier = StoreNotifier();

  final String? _databasePath;
  Database? _db;
  String? _openDatabasePath;

  /// Opens SQLite, migrates schema, and loads the singleton settings rows.
  ///
  /// Returns `false` and appends to [errors] on failure.
  Future<bool> open() async {
    if (kIsWeb) return _fail(errWebUnsupported, "Web unsupported");
    try {
      final String path;
      if (_databasePath == null) {
        final Directory directory = await getApplicationDocumentsDirectory();
        path = "${directory.path}/delforte_quotes.sqlite";
      } else {
        path = _databasePath;
      }
      _openDatabasePath = path;
      final Database db = sqlite3.open(path);
      _db = db;
      db.execute("PRAGMA journal_mode = WAL;");
      db.execute("PRAGMA synchronous = NORMAL;");
      db.execute("PRAGMA foreign_keys = ON;");
      if (!_migrate(db)) return false;
      if (!_loadSettings(db)) return false;
      return true;
    } catch (error) {
      return _fail(errDbOpen, error.toString());
    }
  }

  /// Closes SQLite and disposes all notifiers.
  void dispose() {
    _db?.close();
    _openDatabasePath = null;
    equipmentNotifier.dispose();
    servicesNotifier.dispose();
    clientsNotifier.dispose();
    unitsNotifier.dispose();
    quotesNotifier.dispose();
    errorsNotifier.dispose();
    paymentMethodsNotifier.dispose();
    settingsNotifier.dispose();
  }

  // ── CLIENTS ───────────────────────────────────────────────────────────────

  /// Returns all clients, newest first.
  List<Client> listClients() {
    return _queryClients(
      "SELECT id, name, phone, email, address, city FROM clients ORDER BY id DESC",
    );
  }

  /// Returns clients whose any text field contains [query] (case-insensitive).
  ///
  /// An empty [query] returns every client.
  List<Client> searchClients(String query) {
    final String q = query.trim();
    if (q.isEmpty) return listClients();
    final String like = "%${q.toLowerCase()}%";
    return _queryClients(
      "SELECT id, name, phone, email, address, city FROM clients "
      "WHERE lower(name) LIKE ? OR lower(phone) LIKE ? OR lower(email) LIKE ? "
      "OR lower(address) LIKE ? OR lower(city) LIKE ? ORDER BY id DESC",
      [like, like, like, like, like],
    );
  }

  /// Returns the client with [id], or `null` when absent.
  Client? clientById(int id) {
    final List<Client> rows = _queryClients(
      "SELECT id, name, phone, email, address, city FROM clients WHERE id = ?",
      [id],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Inserts a client and returns whether it succeeded.
  bool addClient(String name, String phone, String email, String address, String city) {
    if (!_validName(name)) return _fail(errInvalidInput, "Client name required");
    return _write(clientsNotifier, (Database db) {
      db.execute("INSERT INTO clients (name, phone, email, address, city) VALUES (?, ?, ?, ?, ?)", [
        name,
        phone,
        email,
        address,
        city,
      ]);
    });
  }

  /// Returns the id of the most recently inserted client, or `0` when none.
  int lastClientId() => _lastId("clients");

  /// Updates a client by [id].
  bool updateClient(int id, String name, String phone, String email, String address, String city) {
    if (!_validName(name)) return _fail(errInvalidInput, "Client name required");
    return _write(clientsNotifier, (Database db) {
      db.execute(
        "UPDATE clients SET name = ?, phone = ?, email = ?, address = ?, city = ? WHERE id = ?",
        [name, phone, email, address, city, id],
      );
    });
  }

  /// Deletes a client by [id].
  bool deleteClient(int id) {
    return _write(clientsNotifier, (Database db) {
      db.execute("DELETE FROM clients WHERE id = ?", [id]);
    });
  }

  // ── CATALOG (equipment + services) ──────────────────────────────────────────

  /// Returns all catalog rows of [type], newest first.
  List<CatalogItem> listCatalog(CatalogItemType type) {
    return _queryCatalog("SELECT * FROM ${_catalogTable(type)} ORDER BY id DESC");
  }

  /// Returns catalog rows of [type] whose name or description contains [query],
  /// ignoring accents and case.
  ///
  /// An empty [query] returns every row.
  List<CatalogItem> searchCatalog(CatalogItemType type, String query) {
    final String q = _fold(query.trim());
    return [
      for (final CatalogItem item in listCatalog(type))
        if (_fold("${item.name}\n${item.description}").contains(q)) item,
    ];
  }

  /// Returns the catalog row of [type] with [id], or `null` when absent.
  CatalogItem? catalogById(CatalogItemType type, int id) {
    final List<CatalogItem> rows = _queryCatalog(
      "SELECT * FROM ${_catalogTable(type)} WHERE id = ?",
      [id],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Inserts equipment and returns whether it succeeded.
  bool addEquipment(String name, String description, int priceCents, int unitId) {
    return _addCatalog(.equipment, name, description, priceCents, unitId);
  }

  /// Inserts a service (services have no unit) and returns whether it succeeded.
  bool addService(String name, String description, int priceCents) {
    return _addCatalog(.service, name, description, priceCents, 0);
  }

  /// Updates equipment by [id].
  bool updateEquipment(int id, String name, String description, int priceCents, int unitId) {
    return _updateCatalog(.equipment, id, name, description, priceCents, unitId);
  }

  /// Updates a service by [id].
  bool updateService(int id, String name, String description, int priceCents) {
    return _updateCatalog(.service, id, name, description, priceCents, 0);
  }

  /// Deletes equipment by [id]; quote lines keep their own copy.
  bool deleteEquipment(int id) {
    return _deleteCatalog(.equipment, id);
  }

  /// Deletes a service by [id]; quote lines keep their own copy.
  bool deleteService(int id) {
    return _deleteCatalog(.service, id);
  }

  /// Returns the id of the most recently inserted catalog row of [type].
  int lastCatalogId(CatalogItemType type) => _lastId(_catalogTable(type));

  // ── UNITS ───────────────────────────────────────────────────────────────────

  /// Returns all units, newest first.
  List<Unit> listUnits() {
    return _queryUnits("SELECT id, abbreviation, description FROM units ORDER BY id DESC");
  }

  /// Returns the unit with [id], or `null` when absent.
  Unit? unitById(int id) {
    final List<Unit> rows = _queryUnits(
      "SELECT id, abbreviation, description FROM units WHERE id = ?",
      [id],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Inserts a unit and returns whether it succeeded.
  bool addUnit(String abbreviation, String description) {
    if (!_validName(abbreviation)) return _fail(errInvalidInput, "Unit abbreviation required");
    return _write(unitsNotifier, (Database db) {
      db.execute("INSERT INTO units (abbreviation, description) VALUES (?, ?)", [
        abbreviation,
        description,
      ]);
    });
  }

  /// Returns the id of the most recently inserted unit, or `0` when none.
  int lastUnitId() => _lastId("units");

  /// Updates a unit by [id].
  bool updateUnit(int id, String abbreviation, String description) {
    if (!_validName(abbreviation)) return _fail(errInvalidInput, "Unit abbreviation required");
    return _write(unitsNotifier, (Database db) {
      db.execute("UPDATE units SET abbreviation = ?, description = ? WHERE id = ?", [
        abbreviation,
        description,
        id,
      ]);
    });
  }

  /// Deletes a unit by [id].
  bool deleteUnit(int id) {
    return _write(unitsNotifier, (Database db) {
      db.execute("DELETE FROM units WHERE id = ?", [id]);
    });
  }

  // ── DRAFTS & QUOTES ─────────────────────────────────────────────────────────

  /// Creates a draft with no client and a copy of the Padrões, and returns its
  /// id, or `0` on failure.
  int createDraft() {
    final int now = _nowMillis();
    final bool created = _write(quotesNotifier, (Database db) {
      db.execute(
        "INSERT INTO quotes (created_at, updated_at, payment, warranty, validity, terms, show_unit_price) "
        "SELECT ?, ?, payment_method, warranty, validity, terms, show_unit_price FROM quote_defaults",
        [now, now],
      );
    });
    if (!created) return 0;
    return _db!.lastInsertRowId;
  }

  /// Copies client [clientId] into draft [quoteId]; later edits to the client
  /// do not reach the quote.
  bool setDraftClient(int quoteId, int clientId) {
    return _writeDraft(quoteId, (Database db) {
      db.execute(
        "UPDATE quotes SET (client_id, client_name, client_phone, client_email, client_address, client_city) = "
        "(SELECT id, name, phone, email, address, city FROM clients WHERE id = ?) WHERE id = ?",
        [clientId, quoteId],
      );
    });
  }

  /// Returns the client copied into [quoteId], or `null` when it has none.
  Client? quoteClient(int quoteId) => quotePdfData(quoteId).client;

  /// Sets the Condições and Observações of draft [quoteId]; a `null` text stays as it is.
  bool setDraftTexts(
    int quoteId, {
    String? payment,
    String? warranty,
    String? validity,
    String? terms,
    String? notes,
  }) {
    return _writeDraft(quoteId, (Database db) {
      db.execute(
        "UPDATE quotes SET payment = COALESCE(?, payment), warranty = COALESCE(?, warranty), "
        "validity = COALESCE(?, validity), terms = COALESCE(?, terms), notes = COALESCE(?, notes) "
        "WHERE id = ?",
        [payment, warranty, validity, terms, notes, quoteId],
      );
    });
  }

  /// Adds a line to draft [quoteId] with its own copy of catalog item [refId].
  ///
  /// An equipment already on the quote sums [quantity] (up to 9999) and keeps its
  /// own price; a service already on the quote is left as it is.
  bool addDraftLine(int quoteId, CatalogItemType type, int refId, int quantity) {
    if (quantity <= 0) return _fail(errInvalidInput, "Invalid quantity");
    final CatalogItem? item = catalogById(type, refId);
    if (item == null) return _fail(errMissingId, "Catalog ref missing");
    final String unit = unitById(item.unitId)?.abbreviation ?? "";
    return _writeDraft(quoteId, (Database db) {
      db.execute(
        "INSERT INTO quote_lines (quote_id, line_type, ref_id, quantity, unit_price_cents, subtotal_cents, name, description, unit) "
        "VALUES (?1, ?2, ?3, ?4, ?5, ?4 * ?5, ?6, ?7, ?8) "
        "ON CONFLICT(quote_id, line_type, ref_id) DO UPDATE SET "
        "quantity = min(9999, quote_lines.quantity + ?4), "
        "subtotal_cents = min(9999, quote_lines.quantity + ?4) * quote_lines.unit_price_cents "
        "WHERE quote_lines.line_type = ${CatalogItemType.equipment.index}",
        [quoteId, type.index, refId, quantity, item.priceCents, item.name, item.description, unit],
      );
    });
  }

  /// Item novo: adds [name] (first letter capitalised) to the catalog and a line
  /// for it to draft [quoteId], flagged "novo no catálogo" until the quote is saved.
  bool addNewCatalogLine(
    int quoteId,
    CatalogItemType type,
    String name,
    String description,
    int priceCents,
    int unitId,
    int quantity,
  ) {
    // A saved quote, or a database that rejects writes, must not grow the catalog.
    if (!_writeDraft(quoteId, (Database db) {})) return false;
    final String capitalised = name.trim().replaceFirstMapped(
      RegExp("^."),
      (Match m) => m[0]!.toUpperCase(),
    );
    if (!_addCatalog(type, capitalised, description, priceCents, unitId)) return false;
    final int refId = lastCatalogId(type);
    if (!addDraftLine(quoteId, type, refId, quantity)) return false;
    return _writeDraft(quoteId, (Database db) {
      db.execute(
        "UPDATE quote_lines SET is_new = 1 WHERE quote_id = ? AND line_type = ? AND ref_id = ?",
        [quoteId, type.index, refId],
      );
    });
  }

  /// Sets the description of a draft line, on this quote only.
  bool setDraftLineDescription(int quoteId, CatalogItemType type, int refId, String description) {
    return _writeDraft(quoteId, (Database db) {
      db.execute(
        "UPDATE quote_lines SET description = ? WHERE quote_id = ? AND line_type = ? AND ref_id = ?",
        [description, quoteId, type.index, refId],
      );
    });
  }

  /// Changes a draft line quantity by [delta].
  ///
  /// Deletes the line below `1` and clamps it to `9999` at the upper bound.
  bool changeDraftLineQuantity(int quoteId, CatalogItemType type, int refId, int delta) {
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    final int current = _lineQuantity(db, quoteId, type, refId);
    if (current < 0) return _fail(errMissingId, "Quote line missing");
    if (current + delta < 1) return removeDraftLine(quoteId, type, refId);
    final int next = math.min(9999, current + delta);
    return _writeDraft(quoteId, (Database db) {
      db.execute(
        "UPDATE quote_lines SET quantity = ?, subtotal_cents = unit_price_cents * ? "
        "WHERE quote_id = ? AND line_type = ? AND ref_id = ?",
        [next, next, quoteId, type.index, refId],
      );
    });
  }

  /// Sets the unit price of an existing draft line and recomputes its subtotal.
  ///
  /// A no-op (still returns `true`) when no matching line exists.
  bool setDraftLineUnitPrice(int quoteId, CatalogItemType type, int refId, int priceCents) {
    if (priceCents < 0) return _fail(errInvalidInput, "Invalid price");
    return _writeDraft(quoteId, (Database db) {
      db.execute(
        "UPDATE quote_lines SET unit_price_cents = ?, subtotal_cents = quantity * ? "
        "WHERE quote_id = ? AND line_type = ? AND ref_id = ?",
        [priceCents, priceCents, quoteId, type.index, refId],
      );
    });
  }

  /// Removes a draft line by [type] and [refId].
  bool removeDraftLine(int quoteId, CatalogItemType type, int refId) {
    return _writeDraft(quoteId, (Database db) {
      db.execute("DELETE FROM quote_lines WHERE quote_id = ? AND line_type = ? AND ref_id = ?", [
        quoteId,
        type.index,
        refId,
      ]);
    });
  }

  /// Returns the lines of [quoteId], each with its own copy of the catalog item.
  List<QuoteLine> listQuoteLines(int quoteId) {
    final Database? db = _db;
    if (db == null) return const <QuoteLine>[];
    final ResultSet rows = db.select(
      "SELECT * FROM quote_lines WHERE quote_id = ? ORDER BY rowid ASC",
      [quoteId],
    );
    return [
      for (final Row row in rows)
        QuoteLine(
          type: CatalogItemType.values[row["line_type"] as int],
          refId: row["ref_id"] as int,
          name: row["name"] as String,
          description: row["description"] as String,
          unit: row["unit"] as String,
          quantity: row["quantity"] as int,
          unitPriceCents: row["unit_price_cents"] as int,
          subtotalCents: row["subtotal_cents"] as int,
          isNew: row["is_new"] == 1,
        ),
    ];
  }

  /// Gathers the whole quote document in a single query: its state, client copy,
  /// Condições, Observações, renderer version and every line copy.
  QuotePdfData quotePdfData(int quoteId) {
    final ResultSet? rows = _db?.select(
      "SELECT q.*, l.* FROM quotes q LEFT JOIN quote_lines l ON l.quote_id = q.id "
      "WHERE q.id = ? ORDER BY l.rowid ASC",
      [quoteId],
    );
    if (rows == null || rows.isEmpty) {
      return const QuotePdfData(
        id: 0,
        createdAt: 0,
        status: "",
        client: null,
        payment: "",
        warranty: "",
        validity: "",
        terms: "",
        notes: "",
        rendererVersion: newestPdfRenderer,
        showUnitPrice: true,
        equipmentPriceMode: 0,
        closedTotalCents: 0,
        markupPercent: 0,
        lines: [],
      );
    }
    final Row head = rows.first;
    final Object? clientId = head["client_id"];
    Client? client;
    if (clientId != null) {
      client = Client(
        id: clientId as int,
        name: head["client_name"] as String,
        phone: head["client_phone"] as String,
        email: head["client_email"] as String,
        address: head["client_address"] as String,
        city: head["client_city"] as String,
      );
    }
    final List<QuotePdfLine> lines = [
      for (final Row row in rows)
        if (row["line_type"] != null)
          QuotePdfLine(
            type: CatalogItemType.values[row["line_type"] as int],
            name: row["name"] as String,
            description: row["description"] as String,
            quantity: row["quantity"] as int,
            unit: row["unit"] as String,
            unitPriceCents: row["unit_price_cents"] as int,
            subtotalCents: row["subtotal_cents"] as int,
          ),
    ];
    final String status = head["status"] as String;
    return QuotePdfData(
      id: quoteId,
      createdAt: head["created_at"] as int,
      status: status,
      client: client,
      payment: head["payment"] as String,
      warranty: head["warranty"] as String,
      validity: head["validity"] as String,
      terms: head["terms"] as String,
      notes: head["notes"] as String,
      // A draft always renders with the newest renderer; a saved quote keeps its own.
      rendererVersion: status == "draft" ? newestPdfRenderer : head["renderer_version"] as int,
      showUnitPrice: head["show_unit_price"] == 1,
      equipmentPriceMode: head["equipment_price_mode"] as int,
      closedTotalCents: head["closed_total_cents"] as int,
      markupPercent: head["markup_percent"] as int,
      lines: lines,
    );
  }

  /// Returns the total in cents for [quoteId].
  int quoteTotal(int quoteId) => _sumSubtotals(quoteId);

  /// Returns the subtotal in cents for [quoteId] limited to [type].
  int quoteSubtotal(int quoteId, CatalogItemType type) => _sumSubtotals(quoteId, type);

  /// Returns the number of lines of [type] in [quoteId].
  int quoteLineCount(int quoteId, CatalogItemType type) {
    final Database? db = _db;
    if (db == null) return 0;
    final ResultSet rows = db.select(
      "SELECT COUNT(*) AS c FROM quote_lines WHERE quote_id = ? AND line_type = ?",
      [quoteId, type.index],
    );
    if (rows.isEmpty) return 0;
    return rows.first["c"] as int;
  }

  /// Saves a draft that has a client and at least one line: stamps the total and
  /// the newest renderer version, clears the "novo no catálogo" flags and flips it
  /// to a saved quote, which refuses every later write.
  bool finalizeDraft(int quoteId) {
    final QuotePdfData data = quotePdfData(quoteId);
    if (data.client == null) return _fail(errMissingId, "Client missing");
    if (data.lines.isEmpty) return _fail(errQuoteEmpty, "Quote empty");
    final int total = quoteTotal(quoteId);
    return _writeDraft(quoteId, (Database db) {
      db.execute("UPDATE quote_lines SET is_new = 0 WHERE quote_id = ?", [quoteId]);
      db.execute(
        "UPDATE quotes SET total_cents = ?, status = 'saved', renderer_version = ? WHERE id = ?",
        [total, newestPdfRenderer, quoteId],
      );
    });
  }

  /// Editar: copies [quoteId] into a new draft created now, with the same client
  /// copy, lines (no "novo" flags), Condições, Observações and Preço dos
  /// equipamentos fields. Returns the new id, or `0` on failure.
  int copyQuote(int quoteId) {
    const String copied =
        "client_id, client_name, client_phone, client_email, client_address, client_city, "
        "payment, warranty, validity, terms, notes, "
        "show_unit_price, equipment_price_mode, closed_total_cents, markup_percent";
    final int now = _nowMillis();
    int copyId = 0;
    _write(quotesNotifier, (Database db) {
      db.execute(
        "INSERT INTO quotes ($copied, created_at, updated_at) SELECT $copied, ?, ? FROM quotes WHERE id = ?",
        [now, now, quoteId],
      );
      final int id = db.lastInsertRowId;
      db.execute(
        "INSERT INTO quote_lines (quote_id, line_type, ref_id, name, description, unit, quantity, unit_price_cents, subtotal_cents) "
        "SELECT ?, line_type, ref_id, name, description, unit, quantity, unit_price_cents, subtotal_cents "
        "FROM quote_lines WHERE quote_id = ? ORDER BY rowid",
        [id, quoteId],
      );
      copyId = id;
    });
    return copyId;
  }

  /// Deletes a quote (and its lines) by [quoteId].
  bool deleteQuote(int quoteId) {
    return _write(quotesNotifier, (Database db) {
      db.execute("DELETE FROM quote_lines WHERE quote_id = ?", [quoteId]);
      db.execute("DELETE FROM quotes WHERE id = ?", [quoteId]);
    });
  }

  /// Deletes [quoteId] only if it is still a draft with no client and no lines.
  ///
  /// Used to clean up drafts the user abandoned before adding anything.
  void deleteDraftIfEmpty(int quoteId) {
    final Database? db = _db;
    if (db == null) return;
    final ResultSet rows = db.select(
      "SELECT (SELECT COUNT(*) FROM quote_lines WHERE quote_id = q.id) AS lines "
      "FROM quotes q WHERE q.id = ? AND q.status = 'draft' AND q.client_id IS NULL",
      [quoteId],
    );
    if (rows.isEmpty) return;
    if ((rows.first["lines"] as int) == 0) deleteQuote(quoteId);
  }

  /// Returns the most recent quotes (drafts and saved), newest first.
  List<QuoteSummary> listRecentQuotes({int limit = 3}) => _queryQuotes(limit: limit);

  /// Returns all quotes, optionally filtered by [status], newest first.
  List<QuoteSummary> listQuotes({String? status}) => _queryQuotes(status: status);

  /// Returns the most recent error message, or `""` when there are no errors.
  String latestErrorMessage() {
    if (errors.count == 0) return "";
    return errors.messageAt(errors.count - 1);
  }

  /// Default filename for a database backup created now.
  String backupFileName([DateTime? now]) {
    final DateTime stamp = now ?? DateTime.now();
    final String date = "${stamp.year}${_twoDigits(stamp.month)}${_twoDigits(stamp.day)}";
    final String time =
        "${_twoDigits(stamp.hour)}${_twoDigits(stamp.minute)}${_twoDigits(stamp.second)}";
    return "delforte_backup_${date}_$time.sqlite";
  }

  /// Returns a consistent SQLite database backup as bytes.
  Future<Uint8List?> exportBackupBytes() async {
    final Database? db = _db;
    if (db == null) {
      _fail(errDbOpen, "DB not open");
      return null;
    }
    Directory? tempDirectory;
    Database? backupDb;
    try {
      tempDirectory = await Directory.systemTemp.createTemp("delforte_backup_");
      final String tempPath = "${tempDirectory.path}/backup.sqlite";
      backupDb = sqlite3.open(tempPath);
      await db.backup(backupDb, nPage: -1).drain<void>();
      backupDb.close();
      backupDb = null;
      return await File(tempPath).readAsBytes();
    } catch (error) {
      _fail(errDbBackup, error.toString());
      return null;
    } finally {
      backupDb?.close();
      if (tempDirectory != null && tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  /// Replaces the live database with a validated SQLite backup.
  Future<bool> importBackupBytes(Uint8List bytes) async {
    final Database? db = _db;
    final String? path = _openDatabasePath;
    if (db == null || path == null) return _fail(errDbOpen, "DB not open");
    if (bytes.isEmpty) return _fail(errInvalidInput, "Backup is empty");
    Directory? tempDirectory;
    Database? sourceDb;
    try {
      tempDirectory = await Directory.systemTemp.createTemp("delforte_import_");
      final String tempPath = "${tempDirectory.path}/import.sqlite";
      await File(tempPath).writeAsBytes(bytes, flush: true);
      sourceDb = sqlite3.open(tempPath);
      if (!_validateBackup(sourceDb)) return false;

      await sourceDb.backup(db, nPage: -1).drain<void>();
      db.execute("PRAGMA journal_mode = WAL;");
      db.execute("PRAGMA synchronous = NORMAL;");
      db.execute("PRAGMA foreign_keys = ON;");
      if (!_migrate(db)) return false;
      if (!_loadSettings(db)) return false;
      _markAllChanged();
      return true;
    } catch (error) {
      return _fail(errDbBackup, error.toString());
    } finally {
      sourceDb?.close();
      if (tempDirectory != null && tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  // ── PAYMENT METHODS ─────────────────────────────────────────────────────────

  /// Returns all payment methods, newest first.
  List<PaymentMethod> listPaymentMethods() {
    final Database? db = _db;
    if (db == null) return const <PaymentMethod>[];
    final ResultSet rows = db.select("SELECT id, name FROM payment_methods ORDER BY id DESC");
    return [
      for (final Row row in rows) PaymentMethod(id: row["id"] as int, name: row["name"] as String),
    ];
  }

  bool addPaymentMethod(String name) {
    if (!_validName(name)) return _fail(errInvalidInput, "Payment method name required");
    return _write(paymentMethodsNotifier, (Database db) {
      db.execute("INSERT INTO payment_methods (name) VALUES (?)", [name]);
    });
  }

  bool updatePaymentMethod(int id, String name) {
    if (!_validName(name)) return _fail(errInvalidInput, "Payment method name required");
    return _write(paymentMethodsNotifier, (Database db) {
      db.execute("UPDATE payment_methods SET name = ? WHERE id = ?", [name, id]);
    });
  }

  bool deletePaymentMethod(int id) {
    return _write(paymentMethodsNotifier, (Database db) {
      db.execute("DELETE FROM payment_methods WHERE id = ?", [id]);
    });
  }

  // ── SETTINGS WRITERS ─────────────────────────────────────────────────────────

  bool saveBusinessInfo(
    String name,
    String cnpj,
    String address,
    String city,
    String state,
    String phone,
    String email,
    Uint8List logo,
  ) {
    return _write(settingsNotifier, (Database db) {
      db.execute(
        "INSERT OR REPLACE INTO business_info (id, name, cnpj, address, city, state, phone, email, logo) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?)",
        [name, cnpj, address, city, state, phone, email, logo],
      );
      businessInfo.id = 1;
      businessInfo.name = name;
      businessInfo.cnpj = cnpj;
      businessInfo.address = address;
      businessInfo.city = city;
      businessInfo.state = state;
      businessInfo.phone = phone;
      businessInfo.email = email;
      businessInfo.logo = logo;
    });
  }

  bool saveQuoteDefaults(String paymentMethod, String validity, String warranty, String terms) {
    return _write(settingsNotifier, (Database db) {
      db.execute(
        "INSERT OR REPLACE INTO quote_defaults (id, payment_method, validity, warranty, terms) VALUES (1, ?, ?, ?, ?)",
        [paymentMethod, validity, warranty, terms],
      );
      quoteDefaults.id = 1;
      quoteDefaults.paymentMethod = paymentMethod;
      quoteDefaults.validity = validity;
      quoteDefaults.warranty = warranty;
      quoteDefaults.terms = terms;
    });
  }

  bool savePdfSettings(String accentColour) {
    return _write(settingsNotifier, (Database db) {
      db.execute("INSERT OR REPLACE INTO pdf_settings (id, accent_colour) VALUES (1, ?)", [
        accentColour,
      ]);
      pdfSettings.id = 1;
      pdfSettings.accentColour = accentColour;
    });
  }

  // ── INTERNAL ──────────────────────────────────────────────────────────────

  String _catalogTable(CatalogItemType type) => switch (type) {
    .service => "services",
    .equipment => "equipments",
  };

  StoreNotifier _catalogNotifier(CatalogItemType type) => switch (type) {
    .service => servicesNotifier,
    .equipment => equipmentNotifier,
  };

  int _nowMillis() => DateTime.now().millisecondsSinceEpoch;

  String _twoDigits(int value) => value.toString().padLeft(2, "0");

  int _lastId(String table) {
    final Database? db = _db;
    if (db == null) return 0;
    final ResultSet rows = db.select("SELECT MAX(id) AS m FROM $table");
    if (rows.isEmpty) return 0;
    final Object? value = rows.first["m"];
    if (value is! int) return 0;
    return value;
  }

  void _touchQuote(Database db, int quoteId) =>
      db.execute("UPDATE quotes SET updated_at = ? WHERE id = ?", [_nowMillis(), quoteId]);

  int _lineQuantity(Database db, int quoteId, CatalogItemType type, int refId) {
    final ResultSet rows = db.select(
      "SELECT quantity FROM quote_lines WHERE quote_id = ? AND line_type = ? AND ref_id = ?",
      [quoteId, type.index, refId],
    );
    if (rows.isEmpty) return -1;
    return rows.first["quantity"] as int;
  }

  int _sumSubtotals(int quoteId, [CatalogItemType? type]) {
    final Database? db = _db;
    if (db == null) return 0;
    final ResultSet rows;
    if (type == null) {
      rows = db.select(
        "SELECT COALESCE(SUM(subtotal_cents), 0) AS s "
        "FROM quote_lines WHERE quote_id = ?",
        [quoteId],
      );
    } else {
      rows = db.select(
        "SELECT COALESCE(SUM(subtotal_cents), 0) AS s "
        "FROM quote_lines WHERE quote_id = ? AND line_type = ?",
        [quoteId, type.index],
      );
    }
    if (rows.isEmpty) return 0;
    return rows.first["s"] as int;
  }

  List<Client> _queryClients(String sql, [List<Object?> params = const []]) {
    final Database? db = _db;
    if (db == null) return const <Client>[];
    final ResultSet rows = db.select(sql, params);
    return [
      for (final Row row in rows)
        Client(
          id: row["id"] as int,
          name: row["name"] as String,
          phone: row["phone"] as String,
          email: row["email"] as String,
          address: row["address"] as String,
          city: row["city"] as String,
        ),
    ];
  }

  List<CatalogItem> _queryCatalog(String sql, [List<Object?> params = const []]) {
    final Database? db = _db;
    if (db == null) return const <CatalogItem>[];
    final ResultSet rows = db.select(sql, params);
    return [
      for (final Row row in rows)
        CatalogItem(
          id: row["id"] as int,
          name: row["name"] as String,
          description: row["description"] as String,
          priceCents: row["price_cents"] as int,
          unitId: row["unit_id"] as int? ?? 0, // services have no unit
        ),
    ];
  }

  List<Unit> _queryUnits(String sql, [List<Object?> params = const []]) {
    final Database? db = _db;
    if (db == null) return const <Unit>[];
    final ResultSet rows = db.select(sql, params);
    return [
      for (final Row row in rows)
        Unit(
          id: row["id"] as int,
          abbreviation: row["abbreviation"] as String,
          description: row["description"] as String,
        ),
    ];
  }

  List<QuoteSummary> _queryQuotes({String? status, int? limit}) {
    final Database? db = _db;
    if (db == null) return const <QuoteSummary>[];
    var sql =
        "SELECT q.id, q.client_name, q.status, "
        "COALESCE(SUM(l.subtotal_cents), 0) AS total_cents, q.updated_at, "
        "COALESCE(SUM(CASE WHEN l.line_type = ${CatalogItemType.service.index} THEN 1 ELSE 0 END), 0) AS service_count, "
        "COALESCE(SUM(CASE WHEN l.line_type = ${CatalogItemType.equipment.index} THEN 1 ELSE 0 END), 0) AS equipment_count "
        "FROM quotes q LEFT JOIN quote_lines l ON l.quote_id = q.id ";
    final List<Object?> params = [];
    if (status != null) {
      sql += "WHERE q.status = ? ";
      params.add(status);
    }
    sql += "GROUP BY q.id ORDER BY updated_at DESC";
    if (limit != null) {
      sql += " LIMIT ?";
      params.add(limit);
    }
    final ResultSet rows = db.select(sql, params);
    return [
      for (final Row row in rows)
        QuoteSummary(
          id: row["id"] as int,
          clientName: row["client_name"] as String,
          status: row["status"] as String,
          totalCents: row["total_cents"] as int,
          updatedAt: row["updated_at"] as int,
          serviceCount: row["service_count"] as int,
          equipmentCount: row["equipment_count"] as int,
        ),
    ];
  }

  bool _write(StoreNotifier notifier, void Function(Database db) action) {
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      action(db);
      notifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  /// [_write] for the content of quote [quoteId]: refused unless it is a draft,
  /// and touches the quote.
  bool _writeDraft(int quoteId, void Function(Database db) action) {
    final ResultSet? draft = _db?.select("SELECT 1 FROM quotes WHERE id = ? AND status = 'draft'", [
      quoteId,
    ]);
    if (draft != null && draft.isEmpty) return _fail(errInvalidInput, "Quote is not a draft");
    return _write(quotesNotifier, (Database db) {
      action(db);
      _touchQuote(db, quoteId);
    });
  }

  /// Lower-cases [value] and strips Portuguese accents, for searching.
  String _fold(String value) {
    const String accented = "áàâãäéèêëíìîïóòôõöúùûüç";
    const String plain = "aaaaaeeeeiiiiooooouuuuc";
    return value.toLowerCase().splitMapJoin(
      RegExp("[$accented]"),
      onMatch: (Match m) => plain[accented.indexOf(m[0]!)],
    );
  }

  bool _addCatalog(
    CatalogItemType type,
    String name,
    String description,
    int priceCents,
    int unitId,
  ) {
    if (!_validName(name)) return _fail(errInvalidInput, "Catalog name required");
    if (priceCents < 0) return _fail(errInvalidInput, "Invalid price");
    return _write(_catalogNotifier(type), (Database db) {
      if (type == .service) {
        db.execute("INSERT INTO services (name, description, price_cents) VALUES (?, ?, ?)", [
          name,
          description,
          priceCents,
        ]);
        return;
      }
      db.execute(
        "INSERT INTO equipments (name, description, price_cents, unit_id) VALUES (?, ?, ?, ?)",
        [name, description, priceCents, unitId],
      );
    });
  }

  bool _updateCatalog(
    CatalogItemType type,
    int id,
    String name,
    String description,
    int priceCents,
    int unitId,
  ) {
    if (!_validName(name)) return _fail(errInvalidInput, "Catalog name required");
    if (priceCents < 0) return _fail(errInvalidInput, "Invalid price");
    return _write(_catalogNotifier(type), (Database db) {
      if (type == .service) {
        db.execute("UPDATE services SET name = ?, description = ?, price_cents = ? WHERE id = ?", [
          name,
          description,
          priceCents,
          id,
        ]);
        return;
      }
      db.execute(
        "UPDATE equipments SET name = ?, description = ?, price_cents = ?, unit_id = ? WHERE id = ?",
        [name, description, priceCents, unitId, id],
      );
    });
  }

  bool _deleteCatalog(CatalogItemType type, int id) {
    return _write(_catalogNotifier(type), (Database db) {
      db.execute("DELETE FROM ${_catalogTable(type)} WHERE id = ?", [id]);
    });
  }

  bool _validateBackup(Database backupDb) {
    try {
      final ResultSet checkRows = backupDb.select("PRAGMA quick_check");
      if (checkRows.isEmpty || checkRows.first["quick_check"] != "ok") {
        return _fail(errDbBackup, "Backup failed SQLite quick_check");
      }

      final ResultSet versionRows = backupDb.select("PRAGMA user_version");
      if (versionRows.isEmpty || (versionRows.first["user_version"] as int) < 2) {
        return _fail(errBackupTooOld, "Backup comes from an older app version");
      }

      const List<String> requiredTables = [
        "clients",
        "units",
        "equipments",
        "services",
        "quotes",
        "quote_lines",
        "business_info",
        "payment_methods",
        "quote_defaults",
        "pdf_settings",
      ];
      for (final String table in requiredTables) {
        final ResultSet tableRows = backupDb.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          [table],
        );
        if (tableRows.isEmpty) return _fail(errDbBackup, "Backup is missing $table");
      }
      return true;
    } catch (error) {
      return _fail(errDbBackup, error.toString());
    }
  }

  bool _migrate(Database db) {
    try {
      final ResultSet versionRows = db.select("PRAGMA user_version");
      final int version = versionRows.first["user_version"] as int;
      if (version < 2) {
        // Older databases are wiped and recreated from scratch.
        for (final Row table in db.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
        )) {
          db.execute('DROP TABLE "${table["name"]}"');
        }
        db.execute("""
CREATE TABLE clients (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  name     TEXT NOT NULL,
  phone    TEXT NOT NULL DEFAULT '',
  email    TEXT NOT NULL DEFAULT '',
  address  TEXT NOT NULL DEFAULT '',
  city     TEXT NOT NULL DEFAULT ''
);
CREATE TABLE units (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  abbreviation  TEXT NOT NULL,
  description   TEXT NOT NULL DEFAULT ''
);
CREATE TABLE equipments (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
  description  TEXT NOT NULL DEFAULT '',
  price_cents  INTEGER NOT NULL DEFAULT 0,
  unit_id      INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE services (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
  description  TEXT NOT NULL DEFAULT '',
  price_cents  INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE quotes (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  client_id    INTEGER,
  client_name     TEXT NOT NULL DEFAULT '',
  client_phone    TEXT NOT NULL DEFAULT '',
  client_email    TEXT NOT NULL DEFAULT '',
  client_address  TEXT NOT NULL DEFAULT '',
  client_city     TEXT NOT NULL DEFAULT '',
  created_at   INTEGER NOT NULL,
  updated_at   INTEGER NOT NULL DEFAULT 0,
  total_cents  INTEGER NOT NULL DEFAULT 0,
  status       TEXT NOT NULL DEFAULT 'draft',
  payment     TEXT NOT NULL DEFAULT '',
  warranty    TEXT NOT NULL DEFAULT '',
  validity    TEXT NOT NULL DEFAULT '',
  terms       TEXT NOT NULL DEFAULT '',
  notes       TEXT NOT NULL DEFAULT '',
  renderer_version      INTEGER NOT NULL DEFAULT 1,
  show_unit_price       INTEGER NOT NULL DEFAULT 1,
  equipment_price_mode  INTEGER NOT NULL DEFAULT 0,
  closed_total_cents    INTEGER NOT NULL DEFAULT 0,
  markup_percent        INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE quote_lines (
  quote_id         INTEGER NOT NULL,
  line_type        INTEGER NOT NULL,
  ref_id           INTEGER NOT NULL,
  name             TEXT NOT NULL,
  description      TEXT NOT NULL DEFAULT '',
  unit             TEXT NOT NULL DEFAULT '',
  quantity         INTEGER NOT NULL,
  unit_price_cents INTEGER NOT NULL,
  subtotal_cents   INTEGER NOT NULL,
  is_new           INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_quote_lines_quote ON quote_lines(quote_id);
CREATE UNIQUE INDEX idx_quote_lines_unique ON quote_lines(quote_id, line_type, ref_id);
CREATE TABLE business_info (
  id       INTEGER PRIMARY KEY,
  name     TEXT NOT NULL DEFAULT '',
  cnpj     TEXT NOT NULL DEFAULT '',
  address  TEXT NOT NULL DEFAULT '',
  city     TEXT NOT NULL DEFAULT '',
  state    TEXT NOT NULL DEFAULT '',
  phone    TEXT NOT NULL DEFAULT '',
  email    TEXT NOT NULL DEFAULT '',
  logo     BLOB
);
CREATE TABLE payment_methods (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
);
CREATE TABLE quote_defaults (
  id              INTEGER PRIMARY KEY,
  payment_method  TEXT NOT NULL DEFAULT '',
  validity        TEXT NOT NULL DEFAULT '',
  warranty        TEXT NOT NULL DEFAULT '',
  terms           TEXT NOT NULL DEFAULT '',
  show_unit_price INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE pdf_settings (
  id             INTEGER PRIMARY KEY,
  accent_colour  TEXT NOT NULL DEFAULT ''
);
INSERT INTO business_info (id) VALUES (1);
INSERT INTO quote_defaults (id) VALUES (1);
INSERT INTO pdf_settings (id) VALUES (1);
INSERT INTO units (abbreviation, description) VALUES
  ('un', 'Unidade'), ('m', 'Metro'), ('cx', 'Caixa'), ('kit', 'Kit');
PRAGMA user_version = 2;
""");
      }
      return true;
    } catch (error) {
      return _fail(errDbMigration, error.toString());
    }
  }

  bool _loadSettings(Database db) {
    try {
      final ResultSet businessRows = db.select(
        "SELECT id, name, cnpj, address, city, state, phone, email, logo "
        "FROM business_info WHERE id = 1",
      );
      if (businessRows.isNotEmpty) {
        final Row row = businessRows.first;
        businessInfo.id = row["id"] as int;
        businessInfo.name = row["name"] as String;
        businessInfo.cnpj = row["cnpj"] as String;
        businessInfo.address = row["address"] as String;
        businessInfo.city = row["city"] as String;
        businessInfo.state = row["state"] as String;
        businessInfo.phone = row["phone"] as String;
        businessInfo.email = row["email"] as String;
        final Object? logo = row["logo"];
        businessInfo.logo = logo is List<int> ? Uint8List.fromList(logo) : Uint8List(0);
      }

      final ResultSet defaultsRows = db.select("SELECT * FROM quote_defaults WHERE id = 1");
      if (defaultsRows.isNotEmpty) {
        final Row row = defaultsRows.first;
        quoteDefaults.id = row["id"] as int;
        quoteDefaults.paymentMethod = row["payment_method"] as String;
        quoteDefaults.validity = row["validity"] as String;
        quoteDefaults.warranty = row["warranty"] as String;
        quoteDefaults.terms = row["terms"] as String;
        quoteDefaults.showUnitPrice = row["show_unit_price"] == 1;
      }

      final ResultSet pdfRows = db.select(
        "SELECT id, accent_colour FROM pdf_settings WHERE id = 1",
      );
      if (pdfRows.isNotEmpty) {
        final Row row = pdfRows.first;
        pdfSettings.id = row["id"] as int;
        pdfSettings.accentColour = row["accent_colour"] as String;
      }

      settingsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errDbLoad, error.toString());
    }
  }

  bool _validName(String value) => value.trim().isNotEmpty;

  void _markAllChanged() {
    equipmentNotifier.markChanged();
    servicesNotifier.markChanged();
    clientsNotifier.markChanged();
    quotesNotifier.markChanged();
    unitsNotifier.markChanged();
    paymentMethodsNotifier.markChanged();
    settingsNotifier.markChanged();
  }

  bool _fail(int code, String message) {
    errors.add(code, message);
    errorsNotifier.markChanged();
    return false;
  }
}
