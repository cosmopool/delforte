import "dart:io";
import "dart:math" as math;

import "package:flutter/foundation.dart";
import "package:path_provider/path_provider.dart";
import "package:sqlite3/sqlite3.dart";

/// Initial row capacity for short-lived buffers.
const int initialCap = 256;

/// Maximum number of rows mirrored in memory per table.
const int maxLimit = 10000;

/// Quote line type for catalog items.
const int quoteLineItem = 0;

/// Quote line type for catalog services.
const int quoteLineService = 1;

/// Error code used when the store is opened on Flutter web.
const int errWebUnsupported = 1;

/// Error code used when SQLite cannot be opened or is not open.
const int errDbOpen = 2;

/// Error code used when schema migration fails.
const int errDbMigration = 3;

/// Error code used when loading SQLite rows into memory fails.
const int errDbLoad = 4;

/// Error code used when a fixed-size buffer is full.
const int errCapReached = 5;

/// Error code used when a requested row id does not exist.
const int errMissingId = 6;

/// Error code used when a SQLite write fails.
const int errSqlWrite = 7;

/// Error code used when input is invalid.
const int errInvalidInput = 8;

/// Error code used when saving an empty quote draft.
const int errQuoteEmpty = 9;

/// Fixed-size side-channel for store errors.
class ErrorLogBuffer {
  /// Creates an error log with [capacity] entries.
  ErrorLogBuffer(int capacity)
    : codes = Int32List(capacity),
      messages = List<String>.filled(capacity, "", growable: false);

  /// Error codes in insertion order.
  final Int32List codes;

  /// Error messages in insertion order.
  final List<String> messages;

  /// Number of valid entries in [codes] and [messages].
  int count = 0;

  /// Appends [code] and [message] if space is available.
  ///
  /// Use when a store operation fails and the caller needs a non-throwing
  /// side-channel.
  ///
  /// ```dart
  /// errors.add(errInvalidInput, "Client name required");
  /// ```
  void add(int code, String message) {
    if (count >= codes.length) return;
    codes[count] = code;
    messages[count] = message;
    count++;
  }

  /// Returns the error code at [index], or `0` when [index] is invalid.
  ///
  /// Use when the UI or a test needs to branch on the failure type.
  ///
  /// ```dart
  /// if (store.errors.codeAt(store.errors.count - 1) == errMissingId) {}
  /// ```
  int codeAt(int index) {
    if (index < 0 || index >= count) return 0;
    return codes[index];
  }

  /// Returns the error message at [index], or `""` when [index] is invalid.
  ///
  /// Use when showing the stored failure to the user.
  ///
  /// ```dart
  /// final String message = store.errors.messageAt(store.errors.count - 1);
  /// ```
  String messageAt(int index) {
    if (index < 0 || index >= count) return "";
    return messages[index];
  }
}

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

/// Struct-of-arrays buffer for catalog item or service rows.
class ItemData {
  /// Creates a fixed-size catalog buffer with [capacity] rows.
  ///
  /// Use when allocating the hot catalog arrays before loading SQLite rows.
  ///
  /// ```dart
  /// final ItemData items = ItemData(maxLimit);
  /// ```
  ItemData(int capacity)
    : ids = Int64List(capacity),
      priceCents = Int64List(capacity),
      names = List<String>.filled(capacity, "", growable: false),
      descriptions = List<String>.filled(capacity, "", growable: false);

  /// SQLite row ids.
  final Int64List ids;

  /// Unit prices stored as integer cents.
  final Int64List priceCents;

  /// Catalog names.
  final List<String> names;

  /// Catalog descriptions.
  final List<String> descriptions;

  /// Number of active rows.
  int count = 0;

  /// Returns the id at [index], or `0` when [index] is invalid.
  int idAt(int index) {
    if (index < 0 || index >= count) return 0;
    return ids[index];
  }

  /// Returns the price in cents at [index], or `0` when [index] is invalid.
  ///
  /// Use when displaying catalog prices without floating-point money.
  ///
  /// ```dart
  /// final int cents = store.items.priceCentsAt(index);
  /// ```
  int priceCentsAt(int index) {
    if (index < 0 || index >= count) return 0;
    return priceCents[index];
  }

