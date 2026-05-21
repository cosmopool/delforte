import "dart:typed_data";

import "package:delforte/store/quote_store.dart";

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
      unitIds = Int64List(capacity),
      names = List<String>.filled(capacity, "", growable: false),
      descriptions = List<String>.filled(capacity, "", growable: false);

  /// SQLite row ids.
  final Int64List ids;

  /// Unit prices stored as integer cents.
  final Int64List priceCents;

  /// Unit ids referencing the units table.
  final Int64List unitIds;

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

  /// Returns the unit id at [index], or `0` when [index] is invalid.
  int unitIdAt(int index) {
    if (index < 0 || index >= count) return 0;
    return unitIds[index];
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
  bool append(int id, String name, String description, int cents, int unitId) {
    if (count >= ids.length || count >= maxLimit) return false;
    ids[count] = id;
    names[count] = name;
    descriptions[count] = description;
    priceCents[count] = cents;
    unitIds[count] = unitId;
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
  bool update(int id, String name, String description, int cents, int unitId) {
    final int index = indexOfId(id);
    if (index < 0) return false;
    ids[index] = id;
    names[index] = name;
    descriptions[index] = description;
    priceCents[index] = cents;
    unitIds[index] = unitId;
    return true;
  }

  /// Returns indexes of rows whose name or description contains [query].
  ///
  /// Matching is case-insensitive. An empty [query] returns every index.
  List<int> searchIndexes(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final List<int> result = <int>[];
    for (var i = 0; i < count; i++) {
      if (names[i].toLowerCase().contains(q) || descriptions[i].toLowerCase().contains(q)) {
        result.add(i);
      }
    }
    return result;
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
    unitIds[index] = unitIds[last];
    ids[last] = 0;
    names[last] = "";
    descriptions[last] = "";
    priceCents[last] = 0;
    unitIds[last] = 0;
    count--;
    return true;
  }
}
