import "dart:io";
import "dart:math" as math;

import "package:delforte/store/business_info_data.dart";
import "package:delforte/store/client_data.dart";
import "package:delforte/store/item_data.dart";
import "package:delforte/store/payment_method_data.dart";
import "package:delforte/store/pdf_settings_data.dart";
import "package:delforte/store/quote_calc_buffer.dart";
import "package:delforte/store/quote_data.dart";
import "package:delforte/store/quote_defaults_data.dart";
import "package:delforte/store/store_errors.dart";
import "package:delforte/store/unit_data.dart";
import "package:flutter/foundation.dart";
import "package:path_provider/path_provider.dart";
import "package:sqlite3/sqlite3.dart";

/// Initial row capacity for short-lived buffers.
const int initialCap = 256;

/// Maximum number of rows mirrored in memory per table.
const int maxLimit = 10000;

/// Quote line type for catalog item.
enum CatalogItemType { equipment, service }

/// Public notifier wrapper used by store tables.
class StoreNotifier extends ChangeNotifier {
  /// Notifies listeners that the associated store data changed.
  ///
  /// Use inside store mutations after the mirrored data is already updated.
  ///
  /// ```dart
  /// clientsNotifier.markChanged();
  /// ```
  void markChanged() {
    notifyListeners();
  }
}

/// SQLite-backed quote module store.
class QuoteStore {
  /// Creates a store.
  ///
  /// If [databasePath] is omitted, [open] uses the app documents directory.
  QuoteStore({String? databasePath})
    : _databasePath = databasePath,
      equipments = ItemData(maxLimit),
      services = ItemData(maxLimit),
      clients = ClientData(maxLimit),
      quotes = QuoteData(maxLimit),
      units = UnitData(maxLimit),
      draft = QuoteCalcBuffer(initialCap),
      errors = ErrorLogBuffer(256),
      paymentMethods = PaymentMethodData(maxLimit),
      businessInfo = BusinessInfoData(),
      quoteDefaults = QuoteDefaultsData(),
      pdfSettings = PdfSettingsData();

  /// Equipment rows mirrored from SQLite.
  final ItemData equipments;

  /// Service rows mirrored from SQLite.
  final ItemData services;

  /// Client rows mirrored from SQLite.
  final ClientData clients;

  /// Saved quote rows mirrored from SQLite.
  final QuoteData quotes;

  /// Unit rows mirrored from SQLite.
  final UnitData units;

  /// Mutable in-memory draft quote.
  final QuoteCalcBuffer draft;

  /// Error side-channel for failed operations.
  final ErrorLogBuffer errors;

  /// Payment method rows mirrored from SQLite.
  final PaymentMethodData paymentMethods;

  /// Business info singleton mirrored from SQLite.
  final BusinessInfoData businessInfo;

  /// Quote defaults singleton mirrored from SQLite.
  final QuoteDefaultsData quoteDefaults;

  /// PDF appearance settings singleton mirrored from SQLite.
  final PdfSettingsData pdfSettings;

  /// Notifies when [equipments] changes.
  final StoreNotifier equipmentNotifier = StoreNotifier();

  /// Notifies when [services] changes.
  final StoreNotifier servicesNotifier = StoreNotifier();

  /// Notifies when [clients] changes.
  final StoreNotifier clientsNotifier = StoreNotifier();

  /// Notifies when [quotes] changes.
  final StoreNotifier quotesNotifier = StoreNotifier();

  /// Notifies when [draft] changes.
  final StoreNotifier quoteDraftNotifier = StoreNotifier();

  /// Notifies when [units] changes.
  final StoreNotifier unitsNotifier = StoreNotifier();

  /// Notifies when [errors] changes.
  final StoreNotifier errorsNotifier = StoreNotifier();

  /// Notifies when [paymentMethods] changes.
  final StoreNotifier paymentMethodsNotifier = StoreNotifier();

  /// Notifies when any singleton settings change.
  final StoreNotifier settingsNotifier = StoreNotifier();

  final String? _databasePath;
  Database? _db;