  /// Returns the name at [index], or `""` when [index] is invalid.
  String nameAt(int index) {
    if (index < 0 || index >= count) return "";
    return names[index];
  }

  /// Returns the description at [index], or `""` when [index] is invalid.
  ///
  /// Use when showing catalog detail text.
  ///
  /// ```dart
  /// final String description = store.items.descriptionAt(index);
  /// ```
  String descriptionAt(int index) {
    if (index < 0 || index >= count) return "";
    return descriptions[index];
  }

  /// Returns the index for [id], or `-1` when it is not present.
  int indexOfId(int id) {
    for (var i = 0; i < count && i < maxLimit; i++) {
      if (ids[i] == id) return i;
    }
    return -1;
  }

  /// Appends a row and returns whether it fit in the buffer.
  ///
  /// Use after SQLite has accepted a new catalog row.
  ///
  /// ```dart
  /// final bool ok = store.items.append(id, "Camera", "4MP", 42000);
  /// ```
  bool append(int id, String name, String description, int cents) {
    if (count >= ids.length || count >= maxLimit) return false;
    ids[count] = id;
    names[count] = name;
    descriptions[count] = description;
    priceCents[count] = cents;
    count++;
    return true;
  }

  /// Updates the row with [id] and returns whether it existed.
  ///
  /// Use after SQLite has accepted a catalog update.
  ///
  /// ```dart
  /// final bool ok = store.items.update(id, "Camera Pro", "8MP", 50000);
  /// ```
  bool update(int id, String name, String description, int cents) {
    final int index = indexOfId(id);
    if (index < 0) return false;
    ids[index] = id;
    names[index] = name;
    descriptions[index] = description;
    priceCents[index] = cents;
    return true;
  }

  /// Deletes the row with [id] by swap-removing it.
  bool deleteById(int id) {
    final int index = indexOfId(id);
    if (index < 0) return false;
    assert(index < count);
    final int last = count - 1;
    ids[index] = ids[last];
    names[index] = names[last];
    descriptions[index] = descriptions[last];
    priceCents[index] = priceCents[last];
    ids[last] = 0;
    names[last] = "";
    descriptions[last] = "";
    priceCents[last] = 0;
    count--;
    return true;
  }
}

/// Struct-of-arrays buffer for client rows.
class ClientData {
  /// Creates a fixed-size client buffer with [capacity] rows.
  ClientData(int capacity)
    : ids = Int64List(capacity),
      names = List<String>.filled(capacity, "", growable: false),
      phones = List<String>.filled(capacity, "", growable: false),
      emails = List<String>.filled(capacity, "", growable: false),
      addresses = List<String>.filled(capacity, "", growable: false);

  /// SQLite row ids.
  final Int64List ids;

  /// Client names.
  final List<String> names;

  /// Client phone numbers.
  final List<String> phones;

  /// Client email addresses.
  final List<String> emails;

  /// Client street or installation addresses.
  final List<String> addresses;

  /// Number of active rows.
  int count = 0;

  /// Returns the id at [index], or `0` when [index] is invalid.
  int idAt(int index) {
    if (index < 0 || index >= count) return 0;
    return ids[index];
  }

  /// Returns the name at [index], or `""` when [index] is invalid.
  String nameAt(int index) {
    if (index < 0 || index >= count) return "";
    return names[index];
  }

  /// Returns the phone at [index], or `""` when [index] is invalid.
  String phoneAt(int index) {
    if (index < 0 || index >= count) return "";
    return phones[index];
  }

  /// Returns the email at [index], or `""` when [index] is invalid.
  String emailAt(int index) {
    if (index < 0 || index >= count) return "";
    return emails[index];
  }

  /// Returns the address at [index], or `""` when [index] is invalid.
  String addressAt(int index) {
    if (index < 0 || index >= count) return "";
    return addresses[index];
  }

  /// Returns the index for [id], or `-1` when it is not present.
  int indexOfId(int id) {
    for (var i = 0; i < count && i < maxLimit; i++) {
      if (ids[i] == id) return i;
    }
    return -1;
  }

