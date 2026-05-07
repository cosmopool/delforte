import "dart:typed_data";

import "package:delforte/store/quote_store.dart";

/// Struct-of-arrays buffer for payment-method rows.
class PaymentMethodData {
  /// Creates a fixed-size payment-method buffer with [capacity] rows.
  PaymentMethodData(int capacity)
    : ids = Int64List(capacity),
      names = List<String>.filled(capacity, "", growable: false);

  /// SQLite row ids.
  final Int64List ids;

  /// Payment method names.
  final List<String> names;

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

  /// Returns the index for [id], or `-1` when it is not present.
  int indexOfId(int id) {
    for (var i = 0; i < count && i < maxLimit; i++) {
      if (ids[i] == id) return i;
    }
    return -1;
  }

  /// Appends a row and returns whether it fit in the buffer.
  bool append(int id, String name) {
    if (count >= ids.length || count >= maxLimit) return false;
    ids[count] = id;
    names[count] = name;
    count++;
    return true;
  }

  /// Updates the row with [id] and returns whether it existed.
  bool update(int id, String name) {
    final int index = indexOfId(id);
    if (index < 0) return false;
    ids[index] = id;
    names[index] = name;
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
    ids[last] = 0;
    names[last] = "";
    count--;
    return true;
  }
}
