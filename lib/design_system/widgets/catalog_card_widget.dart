import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/form_field_widget.dart";
import "package:delforte/design_system/widgets/round_button_widget.dart";
import "package:delforte/design_system/widgets/tap_card_widget.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

/// A card widget for displaying catalog items with expandable details.
///
/// This card shows an item's name, description, price, and icon. When expanded,
/// it displays additional controls for adjusting quantity or removing the item.
/// The card supports selection state and provides callbacks for all user interactions.
class CatalogCard extends StatefulWidget {
  /// Creates a catalog card widget.
  ///
  /// [name] is the item name displayed in the card.
  /// [description] is the optional item description.
  /// [price] is the item price as a string.
  /// [unitPrice] is the editable unit price in cents (0 when not in draft).
  /// [icon] is the icon displayed for the item.
  /// [expanded] indicates whether the card is currently expanded.
  /// [selectedQuantity] is the current quantity selected (0 if not selected).
  /// [onToggle] is called when the card is tapped to toggle expansion.
  /// [onAdd] is called when the add button is pressed.
  /// [onDecrease] is called when the decrease button is pressed.
  /// [onIncrease] is called when the increase button is pressed.
  /// [onRemove] is called when the remove button is pressed.
  /// [onUnitPriceChanged] is called when the user edits the unit price.
  const CatalogCard({
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.expanded,
    required this.selectedQuantity,
    required this.onToggle,
    required this.onDecrease,
    required this.onIncrease,
    this.unitPrice = 0,
    this.onUnitPriceChanged,
    super.key,
  });

  /// The item name displayed in the card.
  final String name;

  /// The optional item description.
  final String description;

  /// The item price as a string.
  final String price;

  /// The current editable unit price in cents (0 when not in draft).
  final int unitPrice;

  /// The icon displayed for the item.
  final IconData icon;

  /// Whether the card is currently expanded.
  final bool expanded;

  /// The current quantity selected (0 if not selected).
  final int selectedQuantity;

  /// Called when the card is tapped to toggle expansion.
  final VoidCallback onToggle;

  /// Called when the decrease button is pressed.
  final VoidCallback onDecrease;

  /// Called when the increase button is pressed.
  final VoidCallback onIncrease;

  /// Called when the user edits the unit price.
  final ValueChanged<int>? onUnitPriceChanged;

  @override
  State<CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends State<CatalogCard> {
  late final _priceController = TextEditingController()..text = "0";

  void _submitPrice(String text) {
    final int digits = moneyStringToCents(text);
    final String decimal = formatMoney(digits);
    _priceController.text = decimal;
    widget.onUnitPriceChanged?.call(digits);
  }

  @override
  void initState() {
    super.initState();
    _priceController.text = formatMoney(widget.unitPrice);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.selectedQuantity > 0;
    const FontWeight weight = FontWeight.w800;
    const FontWeight weight2 = FontWeight.w700;
    const Color color = VigilColors.textSecondary;
    const FontWeight weight3 = FontWeight.w700;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapCard(
        selected: widget.expanded || selected,
        onTap: widget.onToggle,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  VigilIconBox(
                    icon: widget.icon,
                    color: widget.expanded || selected
                        ? VigilColors.primary
                        : VigilColors.textMuted,
                    background: VigilColors.canvas,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: VigilType.body(
                            color: VigilColors.textPrimary,
                            size: 14,
                            weight: weight2,
                          ),
                        ),
                        if (widget.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VigilType.small(
                              color: VigilColors.textMuted,
                              size: 11,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!widget.expanded)
                    Text(
                      selected ? "${widget.selectedQuantity} x ${widget.price}" : widget.price,
                      style: VigilType.small(color: color, size: 11, weight: weight3),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    widget.expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: VigilColors.textMuted,
                  ),
                ],
              ),
            ),
            if (widget.expanded)
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: VigilColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 11, 15, 14),
                  child: Row(
                    crossAxisAlignment: .end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FormFieldWidget(
                              onChanged: _submitPrice,
                              controller: _priceController,
                              label: "Unit Price",
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: false,
                                signed: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          RoundButton(icon: Icons.remove_rounded, onPressed: widget.onDecrease),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "${widget.selectedQuantity}",
                              style: VigilType.body(
                                color: VigilColors.textPrimary,
                                size: 14,
                                weight: weight,
                              ),
                            ),
                          ),
                          RoundButton(icon: Icons.add_rounded, onPressed: widget.onIncrease),
                        ],
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
