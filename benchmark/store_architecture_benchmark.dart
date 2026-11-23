import "package:flutter/foundation.dart";

enum CatalogItemType { equipment, service }

const int _defaultRows = 10000;
const int _defaultDraftLines = 2048;
const int _defaultLookups = 4096;
const int _defaultUpdates = 512;
const int _defaultTotalPasses = 100;
const int _defaultWarmups = 2;
const int _defaultSamples = 7;

int _sink = 0;

void main(List<String> args) {
  final BenchmarkConfig config = BenchmarkConfig.fromArgs(args);
  final List<BenchmarkTarget> targets = <BenchmarkTarget>[
    BenchmarkTarget("SOA typed buffers", () => SoaStore(config.rows, config.draftLines)),
    BenchmarkTarget("AOS records", () => AosStore(config.rows, config.draftLines)),
    BenchmarkTarget("OOP objects", () => OopStore(config.rows, config.draftLines)),
  ];

  _printResults(config, "Mixed store operations", _measureAll(config, targets, _runMixedScenario));
  _printResults(
    config,
    "Large quote total recomputation only",
    _measureAll(config, targets, _runTotalScenario),
  );
  _printResults(
    config,
    "Bulk price update over all catalog rows",
    _measureAll(config, targets, _runBulkPriceScenario),
  );
  _printResults(
    config,
    "Filtering/summing numeric catalog data",
    _measureAll(config, targets, _runFilterSumScenario),
  );
}

List<BenchmarkResult> _measureAll(
  BenchmarkConfig config,
  List<BenchmarkTarget> targets,
  int Function(StoreScenario store, BenchmarkConfig config) run,
) {
  return <BenchmarkResult>[
    for (final BenchmarkTarget target in targets) _measure(target.name, config, target.create, run),
  ];
}

BenchmarkResult _measure(
  String name,
  BenchmarkConfig config,
  StoreScenario Function() create,
  int Function(StoreScenario store, BenchmarkConfig config) run,
) {
  var checksum = 0;
  for (var i = 0; i < config.warmups; i++) {
    checksum ^= run(create(), config);
  }

  final List<int> micros = <int>[];
  for (var i = 0; i < config.samples; i++) {
    final StoreScenario store = create();
    final Stopwatch watch = Stopwatch()..start();
    checksum ^= run(store, config);
    watch.stop();
    micros.add(watch.elapsedMicroseconds);
  }

  micros.sort();
  _sink ^= checksum;
  return BenchmarkResult(name: name, micros: micros, checksum: checksum);
}

int _runMixedScenario(StoreScenario store, BenchmarkConfig config) {
  var checksum = 0;
  checksum ^= store.seedCatalog(config.rows);
  checksum ^= store.addDraftLines(config.draftLines);
  checksum ^= store.lookupPriceSweep(config.lookups);
  checksum ^= store.updatePriceSweep(config.updates);
  checksum ^= store.computeTotals(config.totalPasses);
  checksum ^= store.removeDraftRefs(97);
  checksum ^= store.computeTotals(1);
  return checksum;
}

int _runTotalScenario(StoreScenario store, BenchmarkConfig config) {
  var checksum = 0;
  checksum ^= store.seedCatalog(config.rows);
  checksum ^= store.addDraftLines(config.draftLines);
  checksum ^= store.computeTotals(config.totalPasses);
  return checksum;
}

int _runBulkPriceScenario(StoreScenario store, BenchmarkConfig config) {
  var checksum = 0;
  checksum ^= store.seedCatalog(config.rows);
  checksum ^= store.bulkUpdatePrices(config.totalPasses);
  return checksum;
}

int _runFilterSumScenario(StoreScenario store, BenchmarkConfig config) {
  var checksum = 0;
  checksum ^= store.seedCatalog(config.rows);
  checksum ^= store.filterSumPrices(config.totalPasses);
  return checksum;
}

