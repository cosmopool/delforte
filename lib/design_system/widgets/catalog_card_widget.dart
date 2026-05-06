import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/field_summary_widget.dart";
import "package:delforte/design_system/widgets/round_button_widget.dart";
import "package:delforte/design_system/widgets/tap_card_widget.dart";
import "package:flutter/material.dart";

/// A card widget for displaying catalog items with expandable details.
///
/// This card shows an item's name, description, price, and icon. When expanded,
/// it displays additional controls for adjusting quantity or removing the item.
/// The card supports selection state and provides callbacks for all user interactions.
class CatalogCard extends StatelessWidget {
  /// Creates a catalog card widget.
  ///
  /// [name] is the item name displayed in the card.
  /// [description] is the optional item description.
  /// [price] is the item price as a string.
  /// [icon] is the icon displayed for the item.
  /// [expanded] indicates whether the card is currently expanded.
  /// [selectedQuantity] is the current quantity selected (0 if not selected).
  /// [onToggle] is called when the card is tapped to toggle expansion.
  /// [onAdd] is called when the add button is pressed.
  /// [onDecrease] is called when the decrease button is pressed.
  /// [onIncrease] is called when the increase button is pressed.
  /// [onRemove] is called when the remove button is pressed.
  const CatalogCard({
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.expanded,
    required this.selectedQuantity,
    required this.onToggle,
    required this.onAdd,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
    super.key,
  });

  /// The item name displayed in the card.
  final String name;

  /// The optional item description.
  final String description;

  /// The item price as a string.
  final String price;

  /// The icon displayed for the item.
  final IconData icon;

  /// Whether the card is currently expanded.
  final bool expanded;

  /// The current quantity selected (0 if not selected).
  final int selectedQuantity;

  /// Called when the card is tapped to toggle expansion.
  final VoidCallback onToggle;

  /// Called when the add button is pressed.
  final VoidCallback onAdd;

  /// Called when the decrease button is pressed.
  final VoidCallback onDecrease;

  /// Called when the increase button is pressed.
  final VoidCallback onIncrease;

  /// Called when the remove button is pressed.
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool selected = selectedQuantity > 0;
    const FontWeight weight = FontWeight.w800;
    const FontWeight weight2 = FontWeight.w700;
    const Color color = VigilColors.textSecondary;
    const FontWeight weight3 = FontWeight.w700;
    const Color color2 = VigilColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapCard(
        selected: expanded || selected,
        onTap: onToggle,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  VigilIconBox(
                    icon: icon,
                    color: expanded || selected ? VigilColors.primary : VigilColors.textMuted,
                    background: expanded || selected ? VigilColors.primarySoft : VigilColors.canvas,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: VigilType.body(
                            color: VigilColors.textPrimary,
                            size: 14,
                            weight: weight2,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VigilType.small(
                              color: color2,
                              size: 11,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!expanded)
                    Text(
                      selected ? "$selectedQuantity x $price" : price,
                      style: VigilType.small(color: color, size: 11, weight: weight3),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: VigilColors.textMuted,
                  ),
                ],
              ),
            ),
            if (expanded)
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: VigilColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 11, 15, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: FieldSummary(label: "Unit Price", value: price),
                      ),
                      const SizedBox(width: 8),
                      if (selected)
                        Row(
                          children: [
                            RoundButton(icon: Icons.remove_rounded, onPressed: onDecrease),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "$selectedQuantity",
                                style: VigilType.body(
                                  color: VigilColors.textPrimary,
                                  size: 14,
                                  weight: weight,
                                ),
                              ),
                            ),
                            RoundButton(icon: Icons.add_rounded, onPressed: onIncrease),
                            IconButton(
                              tooltip: "Remove",
                              onPressed: onRemove,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: VigilColors.textMuted,
                              ),
                            ),
                          ],
                        )
                      else
                        FilledButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text("Add"),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
