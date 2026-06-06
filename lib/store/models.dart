/// Quote line type for a catalog reference.
///
/// The [index] is persisted in `quote_lines.line_type`, so the order of these
/// values must stay stable.
enum CatalogItemType { equipment, service }

/// A client row.
class Client {
  const Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
  });

  final int id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String city;
}

/// A catalog row (equipment or service share the same shape).
class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.unitId,
  });

  final int id;
  final String name;
  final String description;
  final int priceCents;
  final int unitId;
}

/// A unit row.
class Unit {
  const Unit({required this.id, required this.abbreviation, required this.description});

  final int id;
  final String abbreviation;
  final String description;
}

/// A payment method row.
class PaymentMethod {
  const PaymentMethod({required this.id, required this.name});

  final int id;
  final String name;
}

/// A quote row summarised for list/card display.
class QuoteSummary {
  const QuoteSummary({
    required this.id,
    required this.clientId,
    required this.status,
    required this.totalCents,
    required this.updatedAt,
    required this.serviceCount,
    required this.equipmentCount,
  });

  final int id;
  final int clientId;
  final String status;
  final int totalCents;
  final int updatedAt;
  final int serviceCount;
  final int equipmentCount;

  bool get isDraft => status == "draft";
}

/// A single line of a quote (draft or saved), with the catalog name resolved.
class QuoteLine {
  const QuoteLine({
    required this.type,
    required this.refId,
    required this.name,
    required this.quantity,
    required this.unitPriceCents,
    required this.subtotalCents,
  });

  final CatalogItemType type;
  final int refId;
  final String name;
  final int quantity;
  final int unitPriceCents;
  final int subtotalCents;
}

/// A quote line fully resolved for PDF rendering: the catalog name and unit
/// abbreviation are already joined in, so rendering needs no follow-up queries.
class QuotePdfLine {
  const QuotePdfLine({
    required this.type,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPriceCents,
    required this.subtotalCents,
  });

  final CatalogItemType type;
  final String name;
  final int quantity;
  final String unit;
  final int unitPriceCents;
  final int subtotalCents;
}

/// Everything the quote PDF reads from SQLite, gathered by a single query.
class QuotePdfData {
  const QuotePdfData({required this.createdAt, required this.client, required this.lines});

  final int createdAt;
  final Client? client;
  final List<QuotePdfLine> lines;
}