  /// Opens SQLite, migrates schema, and loads rows into memory.
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
      final Database db = sqlite3.open(path);
      _db = db;
      db.execute("PRAGMA journal_mode = WAL;");
      db.execute("PRAGMA synchronous = NORMAL;");
      db.execute("PRAGMA foreign_keys = ON;");
      if (!_migrate(db)) return false;
      if (!_load(db)) return false;
      return true;
    } catch (error) {
      return _fail(errDbOpen, error.toString());
    }
  }

  /// Closes SQLite and disposes all notifiers.
  void dispose() {
    _db?.close();
    equipmentNotifier.dispose();
    servicesNotifier.dispose();
    clientsNotifier.dispose();
    unitsNotifier.dispose();
    quotesNotifier.dispose();
    quoteDraftNotifier.dispose();
    errorsNotifier.dispose();
    paymentMethodsNotifier.dispose();
    settingsNotifier.dispose();
  }

  /// Inserts a client and mirrors it into [clients].
  bool addClient(String name, String phone, String email, String address, String city) {
    if (!_validName(name)) return _fail(errInvalidInput, "Client name required");
    if (clients.count >= maxLimit) return _fail(errCapReached, "Client cap reached");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute("INSERT INTO clients (name, phone, email, address, city) VALUES (?, ?, ?, ?, ?)", [
        name,
        phone,
        email,
        address,
        city,
      ]);
      final int id = db.lastInsertRowId;
      if (!clients.append(id, name, phone, email, address, city)) {
        return _fail(errCapReached, "Client RAM cap reached");
      }
      clientsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  /// Updates a client by [id] and mirrors it into [clients].
  bool updateClient(int id, String name, String phone, String email, String address, String city) {
    if (!_validName(name)) return _fail(errInvalidInput, "Client name required");
    if (clients.indexOfId(id) < 0) return _fail(errMissingId, "Client missing");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute(
        "UPDATE clients SET name = ?, phone = ?, email = ?, address = ?, city = ? WHERE id = ?",
        [name, phone, email, address, city, id],
      );
      clients.update(id, name, phone, email, address, city);
      clientsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  /// Deletes a client by [id].
  bool deleteClient(int id) {
    if (clients.indexOfId(id) < 0) return _fail(errMissingId, "Client missing");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute("DELETE FROM clients WHERE id = ?", [id]);
      clients.deleteById(id);
      clientsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  /// Inserts equipment and mirrors it into [equipments].
  bool addEquipment(String name, String description, int priceCents, int unitId) {
    return _addCatalog(false, name, description, priceCents, unitId);
  }

  /// Inserts a service and mirrors it into [services].
  bool addService(String name, String description, int priceCents, int unitId) {
    return _addCatalog(true, name, description, priceCents, unitId);
  }

  /// Updates equipment by [id].
  bool updateEquipment(int id, String name, String description, int priceCents, int unitId) {
    return _updateCatalog(.equipment, id, name, description, priceCents, unitId);
  }

  /// Updates a service by [id].
  bool updateService(int id, String name, String description, int priceCents, int unitId) {
    return _updateCatalog(.service, id, name, description, priceCents, unitId);
  }

  /// Deletes equipment by [id] and removes matching draft lines.
  bool deleteEquipment(int id) {
    return _deleteCatalog(.equipment, id);
  }

  /// Deletes a service by [id] and removes matching draft lines.
  bool deleteService(int id) {
    return _deleteCatalog(.service, id);
  }

  /// Adds or increments a draft line for [type] and [refId].
  bool addDraftLine(CatalogItemType type, int refId, int quantity) {
    final int price = priceFor(type, refId);
    if (price < 0) return _fail(errMissingId, "Catalog ref missing");
    final int existing = draft.lineIndex(type, refId);
    if (existing >= 0) {
      final int next = math.min(9999, draft.quantities[existing] + quantity);
      if (!draft.setQuantity(existing, next)) return _fail(errInvalidInput, "Invalid quantity");
      quoteDraftNotifier.markChanged();
      return true;
    }
    if (!draft.addLine(type, refId, quantity, price)) {
      return _fail(errCapReached, "Quote line cap reached");
    }
    quoteDraftNotifier.markChanged();
    return true;
  }

  /// Changes draft quantity at [index] by [delta], clamped to `1..9999`.
  bool changeDraftQuantity(int index, int delta) {
    if (index < 0 || index >= draft.count) return _fail(errMissingId, "Quote line missing");
    final int next = math.max(0, math.min(9999, draft.quantities[index] + delta));
    if (next == 0) return draft.removeAt(index);
    if (!draft.setQuantity(index, next)) return _fail(errInvalidInput, "Invalid quantity");
    quoteDraftNotifier.markChanged();
    return true;
  }

  /// Sets the unit price at [index] to [cents] and refreshes the subtotal.
  bool setDraftUnitPrice(int index, int cents) {
    if (index < 0 || index >= draft.count) return _fail(errMissingId, "Quote line missing");
    if (cents < 0) return _fail(errInvalidInput, "Invalid price");
    draft.unitPriceCents[index] = cents;
    draft.setQuantity(index, draft.quantities[index]);
    quoteDraftNotifier.markChanged();
    return true;
  }

  /// Removes a draft line by [index].
  bool removeDraftLine(int index) {
    if (!draft.removeAt(index)) return _fail(errMissingId, "Quote line missing");
    quoteDraftNotifier.markChanged();
    return true;
  }

  /// Clears the active draft.
  bool clearDraft() {
    draft.clear();
    quoteDraftNotifier.markChanged();
    return true;
  }

  /// Saves the draft for [clientId] in one SQLite transaction.
  ///
  /// Does not clear [draft] after saving.
  bool saveQuote(int clientId) {
    if (clients.indexOfId(clientId) < 0) return _fail(errMissingId, "Client missing");
    if (draft.count <= 0) return _fail(errQuoteEmpty, "Quote empty");
    if (quotes.count >= maxLimit) return _fail(errCapReached, "Quote cap reached");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    final int createdAt = DateTime.now().toUtc().millisecondsSinceEpoch;
    final int total = draft.computeTotals();
    try {
      db.execute("BEGIN IMMEDIATE");
      db.execute("INSERT INTO quotes (client_id, created_at, total_cents) VALUES (?, ?, ?)", [
        clientId,
        createdAt,
        total,
      ]);
      final int quoteId = db.lastInsertRowId;
      final PreparedStatement stmt = db.prepare(
        "INSERT INTO quote_lines (quote_id, line_type, ref_id, quantity, unit_price_cents, subtotal_cents) VALUES (?, ?, ?, ?, ?, ?)",
      );
      try {
        for (var i = 0; i < draft.count && i < maxLimit; i++) {
          stmt.execute([
            quoteId,
            draft.types[i],
            draft.refIds[i],
            draft.quantities[i],
            draft.unitPriceCents[i],
            draft.subtotalCents[i],
          ]);
        }
      } finally {
        stmt.close();
      }
      db.execute("COMMIT");
      if (!quotes.append(quoteId, clientId, createdAt, total)) {
        return _fail(errCapReached, "Quote RAM cap reached");
      }
      quotesNotifier.markChanged();
      return true;
    } catch (error) {
      try {
        db.execute("ROLLBACK");
      } catch (_) {}
      return _fail(errSqlWrite, error.toString());
    }
  }

  /// Returns the catalog price for [type] and [refId], or `-1` if missing.
  int priceFor(CatalogItemType type, int refId) {
    final ItemData data = switch (type) {
      .service => services,
      .equipment => equipments,
    };
    final int index = data.indexOfId(refId);
    if (index < 0) return -1;
    return data.priceCents[index];
  }

  /// Returns the catalog name for [type] and [refId], or `""` if missing.
  String nameFor(CatalogItemType type, int refId) {
    final ItemData data = type == .service ? services : equipments;
    final int index = data.indexOfId(refId);
    if (index < 0) return "";
    return data.names[index];
  }

  /// Returns the catalog description for [type] and [refId], or `""` if missing.
  String descriptionFor(CatalogItemType type, int refId) {
    final ItemData data = type == .service ? services : equipments;
    final int index = data.indexOfId(refId);
    if (index < 0) return "";
    return data.descriptions[index];
  }

  /// Inserts a unit and mirrors it into [units].
  bool addUnit(String abbreviation, String description) {
    if (!_validName(abbreviation)) return _fail(errInvalidInput, "Unit abbreviation required");
    if (units.count >= maxLimit) return _fail(errCapReached, "Unit cap reached");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute("INSERT INTO units (abbreviation, description) VALUES (?, ?)", [
        abbreviation,
        description,
      ]);
      final int id = db.lastInsertRowId;
      if (!units.append(id, abbreviation, description)) {
        return _fail(errCapReached, "Unit RAM cap reached");
      }
      unitsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  /// Updates a unit by [id] and mirrors it into [units].
  bool updateUnit(int id, String abbreviation, String description) {
    if (!_validName(abbreviation)) return _fail(errInvalidInput, "Unit abbreviation required");
    if (units.indexOfId(id) < 0) return _fail(errMissingId, "Unit missing");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute("UPDATE units SET abbreviation = ?, description = ? WHERE id = ?", [
        abbreviation,
        description,
        id,
      ]);
      units.update(id, abbreviation, description);
      unitsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  /// Deletes a unit by [id].
  bool deleteUnit(int id) {
    if (units.indexOfId(id) < 0) return _fail(errMissingId, "Unit missing");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute("DELETE FROM units WHERE id = ?", [id]);
      units.deleteById(id);
      unitsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  /// Returns the unit abbreviation for [unitId], or `""` if missing.
  String unitAbbreviationFor(int unitId) {
    final int index = units.indexOfId(unitId);
    if (index < 0) return "";
    return units.abbreviationAt(index);
  }

  /// Returns the most recent error message, or `""` when there are no errors.
  String latestErrorMessage() {
    if (errors.count <= 0) return "";
    return errors.messageAt(errors.count - 1);
  }

  bool _addCatalog(bool isService, String name, String description, int priceCents, int unitId) {
    if (!_validName(name)) return _fail(errInvalidInput, "Catalog name required");
    if (priceCents < 0) return _fail(errInvalidInput, "Invalid price");
    final ItemData data = isService ? services : equipments;
    if (data.count >= maxLimit) return _fail(errCapReached, "Catalog cap reached");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    final String table = isService ? "services" : "equipments";
    try {
      db.execute(
        "INSERT INTO $table (name, description, price_cents, unit_id) VALUES (?, ?, ?, ?)",
        [name, description, priceCents, unitId],
      );
      final int id = db.lastInsertRowId;
      if (!data.append(id, name, description, priceCents, unitId)) {
        return _fail(errCapReached, "Catalog RAM cap reached");
      }
      (isService ? servicesNotifier : equipmentNotifier).markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
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
    final ItemData data = switch (type) {
      .service => services,
      .equipment => equipments,
    };
    if (data.indexOfId(id) < 0) return _fail(errMissingId, "Catalog missing");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    final String table = switch (type) {
      .service => "services",
      .equipment => "equipments",
    };
    try {
      db.execute(
        "UPDATE $table SET name = ?, description = ?, price_cents = ?, unit_id = ? WHERE id = ?",
        [name, description, priceCents, unitId, id],
      );
      data.update(id, name, description, priceCents, unitId);
      final int draftIndex = draft.lineIndex(type, id);
      if (draftIndex >= 0) {
        draft.unitPriceCents[draftIndex] = priceCents;
        draft.setQuantity(draftIndex, draft.quantities[draftIndex]);
        quoteDraftNotifier.markChanged();
      }
      final StoreNotifier notifier = switch (type) {
        .service => servicesNotifier,
        .equipment => equipmentNotifier,
      };
      notifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  bool _deleteCatalog(CatalogItemType type, int id) {
    final ItemData data = switch (type) {
      .service => services,
      .equipment => equipments,
    };
    if (data.indexOfId(id) < 0) return _fail(errMissingId, "Catalog missing");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    final String table = switch (type) {
      .service => "services",
      .equipment => "equipments",
    };
    try {
      db.execute("DELETE FROM $table WHERE id = ?", [id]);
      data.deleteById(id);
      draft.removeCatalogRef(type, id);
      final StoreNotifier notifier = switch (type) {
        .service => servicesNotifier,
        .equipment => equipmentNotifier,
      };
      notifier.markChanged();
      quoteDraftNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  bool _migrate(Database db) {
    try {
      final ResultSet versionRows = db.select("PRAGMA user_version");
      var version = versionRows.first["user_version"] as int;
      if (version < 1) {
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
  price_cents  INTEGER NOT NULL DEFAULT 0,
  unit_id      INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE quotes (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  client_id    INTEGER NOT NULL,
  created_at   INTEGER NOT NULL,
  total_cents  INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE quote_lines (
  quote_id         INTEGER NOT NULL,
  line_type        INTEGER NOT NULL,
  ref_id           INTEGER NOT NULL,
  quantity         INTEGER NOT NULL,
  unit_price_cents INTEGER NOT NULL,
  subtotal_cents   INTEGER NOT NULL
);
CREATE INDEX idx_quote_lines_quote ON quote_lines(quote_id);
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
  terms           TEXT NOT NULL DEFAULT ''
);
CREATE TABLE pdf_settings (
  id             INTEGER PRIMARY KEY,
  accent_colour  TEXT NOT NULL DEFAULT ''
);
INSERT INTO business_info (id) VALUES (1);
INSERT INTO quote_defaults (id) VALUES (1);
INSERT INTO pdf_settings (id) VALUES (1);
PRAGMA user_version = 1;
""");
        version = 1;
      }
      return true;
    } catch (error) {
      return _fail(errDbMigration, error.toString());
    }
  }

  bool _load(Database db) {
    try {
      if (!_loadClients(db)) return false;
      if (!_loadUnits(db)) return false;
      if (!_loadCatalog(db, false)) return false;
      if (!_loadCatalog(db, true)) return false;
      if (!_loadQuotes(db)) return false;
      if (!_loadPaymentMethods(db)) return false;
      if (!_loadBusinessInfo(db)) return false;
      if (!_loadQuoteDefaults(db)) return false;
      if (!_loadPdfSettings(db)) return false;
      clientsNotifier.markChanged();
      unitsNotifier.markChanged();
      equipmentNotifier.markChanged();
      servicesNotifier.markChanged();
      quotesNotifier.markChanged();
      paymentMethodsNotifier.markChanged();
      settingsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errDbLoad, error.toString());
    }
  }

  bool _loadClients(Database db) {
    final ResultSet rows = db.select(
      "SELECT id, name, phone, email, address, city FROM clients ORDER BY id DESC",
    );
    if (rows.length > maxLimit) return _fail(errCapReached, "Client DB cap exceeded");
    clients.count = 0;
    for (final Row row in rows) {
      final bool ok = clients.append(
        row["id"] as int,
        row["name"] as String,
        row["phone"] as String,
        row["email"] as String,
        row["address"] as String,
        row["city"] as String,
      );
      if (!ok) return _fail(errCapReached, "Client load cap reached");
    }
    return true;
  }

  bool _loadUnits(Database db) {
    final ResultSet rows = db.select(
      "SELECT id, abbreviation, description FROM units ORDER BY id DESC",
    );
    if (rows.length > maxLimit) return _fail(errCapReached, "Unit DB cap exceeded");
    units.count = 0;
    for (final Row row in rows) {
      final bool ok = units.append(
        row["id"] as int,
        row["abbreviation"] as String,
        row["description"] as String,
      );
      if (!ok) return _fail(errCapReached, "Unit load cap reached");
    }
    return true;
  }

  bool _loadCatalog(Database db, bool isService) {
    final String table = isService ? "services" : "equipments";
    final ItemData data = isService ? services : equipments;
    final ResultSet rows = db.select(
      "SELECT id, name, description, price_cents, unit_id FROM $table ORDER BY id DESC",
    );
    if (rows.length > maxLimit) return _fail(errCapReached, "Catalog DB cap exceeded");
    data.count = 0;
    for (final Row row in rows) {
      final bool ok = data.append(
        row["id"] as int,
        row["name"] as String,
        row["description"] as String,
        row["price_cents"] as int,
        row["unit_id"] as int,
      );
      if (!ok) return _fail(errCapReached, "Catalog load cap reached");
    }
    return true;
  }

  bool _loadQuotes(Database db) {
    final ResultSet rows = db.select(
      "SELECT id, client_id, created_at, total_cents FROM quotes ORDER BY id DESC",
    );
    if (rows.length > maxLimit) return _fail(errCapReached, "Quote DB cap exceeded");
    quotes.count = 0;
    for (final Row row in rows) {
      final bool ok = quotes.append(
        row["id"] as int,
        row["client_id"] as int,
        DateTime.fromMillisecondsSinceEpoch(
          row["created_at"] as int,
          isUtc: true,
        ).toLocal().millisecondsSinceEpoch,
        row["total_cents"] as int,
      );
      if (!ok) return _fail(errCapReached, "Quote load cap reached");
    }
    return true;
  }

  bool _validName(String value) {
    return value.trim().isNotEmpty;
  }

  bool _fail(int code, String message) {
    errors.add(code, message);
    errorsNotifier.markChanged();
    return false;
  }

  // ── SETTINGS LOADERS ─────────────────────────────────────────────────────

  bool _loadPaymentMethods(Database db) {
    final ResultSet rows = db.select("SELECT id, name FROM payment_methods ORDER BY id DESC");
    if (rows.length > maxLimit) return _fail(errCapReached, "Payment method DB cap exceeded");
    paymentMethods.count = 0;
    for (final Row row in rows) {
      final bool ok = paymentMethods.append(row["id"] as int, row["name"] as String);
      if (!ok) return _fail(errCapReached, "Payment method load cap reached");
    }
    return true;
  }

  bool _loadBusinessInfo(Database db) {
    final ResultSet rows = db.select(
      "SELECT id, name, cnpj, address, city, state, phone, email, logo FROM business_info WHERE id = 1",
    );
    if (rows.isNotEmpty) {
      final Row row = rows.first;
      businessInfo.id = row["id"] as int;
      businessInfo.name = row["name"] as String;
      businessInfo.cnpj = row["cnpj"] as String;
      businessInfo.address = row["address"] as String;
      businessInfo.city = row["city"] as String;
      businessInfo.state = row["state"] as String;
      businessInfo.phone = row["phone"] as String;
      businessInfo.email = row["email"] as String;
      final Object? logo = row["logo"];
      if (logo is List<int>) {
        businessInfo.logo = Uint8List.fromList(logo);
      }
    }
    return true;
  }

  bool _loadQuoteDefaults(Database db) {
    final ResultSet rows = db.select(
      "SELECT id, payment_method, validity, warranty, terms FROM quote_defaults WHERE id = 1",
    );
    if (rows.isNotEmpty) {
      final Row row = rows.first;
      quoteDefaults.id = row["id"] as int;
      quoteDefaults.paymentMethod = row["payment_method"] as String;
      quoteDefaults.validity = row["validity"] as String;
      quoteDefaults.warranty = row["warranty"] as String;
      quoteDefaults.terms = row["terms"] as String;
    }
    return true;
  }

  bool _loadPdfSettings(Database db) {
    final ResultSet rows = db.select("SELECT id, accent_colour FROM pdf_settings WHERE id = 1");
    if (rows.isNotEmpty) {
      final Row row = rows.first;
      pdfSettings.id = row["id"] as int;
      pdfSettings.accentColour = row["accent_colour"] as String;
    }
    return true;
  }

  // ── PAYMENT METHOD CRUD ──────────────────────────────────────────────────

  bool addPaymentMethod(String name) {
    if (!_validName(name)) return _fail(errInvalidInput, "Payment method name required");
    if (paymentMethods.count >= maxLimit) return _fail(errCapReached, "Payment method cap reached");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute("INSERT INTO payment_methods (name) VALUES (?)", [name]);
      final int id = db.lastInsertRowId;
      if (!paymentMethods.append(id, name)) {
        return _fail(errCapReached, "Payment method RAM cap reached");
      }
      paymentMethodsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  bool updatePaymentMethod(int id, String name) {
    if (!_validName(name)) return _fail(errInvalidInput, "Payment method name required");
    if (paymentMethods.indexOfId(id) < 0) return _fail(errMissingId, "Payment method missing");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute("UPDATE payment_methods SET name = ? WHERE id = ?", [name, id]);
      paymentMethods.update(id, name);
      paymentMethodsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  bool deletePaymentMethod(int id) {
    if (paymentMethods.indexOfId(id) < 0) return _fail(errMissingId, "Payment method missing");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute("DELETE FROM payment_methods WHERE id = ?", [id]);
      paymentMethods.deleteById(id);
      paymentMethodsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  // ── SETTINGS WRITERS ─────────────────────────────────────────────────────

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
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
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
      settingsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  bool saveQuoteDefaults(String paymentMethod, String validity, String warranty, String terms) {
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute(
        "INSERT OR REPLACE INTO quote_defaults (id, payment_method, validity, warranty, terms) VALUES (1, ?, ?, ?, ?)",
        [paymentMethod, validity, warranty, terms],
      );
      quoteDefaults.id = 1;
      quoteDefaults.paymentMethod = paymentMethod;
      quoteDefaults.validity = validity;
      quoteDefaults.warranty = warranty;
      quoteDefaults.terms = terms;
      settingsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  bool savePdfSettings(String accentColour) {
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute("INSERT OR REPLACE INTO pdf_settings (id, accent_colour) VALUES (1, ?)", [
        accentColour,
      ]);
      pdfSettings.id = 1;
      pdfSettings.accentColour = accentColour;
      settingsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }
}
