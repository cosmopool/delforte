import "package:characters/characters.dart";

String formatMoney(int cents) {
  final int safe = cents < 0 ? 0 : cents;
  final int whole = safe ~/ 100;
  final int decimal = safe % 100;
  final String raw = whole.toString();
  final StringBuffer buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final int remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(".");
  }
  return "R\$ ${buffer.toString()},${decimal.toString().padLeft(2, "0")}";
}

int moneyStringToCents(String money) {
  final String digits = money.replaceAll(RegExp(r"\D"), "");
  return int.tryParse(digits) ?? 0;
}

String initials(String value) {
  final List<String> parts = value
      .trim()
      .split(RegExp(r"\s+"))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return "--";
  if (parts.length == 1) return parts.first.characters.take(2).toUpperCase().toString();
  return "${parts.first.characters.first}${parts.last.characters.first}".toUpperCase();
}
