import "dart:typed_data";

/// Single-row buffer for business info.
///
/// Exactly one row (id == 1) is expected in the backing table.
class BusinessInfoData {
  BusinessInfoData()
    : id = 0,
      name = "",
      cnpj = "",
      address = "",
      city = "",
      state = "",
      phone = "",
      email = "";

  /// SQLite row id (always `1` when persisted).
  int id;

  /// Business name.
  String name;

  /// CNPJ (Brazilian company ID).
  String cnpj;

  /// Street address.
  String address;

  /// City.
  String city;

  /// State abbreviation.
  String state;

  /// Phone number.
  String phone;

  /// Email address.
  String email;

  /// Logo image bytes (empty when no logo is set).
  Uint8List logo = Uint8List(0);

  /// Whether this row has been loaded from the database.
  bool get hasData => id != 0;
}
