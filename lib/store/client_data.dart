import "dart:typed_data";

import "package:delforte/store/quote_store.dart";


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