  /// Appends a row and returns whether it fit in the buffer.
  bool append(int id, String name, String phone, String email, String address) {
    if (count >= ids.length || count >= maxLimit) return false;
    ids[count] = id;
    names[count] = name;
    phones[count] = phone;
    emails[count] = email;
    addresses[count] = address;
    count++;
    return true;
  }

  /// Updates the row with [id] and returns whether it existed.
  bool update(int id, String name, String phone, String email, String address) {
    final int index = indexOfId(id);
    if (index < 0) return false;
    ids[index] = id;
    names[index] = name;
    phones[index] = phone;
    emails[index] = email;
    addresses[index] = address;
    return true;
  }

  /// Deletes the row with [id] by swap-removing it.
  bool deleteById(int id) {
    final int index = indexOfId(id);
    if (index < 0) return false;
    assert(index < count);
    final int last = count - 1;
    ids[index] = ids[last];
    names[index] = names[last];
    phones[index] = phones[last];
    emails[index] = emails[last];
    addresses[index] = addresses[last];
    ids[last] = 0;
    names[last] = "";
    phones[last] = "";
    emails[last] = "";
    addresses[last] = "";
    count--;
    return true;
  }
}

/// Struct-of-arrays buffer for saved quote rows.
class QuoteData {
  /// Creates a fixed-size quote buffer with [capacity] rows.
  QuoteData(int capacity)
    : ids = Int64List(capacity),
      clientIds = Int64List(capacity),
      totalCents = Int64List(capacity),
      timestamps = Int64List(capacity);

  /// SQLite row ids.
  final Int64List ids;

  /// Client ids for each quote.
  final Int64List clientIds;

  /// Quote totals stored as integer cents.
  final Int64List totalCents;

  /// Quote creation timestamps in milliseconds since epoch.
  final Int64List timestamps;

  /// Number of active rows.
  int count = 0;

  /// Returns the quote id at [index], or `0` when [index] is invalid.
  int idAt(int index) {
    if (index < 0 || index >= count) return 0;
    return ids[index];
  }

  /// Returns the client id at [index], or `0` when [index] is invalid.
  int clientIdAt(int index) {
    if (index < 0 || index >= count) return 0;
    return clientIds[index];
  }

  /// Returns the total in cents at [index], or `0` when [index] is invalid.
  int totalCentsAt(int index) {
    if (index < 0 || index >= count) return 0;
    return totalCents[index];
  }

  /// Returns the timestamp at [index], or `0` when [index] is invalid.
  int timestampAt(int index) {
    if (index < 0 || index >= count) return 0;
    return timestamps[index];
  }

  /// Appends a saved quote and returns whether it fit in the buffer.
  bool append(int id, int clientId, int createdAt, int total) {
    if (count >= ids.length || count >= maxLimit) return false;
    ids[count] = id;
    clientIds[count] = clientId;
    timestamps[count] = createdAt;
    totalCents[count] = total;
    count++;
    return true;
  }
}

/// Fixed-size quote draft buffer.
class QuoteCalcBuffer {
  /// Creates a fixed-size draft buffer with [capacity] lines.
  QuoteCalcBuffer(int capacity)
    : types = Int32List(capacity),
      refIds = Int64List(capacity),
      quantities = Int32List(capacity),
      unitPriceCents = Int64List(capacity),
      subtotalCents = Int64List(capacity);

  /// Line types, using [quoteLineItem] or [quoteLineService].
  final Int32List types;

  /// Referenced item or service ids.
  final Int64List refIds;

  /// Line quantities.
  final Int32List quantities;

  /// Unit prices stored as integer cents.
  final Int64List unitPriceCents;

  /// Line subtotals stored as integer cents.
  final Int64List subtotalCents;

  /// Number of active draft lines.
  int count = 0;

