/// Single-row buffer for quote default settings.
///
/// Exactly one row (id == 1) is expected in the backing table.
class QuoteDefaultsData {
  QuoteDefaultsData() : id = 0, paymentMethod = "", validity = "", warranty = "", terms = "";

  /// SQLite row id (always `1` when persisted).
  int id;

  /// Default payment method text.
  String paymentMethod;

  /// Default quote validity text.
  String validity;

  /// Default warranty text.
  String warranty;

  /// Default terms & conditions text.
  String terms;

  /// Whether this row has been loaded from the database.
  bool get hasData => id != 0;
}