void _printResults(BenchmarkConfig config, String title, List<BenchmarkResult> results) {
  final BenchmarkResult baseline = results.first;
  debugPrint(title);
  debugPrint(
    "rows=${config.rows} draft=${config.draftLines} lookups=${config.lookups} "
    "updates=${config.updates} totalPasses=${config.totalPasses} "
    "warmups=${config.warmups} samples=${config.samples}",
  );
  debugPrint("");
  debugPrint("Architecture        median ms   avg ms   min ms   max ms   vs SOA");
  for (final BenchmarkResult result in results) {
    final double ratio = result.medianMicros / baseline.medianMicros;
    debugPrint(
      "${result.name.padRight(18)} "
      "${_ms(result.medianMicros).padLeft(9)} "
      "${_ms(result.averageMicros).padLeft(8)} "
      "${_ms(result.minMicros).padLeft(8)} "
      "${_ms(result.maxMicros).padLeft(8)} "
      "${ratio.toStringAsFixed(2).padLeft(7)}x",
    );
  }
  debugPrint("");
  debugPrint("checksum=$_sink");
}

String _ms(num micros) => (micros / 1000).toStringAsFixed(3);

abstract class StoreScenario {
  int seedCatalog(int rows);

  int addDraftLines(int lines);

  int lookupPriceSweep(int lookups);

  int updatePriceSweep(int updates);

  int computeTotals(int passes);

  int removeDraftRefs(int divisor);

  int bulkUpdatePrices(int passes);

  int filterSumPrices(int passes);
}

class SoaStore implements StoreScenario {
  SoaStore(int catalogCapacity, int draftCapacity)
    : ids = Int64List(catalogCapacity),
      priceCents = Int64List(catalogCapacity),
      unitIds = Int64List(catalogCapacity),
      names = List<String>.filled(catalogCapacity, "", growable: false),
      descriptions = List<String>.filled(catalogCapacity, "", growable: false),
      draftTypes = Int32List(draftCapacity),
      draftRefIds = Int64List(draftCapacity),
      draftQuantities = Int32List(draftCapacity),
      draftUnitPriceCents = Int64List(draftCapacity),
      draftSubtotalCents = Int64List(draftCapacity);

  final Int64List ids;
  final Int64List priceCents;
  final Int64List unitIds;
  final List<String> names;
  final List<String> descriptions;
  final Int32List draftTypes;
  final Int64List draftRefIds;
  final Int32List draftQuantities;
  final Int64List draftUnitPriceCents;
  final Int64List draftSubtotalCents;
  int count = 0;
  int draftCount = 0;
  final Map<int, int> _idToIndex = <int, int>{};

  @override
  int seedCatalog(int rows) {
    var checksum = 0;
    for (var i = 0; i < rows; i++) {
      final int id = i + 1;
      final int price = _priceForSeed(i);
      ids[i] = id;
      priceCents[i] = price;
      unitIds[i] = i % 12;
      names[i] = "Catalog $id";
      descriptions[i] = "Description $id";
      checksum ^= price;
    }
    count = rows;
    _idToIndex.clear();
    for (var i = 0; i < count; i++) {
      _idToIndex[ids[i]] = i;
    }
    return checksum ^ count;
  }

  @override
  int addDraftLines(int lines) {
    var checksum = 0;
    for (var i = 0; i < lines; i++) {
      final int refId = (i % count) + 1;
      final int index = indexOfId(refId);
      final int quantity = (i % 5) + 1;
      final int price = priceCents[index];
      draftTypes[i] = i & 1;
      draftRefIds[i] = refId;
      draftQuantities[i] = quantity;
      draftUnitPriceCents[i] = price;
      draftSubtotalCents[i] = price * quantity;
      checksum ^= draftSubtotalCents[i];
    }
    draftCount = lines;
    return checksum ^ draftCount;
  }

  @override
  int lookupPriceSweep(int lookups) {
    var checksum = 0;
    for (var i = 0; i < lookups; i++) {
      final int refId = ((i * 37) % count) + 1;
      final int index = indexOfId(refId);
      checksum ^=
          priceCents[index] + unitIds[index] + names[index].length + descriptions[index].length;
    }
    return checksum;
  }

