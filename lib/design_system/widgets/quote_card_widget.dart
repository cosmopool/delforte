import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A card widget for displaying quote information.
///
/// This widget shows a client's name, metadata, total amount, and status
/// in a bordered white container. The status is displayed as a pill badge
/// with customizable foreground and background colors.
class QuoteCard extends StatelessWidget {
  /// Creates a quote card widget.
  ///
  /// [clientName] is the name of the client.
  /// [meta] is the metadata text (e.g., date or reference).
  /// [total] is the total amount as a string.
  /// [status] is the status text displayed in the pill.
  /// [statusColor] is the text color for the status pill.
  /// [statusBg] is the background color for the status pill.
  const QuoteCard({
    required this.clientName,
    required this.meta,
    required this.total,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    this.onTap,
    super.key,
  });

  /// The name of the client.
  final String clientName;

  /// The metadata text (e.g., date or reference).
  final String meta;

  /// The total amount as a string.
  final String total;

  /// The status text displayed in the pill.
  final String status;

  /// The text color for the status pill.
  final Color statusColor;

  /// The background color for the status pill.
  final Color statusBg;

  /// Optional tap handler. When set, the card becomes tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const FontWeight weight = FontWeight.w700;
    const Color color = VigilColors.textPrimary;
    const Color color2 = VigilColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
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
                        style: VigilType.mono(color: color, size: 13, weight: FontWeight.w500),
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
                      VigilPill(
                        label: status.toUpperCase(),
                        color: statusColor,
                        background: statusBg,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
