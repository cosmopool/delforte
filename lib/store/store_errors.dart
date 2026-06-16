import "dart:typed_data";

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

/// Error code used when exporting or importing a database backup fails.
const int errDbBackup = 10;

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
