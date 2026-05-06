import "dart:typed_data";

import "package:delforte/store/quote_store.dart";

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