  @override
  int updatePriceSweep(int updates) {
    var checksum = 0;
    for (var i = 0; i < updates; i++) {
      final int refId = ((i * 53) % count) + 1;
      final int catalogIndex = indexOfId(refId);
      final int nextPrice = priceCents[catalogIndex] + 125;
      priceCents[catalogIndex] = nextPrice;
      checksum ^= nextPrice;
      for (var draftIndex = 0; draftIndex < draftCount; draftIndex++) {
        if (draftRefIds[draftIndex] == refId) {
          draftUnitPriceCents[draftIndex] = nextPrice;
          draftSubtotalCents[draftIndex] = nextPrice * draftQuantities[draftIndex];
          checksum ^= draftSubtotalCents[draftIndex];
        }
      }
    }
    return checksum;
  }

  @override
  int computeTotals(int passes) {
    var checksum = 0;
    for (var pass = 0; pass < passes; pass++) {
      var total = 0;
      for (var i = 0; i < draftCount; i++) {
        final int subtotal = draftUnitPriceCents[i] * draftQuantities[i];
        draftSubtotalCents[i] = subtotal;
        total += subtotal;
      }
      checksum ^= total;
    }
    return checksum;
  }

  @override
  int removeDraftRefs(int divisor) {
    var checksum = 0;
    var i = 0;
    while (i < draftCount) {
      if (draftRefIds[i] % divisor == 0) {
        checksum ^= draftSubtotalCents[i];
        removeDraftAt(i);
      } else {
        i++;
      }
    }
    return checksum ^ draftCount;
  }

  @override
  int bulkUpdatePrices(int passes) {
    var checksum = 0;
    for (var pass = 0; pass < passes; pass++) {
      for (var i = 0; i < count; i++) {
        final int nextPrice = priceCents[i] + ((i + pass) & 7) + 1;
        priceCents[i] = nextPrice;
        checksum ^= nextPrice;
      }
    }
    return checksum;
  }

  @override
  int filterSumPrices(int passes) {
    var checksum = 0;
    for (var pass = 0; pass < passes; pass++) {
      var total = 0;
      var matches = 0;
      final int threshold = 1000 + ((pass * 997) % 90000);
      for (var i = 0; i < count; i++) {
        final int price = priceCents[i];
        if (price >= threshold && (unitIds[i] & 1) == 0) {
          total += price;
          matches++;
        }
      }
      checksum ^= total ^ matches;
    }
    return checksum;
  }

  int indexOfId(int id) => _idToIndex[id] ?? -1;

  void removeDraftAt(int index) {
    final int last = draftCount - 1;
    draftTypes[index] = draftTypes[last];
    draftRefIds[index] = draftRefIds[last];
    draftQuantities[index] = draftQuantities[last];
    draftUnitPriceCents[index] = draftUnitPriceCents[last];
    draftSubtotalCents[index] = draftSubtotalCents[last];
    draftTypes[last] = 0;
    draftRefIds[last] = 0;
    draftQuantities[last] = 0;
    draftUnitPriceCents[last] = 0;
    draftSubtotalCents[last] = 0;
    draftCount--;
  }
}

typedef CatalogRecord = ({String description, int id, String name, int priceCents, int unitId});
typedef DraftRecord = ({
  int quantity,
  int refId,
  int subtotalCents,
  CatalogItemType type,
  int unitPriceCents,
});

class AosStore implements StoreScenario {
  AosStore(int catalogCapacity, int draftCapacity)
    : catalog = List<CatalogRecord>.empty(growable: true),
      draft = List<DraftRecord>.empty(growable: true) {
    catalog.length = 0;
    draft.length = 0;
  }

  final List<CatalogRecord> catalog;
  final List<DraftRecord> draft;
  final Map<int, int> _idToIndex = <int, int>{};

