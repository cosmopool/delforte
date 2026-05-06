import "dart:typed_data";

import "package:delforte/store/quote_store.dart";

/// Fixed-size quote draft buffer.
class QuoteCalcBuffer {
  /// Creates a fixed-size draft buffer with [capacity] lines.
  QuoteCalcBuffer(int capacity)
    : types = Int32List(capacity),
      refIds = Int64List(capacity),
      quantities = Int32List(capacity),
      unitPriceCents = Int64List(capacity),
      subtotalCents = Int64List(capacity);

  /// Line types, using [quoteLineItem] or [quoteLineService].
  final Int32List types;

  /// Referenced item or service ids.
  final Int64List refIds;

  /// Line quantities.
  final Int32List quantities;

  /// Unit prices stored as integer cents.
  final Int64List unitPriceCents;

  /// Line subtotals stored as integer cents.
  final Int64List subtotalCents;

  /// Number of active draft lines.
  int count = 0;

  /// Selected client id for the draft, or `0` when no client is selected.
  int clientId = 0;

  /// Appends a draft line and returns whether it fit in the buffer.
  bool addLine(int type, int refId, int quantity, int unitPrice) {
    if (count >= types.length || count >= maxLimit) return false;
    if (quantity <= 0 || unitPrice < 0) return false;
    types[count] = type;
    refIds[count] = refId;
    quantities[count] = quantity;
    unitPriceCents[count] = unitPrice;
    subtotalCents[count] = unitPrice * quantity;
    count++;
    return true;
  }

  /// Returns the line index for [type] and [refId], or `-1` when absent.
  int lineIndex(int type, int refId) {
    for (var i = 0; i < count && i < maxLimit; i++) {
      if (types[i] == type && refIds[i] == refId) return i;
    }
    return -1;
  }

  /// Sets [quantity] at [index] and refreshes the subtotal.
  bool setQuantity(int index, int quantity) {
    if (index < 0 || index >= count) return false;
    if (quantity <= 0) return false;
    quantities[index] = quantity;
    subtotalCents[index] = unitPriceCents[index] * quantity;
    return true;
  }

  /// Removes the line at [index] by swap-removing it.
  bool removeAt(int index) {
    if (index < 0 || index >= count) return false;
    assert(index < count);
    final int last = count - 1;
    types[index] = types[last];
    refIds[index] = refIds[last];
    quantities[index] = quantities[last];
    unitPriceCents[index] = unitPriceCents[last];
    subtotalCents[index] = subtotalCents[last];
    types[last] = 0;
    refIds[last] = 0;
    quantities[last] = 0;
    unitPriceCents[last] = 0;
    subtotalCents[last] = 0;
    count--;
    return true;
  }

  /// Removes every draft line referencing [type] and [refId].
  void removeCatalogRef(int type, int refId) {
    var i = 0;
    while (i < count && i < maxLimit) {
      if (types[i] == type && refIds[i] == refId) {
        removeAt(i);
      } else {
        i++;
      }
    }
  }

  /// Recomputes subtotals and returns the draft total in cents.
  int computeTotals() {
    var total = 0;
    for (var i = 0; i < count && i < maxLimit; i++) {
      final int subtotal = unitPriceCents[i] * quantities[i];
      subtotalCents[i] = subtotal;
      total += subtotal;
    }
    return total;
  }

  /// Clears all active draft lines.
  void clear() {
    for (var i = 0; i < count && i < maxLimit; i++) {
      types[i] = 0;
      refIds[i] = 0;
      quantities[i] = 0;
      unitPriceCents[i] = 0;
      subtotalCents[i] = 0;
    }
    count = 0;
    clientId = 0;
  }
}
