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
    required this.clientName,
    required this.status,
    required this.totalCents,
    required this.updatedAt,
    required this.serviceCount,
    required this.equipmentCount,
  });

  final int id;

  /// The client name copied into the quote, or `""` when it has no client.
  final String clientName;
  final String status;
  final int totalCents;
  final int updatedAt;
  final int serviceCount;
  final int equipmentCount;

  bool get isDraft => status == "draft";
}

/// A single line of a quote (draft or saved), holding its own copy of the catalog item.
class QuoteLine {
  const QuoteLine({
    required this.type,
    required this.refId,
    required this.name,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.unitPriceCents,
    required this.subtotalCents,
    required this.isNew,
  });

  final CatalogItemType type;
  final int refId;
  final String name;
  final String description;
  final String unit;
  final int quantity;
  final int unitPriceCents;
  final int subtotalCents;

  /// Whether this line created its catalog item ("novo no catálogo"); cleared on save.
  final bool isNew;
}

/// A quote line fully resolved for PDF rendering: the catalog name and unit
/// abbreviation are already joined in, so rendering needs no follow-up queries.
class QuotePdfLine {
  const QuotePdfLine({
    required this.type,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitPriceCents,
    required this.subtotalCents,
  });

  final CatalogItemType type;
  final String name;
  final String description;
  final int quantity;
  final String unit;
  final int unitPriceCents;
  final int subtotalCents;
}

/// The newest PDF renderer version: drafts render with it and saving records it.
const int newestPdfRenderer = 1;

/// The whole quote document, gathered by a single query: what the PDF prints.
class QuotePdfData {
  const QuotePdfData({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.client,
    required this.payment,
    required this.warranty,
    required this.validity,
    required this.terms,
    required this.notes,
    required this.rendererVersion,
    required this.showUnitPrice,
    required this.equipmentPriceMode,
    required this.closedTotalCents,
    required this.markupPercent,
    required this.lines,
  });

  final int id;
  final int createdAt;
  final String status;

  /// The client copied into the quote, or `null` when it has none.
  final Client? client;
  final String payment;
  final String warranty;
  final String validity;
  final String terms;
  final String notes;

  /// The stored renderer version of a saved quote; [newestPdfRenderer] for a draft.
  final int rendererVersion;

  // Preço dos equipamentos (used from part 2).
  final bool showUnitPrice;
  final int equipmentPriceMode;
  final int closedTotalCents;
  final int markupPercent;
  final List<QuotePdfLine> lines;
}
