import "dart:typed_data";

import "package:delforte/store/quote_store.dart";

/// Struct-of-arrays buffer for unit rows.
class UnitData {
  /// Creates a fixed-size unit buffer with [capacity] rows.
  UnitData(int capacity)
    : ids = Int64List(capacity),
      abbreviations = List<String>.filled(capacity, "", growable: false),
      descriptions = List<String>.filled(capacity, "", growable: false);

  /// SQLite row ids.
  final Int64List ids;

  /// Unit abbreviations (e.g. h, day, un, m^2, m).
  final List<String> abbreviations;

  /// Unit descriptions.
  final List<String> descriptions;

  /// Number of active rows.
  int count = 0;

  /// Returns the id at [index], or `0` when [index] is invalid.
  int idAt(int index) {
    if (index < 0 || index >= count) return 0;
    return ids[index];
  }

  /// Returns the abbreviation at [index], or `""` when [index] is invalid.
  String abbreviationAt(int index) {
    if (index < 0 || index >= count) return "";
    return abbreviations[index];
  }

  /// Returns the description at [index], or `""` when [index] is invalid.
  String descriptionAt(int index) {
    if (index < 0 || index >= count) return "";
    return descriptions[index];
  }

  /// Returns the index for [id], or `-1` when it is not present.
  int indexOfId(int id) {
    for (var i = 0; i < count; i++) {
      if (ids[i] == id) return i;
    }
    return -1;
  }

  /// Appends a row and returns whether it fit in the buffer.
  bool append(int id, String abbreviation, String description) {
    if (count >= ids.length || count >= maxLimit) return false;
    ids[count] = id;
    abbreviations[count] = abbreviation;
    descriptions[count] = description;
    count++;
    return true;
  }

  /// Updates the row with [id] and returns whether it existed.
  bool update(int id, String abbreviation, String description) {
    final int index = indexOfId(id);
    if (index < 0) return false;
    ids[index] = id;
    abbreviations[index] = abbreviation;
    descriptions[index] = description;
    return true;
  }

  /// Returns indexes of rows whose abbreviation or description contains [query].
  ///
  /// Matching is case-insensitive. An empty [query] returns every index.
  List<int> searchIndexes(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return List<int>.generate(count, (i) => i);
    }
    final List<int> result = <int>[];
    for (var i = 0; i < count; i++) {
      if (abbreviations[i].toLowerCase().contains(q) || descriptions[i].toLowerCase().contains(q)) {
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
    abbreviations[index] = abbreviations[last];
    descriptions[index] = descriptions[last];
    ids[last] = 0;
    abbreviations[last] = "";
    descriptions[last] = "";
    count--;
    return true;
  }
}