  @override
  int seedCatalog(int rows) {
    var checksum = 0;
    for (var i = 0; i < rows; i++) {
      final int id = i + 1;
      final int price = _priceForSeed(i);
      catalog.add((
        id: id,
        name: "Catalog $id",
        description: "Description $id",
        priceCents: price,
        unitId: i % 12,
      ));
      checksum ^= price;
    }
    _idToIndex.clear();
    for (var i = 0; i < catalog.length; i++) {
      _idToIndex[catalog[i].id] = i;
    }
    return checksum ^ catalog.length;
  }

  @override
  int addDraftLines(int lines) {
    var checksum = 0;
    for (var i = 0; i < lines; i++) {
      final int refId = (i % catalog.length) + 1;
      final int index = indexOfId(refId);
      final int quantity = (i % 5) + 1;
      final int price = catalog[index].priceCents;
      final int subtotal = price * quantity;
      draft.add((
        type: CatalogItemType.values[i & 1],
        refId: refId,
        quantity: quantity,
        unitPriceCents: price,
        subtotalCents: subtotal,
      ));
      checksum ^= subtotal;
    }
    return checksum ^ draft.length;
  }

  @override
  int lookupPriceSweep(int lookups) {
    var checksum = 0;
    for (var i = 0; i < lookups; i++) {
      final int refId = ((i * 37) % catalog.length) + 1;
      final int index = indexOfId(refId);
      final CatalogRecord row = catalog[index];
      checksum ^= row.priceCents + row.unitId + row.name.length + row.description.length;
    }
    return checksum;
  }

  @override
  int updatePriceSweep(int updates) {
    var checksum = 0;
    for (var i = 0; i < updates; i++) {
      final int refId = ((i * 53) % catalog.length) + 1;
      final int catalogIndex = indexOfId(refId);
      final CatalogRecord catalogRow = catalog[catalogIndex];
      final int nextPrice = catalogRow.priceCents + 125;
      catalog[catalogIndex] = (
        id: catalogRow.id,
        name: catalogRow.name,
        description: catalogRow.description,
        priceCents: nextPrice,
        unitId: catalogRow.unitId,
      );
      checksum ^= nextPrice;
      for (var draftIndex = 0; draftIndex < draft.length; draftIndex++) {
        final DraftRecord draftRow = draft[draftIndex];
        if (draftRow.refId == refId) {
          final int subtotal = nextPrice * draftRow.quantity;
          draft[draftIndex] = (
            type: draftRow.type,
            refId: draftRow.refId,
            quantity: draftRow.quantity,
            unitPriceCents: nextPrice,
            subtotalCents: subtotal,
          );
          checksum ^= subtotal;
        }
      }
    }
    return checksum;
  }

  @override
  int computeTotals(int passes) {
    var checksum = 0;
    for (var pass = 0; pass < passes; pass++) {
      var total = 0;
      for (var i = 0; i < draft.length; i++) {
        final DraftRecord row = draft[i];
        final int subtotal = row.unitPriceCents * row.quantity;
        draft[i] = (
          type: row.type,
          refId: row.refId,
          quantity: row.quantity,
          unitPriceCents: row.unitPriceCents,
          subtotalCents: subtotal,
        );
        total += subtotal;
      }
      checksum ^= total;
    }
    return checksum;
  }

  @override
  int removeDraftRefs(int divisor) {
    var checksum = 0;
    var i = 0;
    while (i < draft.length) {
      if (draft[i].refId % divisor == 0) {
        checksum ^= draft[i].subtotalCents;
        removeDraftAt(i);
      } else {
        i++;
      }
    }
    return checksum ^ draft.length;
  }

  @override
  int bulkUpdatePrices(int passes) {
    var checksum = 0;
    for (var pass = 0; pass < passes; pass++) {
      for (var i = 0; i < catalog.length; i++) {
        final CatalogRecord row = catalog[i];
        final int nextPrice = row.priceCents + ((i + pass) & 7) + 1;
        catalog[i] = (
          id: row.id,
          name: row.name,
          description: row.description,
          priceCents: nextPrice,
          unitId: row.unitId,
        );
        checksum ^= nextPrice;
      }
    }
    return checksum;
  }

