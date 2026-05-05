import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/tap_card_widget.dart";
import "package:flutter/material.dart";

class QuoteTemplate {
  const QuoteTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.itemNames,
    required this.serviceNames,
  });

  final String name;
  final String description;
  final IconData icon;
  final List<String> itemNames;
  final List<String> serviceNames;
}

class TemplateCard extends StatelessWidget {
  const TemplateCard({required this.template, required this.onUse, super.key});

  final QuoteTemplate template;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    const Color color = VigilColors.textMuted;
    const FontWeight weight = FontWeight.w700;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapCard(
        onTap: onUse,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              VigilIconBox(
                icon: template.icon,
                color: VigilColors.primary,
                background: VigilColors.primarySoft,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: VigilType.body(
                        color: VigilColors.textPrimary,
                        size: 14,
                        weight: weight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      template.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VigilType.small(color: color, size: 11, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              FilledButton(onPressed: onUse, child: const Text("Use")),
            ],
          ),
        ),
      ),
    );
  }
}
