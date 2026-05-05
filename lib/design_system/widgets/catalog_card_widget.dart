import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/field_summary_widget.dart";
import "package:delforte/design_system/widgets/round_button_widget.dart";
import "package:delforte/design_system/widgets/tap_card_widget.dart";
import "package:flutter/material.dart";

class CatalogCard extends StatelessWidget {
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

  final String name;
  final String description;
  final String price;
  final IconData icon;
  final bool expanded;
  final int selectedQuantity;
  final VoidCallback onToggle;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
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
                      Expanded(
                        child: FieldSummary(label: "Qty", value: selectedQuantity.toString()),
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