  @override
  int filterSumPrices(int passes) {
    var checksum = 0;
    for (var pass = 0; pass < passes; pass++) {
      var total = 0;
      var matches = 0;
      final int threshold = 1000 + ((pass * 997) % 90000);
      for (final CatalogRecord row in catalog) {
        if (row.priceCents >= threshold && (row.unitId & 1) == 0) {
          total += row.priceCents;
          matches++;
        }
      }
      checksum ^= total ^ matches;
    }
    return checksum;
  }

  int indexOfId(int id) => _idToIndex[id] ?? -1;

  void removeDraftAt(int index) {
    final int last = draft.length - 1;
    draft[index] = draft[last];
    draft.removeLast();
  }
}

class OopStore implements StoreScenario {
  OopStore(int catalogCapacity, int draftCapacity)
    : catalog = List<OopCatalogItem>.empty(growable: true),
      draft = List<OopDraftLine>.empty(growable: true) {
    catalog.length = 0;
    draft.length = 0;
  }

  final List<OopCatalogItem> catalog;
  final List<OopDraftLine> draft;
  final Map<int, OopCatalogItem> _idToItem = <int, OopCatalogItem>{};

  @override
  int seedCatalog(int rows) {
    var checksum = 0;
    for (var i = 0; i < rows; i++) {
      final int id = i + 1;
      final int price = _priceForSeed(i);
      catalog.add(OopCatalogItem(id, "Catalog $id", "Description $id", price, i % 12));
      checksum ^= price;
    }
    _idToItem.clear();
    for (final OopCatalogItem item in catalog) {
      _idToItem[item.id] = item;
    }
    return checksum ^ catalog.length;
  }

  @override
  int addDraftLines(int lines) {
    var checksum = 0;
    for (var i = 0; i < lines; i++) {
      final int refId = (i % catalog.length) + 1;
      final OopCatalogItem item = itemById(refId);
      final int quantity = (i % 5) + 1;
      final OopDraftLine line = OopDraftLine(CatalogItemType.values[i & 1], item, quantity);
      draft.add(line);
      checksum ^= line.subtotalCents;
    }
    return checksum ^ draft.length;
  }

  @override
  int lookupPriceSweep(int lookups) {
    var checksum = 0;
    for (var i = 0; i < lookups; i++) {
      final int refId = ((i * 37) % catalog.length) + 1;
      final OopCatalogItem item = itemById(refId);
      checksum ^= item.lookupScore;
    }
    return checksum;
  }

  @override
  int updatePriceSweep(int updates) {
    var checksum = 0;
    for (var i = 0; i < updates; i++) {
      final int refId = ((i * 53) % catalog.length) + 1;
      final OopCatalogItem item = itemById(refId);
      final int nextPrice = item.priceCents + 125;
      item.changePrice(nextPrice);
      checksum ^= nextPrice;
      for (final OopDraftLine line in draft) {
        if (line.references(item)) {
          line.refreshFromCatalog();
          checksum ^= line.subtotalCents;
        }
      }
    }
    return checksum;
  }

  @override
  int computeTotals(int passes) {
    var checksum = 0;
    for (var pass = 0; pass < passes; pass++) {
      var total = 0;
      for (final OopDraftLine line in draft) {
        total += line.refreshSubtotal();
      }
      checksum ^= total;
    }
    return checksum;
  }

  @override
  int removeDraftRefs(int divisor) {
    var checksum = 0;
    var i = 0;
    while (i < draft.length) {
      if (draft[i].catalog.id % divisor == 0) {
        checksum ^= draft[i].subtotalCents;
        removeDraftAt(i);
      } else {
        i++;
      }
    }
    return checksum ^ draft.length;
  }

  @override
  int bulkUpdatePrices(int passes) {
    var checksum = 0;
    for (var pass = 0; pass < passes; pass++) {
      for (var i = 0; i < catalog.length; i++) {
        final OopCatalogItem item = catalog[i];
        final int nextPrice = item.priceCents + ((i + pass) & 7) + 1;
        item.changePrice(nextPrice);
        checksum ^= nextPrice;
      }
    }
    return checksum;
  }

