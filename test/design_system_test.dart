import "dart:io";

import "package:delforte/design_system.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

/// `ink-elevated` -> `inkElevated`, `blue-m` -> `blueM`.
String camelCase(String kebab) {
  final List<String> parts = kebab.split("-");
  return parts.first + parts.skip(1).map((String p) => p[0].toUpperCase() + p.substring(1)).join();
}

/// `:root` custom properties of the gallery, by name without the leading `--`.
Map<String, String> rootTokens(String html) {
  final String root = RegExp(r":root\s*\{(.*?)\}", dotAll: true).firstMatch(html)!.group(1)!;
  return {
    for (final RegExpMatch m in RegExp(r"--([a-z0-9-]+)\s*:\s*([^;]+);").allMatches(root))
      m.group(1)!: m.group(2)!.trim(),
  };
}

void main() {
  final String html = File("docs/design-system.html").readAsStringSync();

  test("AC-1 every colour token in the gallery :root matches VigilColors and the reverse", () {
    // CSS #RRGGBB[AA] as ARGB.
    final Map<String, int> htmlColors = {
      for (final MapEntry<String, String> token in rootTokens(html).entries)
        if (token.key.startsWith("color-") && token.value.startsWith("#"))
          camelCase(token.key.substring("color-".length)): token.value.length == 7
              ? 0xFF000000 | int.parse(token.value.substring(1), radix: 16)
              : (int.parse(token.value.substring(7, 9), radix: 16) << 24) |
                    int.parse(token.value.substring(1, 7), radix: 16),
    };
    final String colorsSource = File("lib/design_system/colors.dart").readAsStringSync();
    final Map<String, int> dartColors = {
      for (final RegExpMatch m in RegExp(
        r"static const Color (\w+) = Color\(0x([0-9A-Fa-f]{8})\);",
      ).allMatches(colorsSource))
        m.group(1)!: int.parse(m.group(2)!, radix: 16),
    };

    expect(htmlColors, isNotEmpty);
    expect(dartColors, htmlColors);
    expect(htmlColors["paper"], 0xFFE8EBF2);
    expect(htmlColors["blueM"], 0xFF5499EE);
    expect(htmlColors["pin"], 0xFFF2542D);
    expect(VigilColors.paper, const Color(0xFFE8EBF2));
    expect(VigilColors.blueM, const Color(0xFF5499EE));
    expect(VigilColors.pin, const Color(0xFFF2542D));
  });

  test("AC-2 the gallery works offline and shows the foundations, components and screens", () {
    expect(html, isNot(matches(RegExp(r"https?://"))));
    expect(html, isNot(contains("Syne")));
    expect(rootTokens(html)["font-sans"], startsWith('"DM Sans"'));

    final List<String> fontUrls = [
      for (final RegExpMatch m in RegExp(
        r"""@font-face[^}]*url\(["']?([^"')]+)""",
      ).allMatches(html))
        m.group(1)!,
    ];
    expect(fontUrls, isNotEmpty);
    for (final String url in fontUrls) {
      expect(url, startsWith("../assets/fonts/"));
      expect(File("docs/$url").existsSync(), isTrue, reason: url);
    }

    for (final String foundation in ["Cores", "Tipografia", "Espaçamento", "Raios", "Sombras"]) {
      expect(html, matches(RegExp("<h3[^>]*>$foundation")), reason: foundation);
    }

    final Map<String, String> tokens = rootTokens(html);
    expect(tokens["radius-chip"], "${VigilRadius.chip.toInt()}px");
    expect(tokens["radius-input"], "${VigilRadius.input.toInt()}px");
    expect(tokens["radius-card"], "${VigilRadius.card.toInt()}px");
    expect(tokens["radius-feature"], "${VigilRadius.feature.toInt()}px");
    expect(tokens["radius-app-frame"], "${VigilRadius.appFrame.toInt()}px");

    final List<File> sources = Directory("lib/design_system")
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith(".dart"))
        .toList();
    final List<String> components = [
      for (final File source in sources)
        for (final RegExpMatch m in RegExp(
          r"^class ([A-Z]\w*) extends State(less|ful)Widget",
          multiLine: true,
        ).allMatches(source.readAsStringSync()))
          m.group(1)!,
    ];
    expect(components, isNotEmpty);
    for (final String component in components) {
      expect(html, contains(component), reason: "$component is missing from the gallery");
    }

    final int pages = Directory(
      "lib/pages",
    ).listSync().where((FileSystemEntity f) => f.path.endsWith("_page.dart")).length;
    expect(RegExp(r'class="phone-wrap"').allMatches(html).length, greaterThanOrEqualTo(pages));
  });
}