  /// Appends a draft line and returns whether it fit in the buffer.
  bool addLine(int type, int refId, int quantity, int unitPrice) {
    if (count >= types.length || count >= maxLimit) return false;
    if (quantity <= 0 || unitPrice < 0) return false;
    types[count] = type;
    refIds[count] = refId;
    quantities[count] = quantity;
    unitPriceCents[count] = unitPrice;
    subtotalCents[count] = unitPrice * quantity;
    count++;
    return true;
  }

  /// Returns the line index for [type] and [refId], or `-1` when absent.
  int lineIndex(int type, int refId) {
    for (var i = 0; i < count && i < maxLimit; i++) {
      if (types[i] == type && refIds[i] == refId) return i;
    }
    return -1;
  }

  /// Sets [quantity] at [index] and refreshes the subtotal.
  bool setQuantity(int index, int quantity) {
    if (index < 0 || index >= count) return false;
    if (quantity <= 0) return false;
    quantities[index] = quantity;
    subtotalCents[index] = unitPriceCents[index] * quantity;
    return true;
  }

  /// Removes the line at [index] by swap-removing it.
  bool removeAt(int index) {
    if (index < 0 || index >= count) return false;
    assert(index < count);
    final int last = count - 1;
    types[index] = types[last];
    refIds[index] = refIds[last];
    quantities[index] = quantities[last];
    unitPriceCents[index] = unitPriceCents[last];
    subtotalCents[index] = subtotalCents[last];
    types[last] = 0;
    refIds[last] = 0;
    quantities[last] = 0;
    unitPriceCents[last] = 0;
    subtotalCents[last] = 0;
    count--;
    return true;
  }

  /// Removes every draft line referencing [type] and [refId].
  void removeCatalogRef(int type, int refId) {
    var i = 0;
    while (i < count && i < maxLimit) {
      if (types[i] == type && refIds[i] == refId) {
        removeAt(i);
      } else {
        i++;
      }
    }
  }

  /// Recomputes subtotals and returns the draft total in cents.
  int computeTotals() {
    var total = 0;
    for (var i = 0; i < count && i < maxLimit; i++) {
      final int subtotal = unitPriceCents[i] * quantities[i];
      subtotalCents[i] = subtotal;
      total += subtotal;
    }
    return total;
  }

  /// Clears all active draft lines.
  void clear() {
    for (var i = 0; i < count && i < maxLimit; i++) {
      types[i] = 0;
      refIds[i] = 0;
      quantities[i] = 0;
      unitPriceCents[i] = 0;
      subtotalCents[i] = 0;
    }
    count = 0;
  }
}

/// SQLite-backed quote module store.
class QuoteStore {
  /// Creates a store.
  ///
  /// If [databasePath] is omitted, [open] uses the app documents directory.
  QuoteStore({String? databasePath})
    : _databasePath = databasePath,
      items = ItemData(maxLimit),
      services = ItemData(maxLimit),
      clients = ClientData(maxLimit),
      quotes = QuoteData(maxLimit),
      draft = QuoteCalcBuffer(initialCap),
      errors = ErrorLogBuffer(256);

  /// Item rows mirrored from SQLite.
  final ItemData items;

  /// Service rows mirrored from SQLite.
  final ItemData services;

  /// Client rows mirrored from SQLite.
  final ClientData clients;

  /// Saved quote rows mirrored from SQLite.
  final QuoteData quotes;

  /// Mutable in-memory draft quote.
  final QuoteCalcBuffer draft;

  /// Error side-channel for failed operations.
  final ErrorLogBuffer errors;

  /// Notifies when [items] changes.
  final StoreNotifier itemsNotifier = StoreNotifier();

  /// Notifies when [services] changes.
  final StoreNotifier servicesNotifier = StoreNotifier();

  /// Notifies when [clients] changes.
  final StoreNotifier clientsNotifier = StoreNotifier();

  /// Notifies when [quotes] changes.
  final StoreNotifier quotesNotifier = StoreNotifier();

  /// Notifies when [draft] changes.
  final StoreNotifier quoteDraftNotifier = StoreNotifier();