  @override
  int filterSumPrices(int passes) {
    var checksum = 0;
    for (var pass = 0; pass < passes; pass++) {
      var total = 0;
      var matches = 0;
      final int threshold = 1000 + ((pass * 997) % 90000);
      for (final OopCatalogItem item in catalog) {
        if (item.priceCents >= threshold && (item.unitId & 1) == 0) {
          total += item.priceCents;
          matches++;
        }
      }
      checksum ^= total ^ matches;
    }
    return checksum;
  }

  OopCatalogItem itemById(int id) => _idToItem[id]!;

  void removeDraftAt(int index) {
    final int last = draft.length - 1;
    draft[index] = draft[last];
    draft.removeLast();
  }
}

class OopCatalogItem {
  OopCatalogItem(this.id, this.name, this.description, this.priceCents, this.unitId);

  final int id;
  String name;
  String description;
  int priceCents;
  int unitId;

  int get lookupScore => priceCents + unitId + name.length + description.length;

  bool matchesId(int otherId) => id == otherId;

  void changePrice(int value) {
    priceCents = value;
  }
}

class OopDraftLine {
  OopDraftLine(this.type, this.catalog, this.quantity)
    : unitPriceCents = catalog.priceCents,
      subtotalCents = catalog.priceCents * quantity;

  final CatalogItemType type;
  final OopCatalogItem catalog;
  int quantity;
  int unitPriceCents;
  int subtotalCents;

  bool references(OopCatalogItem item) => identical(catalog, item);

  void refreshFromCatalog() {
    unitPriceCents = catalog.priceCents;
    refreshSubtotal();
  }

  int refreshSubtotal() {
    subtotalCents = unitPriceCents * quantity;
    return subtotalCents;
  }
}

class BenchmarkConfig {
  const BenchmarkConfig({
    required this.rows,
    required this.draftLines,
    required this.lookups,
    required this.updates,
    required this.totalPasses,
    required this.warmups,
    required this.samples,
  });

  factory BenchmarkConfig.fromArgs(List<String> args) {
    final bool quick = args.contains("--quick");
    return BenchmarkConfig(
      rows: _argInt(args, "--rows", quick ? 2000 : _defaultRows),
      draftLines: _argInt(args, "--draft", quick ? 512 : _defaultDraftLines),
      lookups: _argInt(args, "--lookups", quick ? 512 : _defaultLookups),
      updates: _argInt(args, "--updates", quick ? 128 : _defaultUpdates),
      totalPasses: _argInt(args, "--total-passes", quick ? 25 : _defaultTotalPasses),
      warmups: _argInt(args, "--warmups", quick ? 1 : _defaultWarmups),
      samples: _argInt(args, "--samples", quick ? 3 : _defaultSamples),
    );
  }

  final int rows;
  final int draftLines;
  final int lookups;
  final int updates;
  final int totalPasses;
  final int warmups;
  final int samples;
}

class BenchmarkTarget {
  BenchmarkTarget(this.name, this.create);

  final String name;
  final StoreScenario Function() create;
}

class BenchmarkResult {
  BenchmarkResult({required this.name, required this.micros, required this.checksum});

  final String name;
  final List<int> micros;
  final int checksum;

  int get minMicros => micros.first;

  int get maxMicros => micros.last;

  int get medianMicros => micros[micros.length ~/ 2];

  double get averageMicros =>
      micros.fold<int>(0, (int sum, int value) => sum + value) / micros.length;
}

int _argInt(List<String> args, String name, int defaultValue) {
  for (var i = 0; i < args.length; i++) {
    final String arg = args[i];
    if (arg == name && i + 1 < args.length) {
      return int.tryParse(args[i + 1]) ?? defaultValue;
    }
    if (arg.startsWith("$name=")) {
      return int.tryParse(arg.substring(name.length + 1)) ?? defaultValue;
    }
  }
  return defaultValue;
}

int _priceForSeed(int index) => 1000 + ((index * 17) % 90000);
