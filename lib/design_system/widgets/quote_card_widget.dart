import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class QuoteCard extends StatelessWidget {
  const QuoteCard({
    required this.clientName,
    required this.meta,
    required this.total,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    super.key,
  });

  final String clientName;
  final String meta;
  final String total;
  final String status;
  final Color statusColor;
  final Color statusBg;

  @override
  Widget build(BuildContext context) {
    const FontWeight weight = FontWeight.w700;
    const Color color = VigilColors.textPrimary;
    const FontWeight weight2 = FontWeight.w800;
    const Color color2 = VigilColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: VigilColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      clientName,
                      style: VigilType.body(
                        color: VigilColors.textPrimary,
                        size: 14,
                        weight: weight,
                      ),
                    ),
                  ),
                  Text(
                    total,
                    style: VigilType.small(color: color, size: 13, weight: weight2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meta,
                      style: VigilType.small(color: color2, size: 11, weight: FontWeight.w600),
                    ),
                  ),
                  VigilPill(label: status.toUpperCase(), color: statusColor, background: statusBg),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