  /// Notifies when [errors] changes.
  final StoreNotifier errorsNotifier = StoreNotifier();

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
    _db?.dispose();
    itemsNotifier.dispose();
    servicesNotifier.dispose();
    clientsNotifier.dispose();
    quotesNotifier.dispose();
    quoteDraftNotifier.dispose();
    errorsNotifier.dispose();
  }

  /// Inserts a client and mirrors it into [clients].
  bool addClient(String name, String phone, String email, String address) {
    if (!_validName(name)) return _fail(errInvalidInput, "Client name required");
    if (clients.count >= maxLimit) return _fail(errCapReached, "Client cap reached");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute("INSERT INTO clients (name, phone, email, address) VALUES (?, ?, ?, ?)", [
        name,
        phone,
        email,
        address,
      ]);
      final int id = db.lastInsertRowId;
      if (!clients.append(id, name, phone, email, address)) {
        return _fail(errCapReached, "Client RAM cap reached");
      }
      clientsNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  /// Updates a client by [id] and mirrors it into [clients].
  bool updateClient(int id, String name, String phone, String email, String address) {
    if (!_validName(name)) return _fail(errInvalidInput, "Client name required");
    if (clients.indexOfId(id) < 0) return _fail(errMissingId, "Client missing");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    try {
      db.execute("UPDATE clients SET name = ?, phone = ?, email = ?, address = ? WHERE id = ?", [
        name,
        phone,
        email,
        address,
        id,
      ]);
      clients.update(id, name, phone, email, address);
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

  /// Inserts an item and mirrors it into [items].
  bool addItem(String name, String description, int priceCents) {
    return _addCatalog(false, name, description, priceCents);
  }

  /// Inserts a service and mirrors it into [services].
  bool addService(String name, String description, int priceCents) {
    return _addCatalog(true, name, description, priceCents);
  }

  /// Updates an item by [id].
  bool updateItem(int id, String name, String description, int priceCents) {
    return _updateCatalog(false, id, name, description, priceCents);
  }

  /// Updates a service by [id].
  bool updateService(int id, String name, String description, int priceCents) {
    return _updateCatalog(true, id, name, description, priceCents);
  }

  /// Deletes an item by [id] and removes matching draft lines.
  bool deleteItem(int id) {
    return _deleteCatalog(false, id);
  }

  /// Deletes a service by [id] and removes matching draft lines.
  bool deleteService(int id) {
    return _deleteCatalog(true, id);
  }

  /// Adds or increments a draft line for [type] and [refId].
  bool addDraftLine(int type, int refId, int quantity) {
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
    final int next = math.max(1, math.min(9999, draft.quantities[index] + delta));
    if (!draft.setQuantity(index, next)) return _fail(errInvalidInput, "Invalid quantity");
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
    final int createdAt = DateTime.now().millisecondsSinceEpoch;
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
        stmt.dispose();
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
  int priceFor(int type, int refId) {
    final ItemData data = type == quoteLineService ? services : items;
    final int index = data.indexOfId(refId);
    if (index < 0) return -1;
    return data.priceCents[index];
  }

  /// Returns the catalog name for [type] and [refId], or `""` if missing.
  String nameFor(int type, int refId) {
    final ItemData data = type == quoteLineService ? services : items;
    final int index = data.indexOfId(refId);
    if (index < 0) return "";
    return data.names[index];
  }

  /// Returns the catalog description for [type] and [refId], or `""` if missing.
  String descriptionFor(int type, int refId) {
    final ItemData data = type == quoteLineService ? services : items;
    final int index = data.indexOfId(refId);
    if (index < 0) return "";
    return data.descriptions[index];
  }

  /// Returns the most recent error message, or `""` when there are no errors.
  String latestErrorMessage() {
    if (errors.count <= 0) return "";
    return errors.messageAt(errors.count - 1);
  }

  bool _addCatalog(bool isService, String name, String description, int priceCents) {
    if (!_validName(name)) return _fail(errInvalidInput, "Catalog name required");
    if (priceCents < 0) return _fail(errInvalidInput, "Invalid price");
    final ItemData data = isService ? services : items;
    if (data.count >= maxLimit) return _fail(errCapReached, "Catalog cap reached");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    final String table = isService ? "services" : "items";
    try {
      db.execute("INSERT INTO $table (name, description, price_cents) VALUES (?, ?, ?)", [
        name,
        description,
        priceCents,
      ]);
      final int id = db.lastInsertRowId;
      if (!data.append(id, name, description, priceCents)) {
        return _fail(errCapReached, "Catalog RAM cap reached");
      }
      (isService ? servicesNotifier : itemsNotifier).markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  bool _updateCatalog(bool isService, int id, String name, String description, int priceCents) {
    if (!_validName(name)) return _fail(errInvalidInput, "Catalog name required");
    if (priceCents < 0) return _fail(errInvalidInput, "Invalid price");
    final ItemData data = isService ? services : items;
    if (data.indexOfId(id) < 0) return _fail(errMissingId, "Catalog missing");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    final String table = isService ? "services" : "items";
    try {
      db.execute("UPDATE $table SET name = ?, description = ?, price_cents = ? WHERE id = ?", [
        name,
        description,
        priceCents,
        id,
      ]);
      data.update(id, name, description, priceCents);
      final int type = isService ? quoteLineService : quoteLineItem;
      final int draftIndex = draft.lineIndex(type, id);
      if (draftIndex >= 0) {
        draft.unitPriceCents[draftIndex] = priceCents;
        draft.setQuantity(draftIndex, draft.quantities[draftIndex]);
        quoteDraftNotifier.markChanged();
      }
      (isService ? servicesNotifier : itemsNotifier).markChanged();
      return true;
    } catch (error) {
      return _fail(errSqlWrite, error.toString());
    }
  }

  bool _deleteCatalog(bool isService, int id) {
    final ItemData data = isService ? services : items;
    if (data.indexOfId(id) < 0) return _fail(errMissingId, "Catalog missing");
    final Database? db = _db;
    if (db == null) return _fail(errDbOpen, "DB not open");
    final String table = isService ? "services" : "items";
    try {
      db.execute("DELETE FROM $table WHERE id = ?", [id]);
      data.deleteById(id);
      final int type = isService ? quoteLineService : quoteLineItem;
      draft.removeCatalogRef(type, id);
      (isService ? servicesNotifier : itemsNotifier).markChanged();
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
  address  TEXT NOT NULL DEFAULT ''
);
CREATE TABLE items (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
  description  TEXT NOT NULL DEFAULT '',
  price_cents  INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE services (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
  description  TEXT NOT NULL DEFAULT '',
  price_cents  INTEGER NOT NULL DEFAULT 0
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
PRAGMA user_version = 1;
""");
        version = 1;
      }
      if (version < 2) {
        db.execute("PRAGMA user_version = 2;");
      }
      return true;
    } catch (error) {
      return _fail(errDbMigration, error.toString());
    }
  }

  bool _load(Database db) {
    try {
      if (!_loadClients(db)) return false;
      if (!_loadCatalog(db, false)) return false;
      if (!_loadCatalog(db, true)) return false;
      if (!_loadQuotes(db)) return false;
      clientsNotifier.markChanged();
      itemsNotifier.markChanged();
      servicesNotifier.markChanged();
      quotesNotifier.markChanged();
      return true;
    } catch (error) {
      return _fail(errDbLoad, error.toString());
    }
  }

  bool _loadClients(Database db) {
    final ResultSet rows = db.select(
      "SELECT id, name, phone, email, address FROM clients ORDER BY id DESC",
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
      );
      if (!ok) return _fail(errCapReached, "Client load cap reached");
    }
    return true;
  }

  bool _loadCatalog(Database db, bool isService) {
    final String table = isService ? "services" : "items";
    final ItemData data = isService ? services : items;
    final ResultSet rows = db.select(
      "SELECT id, name, description, price_cents FROM $table ORDER BY id DESC",
    );
    if (rows.length > maxLimit) return _fail(errCapReached, "Catalog DB cap exceeded");
    data.count = 0;
    for (final Row row in rows) {
      final bool ok = data.append(
        row["id"] as int,
        row["name"] as String,
        row["description"] as String,
        row["price_cents"] as int,
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
        row["created_at"] as int,
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
}
