/// Single-row buffer for PDF appearance settings.
///
/// Exactly one row (id == 1) is expected in the backing table.
class PdfSettingsData {
  PdfSettingsData()
    : id = 0,
      accentColour = "";

  /// SQLite row id (always `1` when persisted).
  int id;

  /// Accent colour name (e.g. "Navy Blue (default)").
  String accentColour;

  /// Whether this row has been loaded from the database.
  bool get hasData => id != 0;
}
