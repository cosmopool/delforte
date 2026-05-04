import "package:delforte/design_system.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store.dart";
import "package:flutter/material.dart";

class SendPage extends StatefulWidget {
  const SendPage({required this.store, required this.router, this.selectedClientId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int? selectedClientId;

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  @override
  Widget build(BuildContext context) {
    final int total = widget.store.draft.computeTotals();
    final int serviceCount = _draftCountFor(quoteLineService);
    final int itemCount = _draftCountFor(quoteLineItem);
    final String clientName = _clientNameById(widget.selectedClientId ?? 0);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: VigilGradients.appBackdrop),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ClipRRect(
                borderRadius: VigilRadius.appFrameRadius,
                child: ColoredBox(
                  color: VigilColors.canvas,
                  child: _buildBody(total, serviceCount, itemCount, clientName),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(int total, int serviceCount, int itemCount, String clientName) {
    return Column(
      children: [
        _FlowHeader(
          title: "Send Quote",
          stepIndex: 4,
          onBack: () => widget.router.goTo(
            QuoteFlowRoute(QuoteStep.review, selectedClientId: widget.selectedClientId),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            children: [
              _ReadyCard(
                title: "Quote Ready",
                subtitle: "Saved locally - $clientName - ${_formatMoney(total)}",
                chips: ["$serviceCount services", "$itemCount items", _formatMoney(total)],
              ),
              const SizedBox(height: 10),
              _PrimaryButton(
                label: "Share via WhatsApp",
                icon: Icons.share_rounded,
                onPressed: () => _showSnack(context, "Sharing is not wired yet."),
              ),
              const SizedBox(height: 10),
              _SecondaryButton(
                label: "Export PDF",
                icon: Icons.picture_as_pdf_rounded,
                onPressed: () => _showSnack(context, "PDF export is not wired to the UI yet."),
              ),
              const SizedBox(height: 10),
              _SecondaryButton(
                label: "Copy Link",
                icon: Icons.link_rounded,
                onPressed: () =>
                    _showSnack(context, "Link sharing is not available for local drafts."),
              ),
              TextButton(
                onPressed: () {
                  widget.store.clearDraft();
                  widget.router.goTo(const HomeRoute());
                },
                child: const Text("Back to Home"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _draftCountFor(int type) {
    var count = 0;
    for (var i = 0; i < widget.store.draft.count; i++) {
      if (widget.store.draft.types[i] == type) count++;
    }
    return count;
  }

  String _clientNameById(int id) {
    final int index = widget.store.clients.indexOfId(id);
    return index < 0 ? "Unknown client" : widget.store.clients.nameAt(index);
  }

  void _showSnack(BuildContext context, String message) {
    if (message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatMoney(int cents) {
    final int safe = cents < 0 ? 0 : cents;
    final int whole = safe ~/ 100;
    final int decimal = safe % 100;
    final String raw = whole.toString();
    final StringBuffer buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final int remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(".");
    }
    return "R\$ ${buffer.toString()},${decimal.toString().padLeft(2, "0")}";
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    this.stepIndex,
    this.onBack,
    this.total,
    this.totalLabel,
    this.continueLabel = "Continue",
    this.onContinue,
  });

  static const List<String> _steps = ["Client", "Services", "Items", "Review", "Send"];

  final String title;
  final int? stepIndex;
  final int? total;
  final String? totalLabel;
  final String continueLabel;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final int? current = stepIndex;
    return ColoredBox(
      color: VigilColors.ink,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Row(
              children: [
                if (onBack != null) ...[
                  _HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: "Back",
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(title, style: VigilType.title(color: VigilColors.surface, size: 19)),
                ),
                if (onContinue != null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: VigilColors.primary,
                      foregroundColor: VigilColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    ),
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(continueLabel),
                  ),
              ],
            ),
          ),
          if (current != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(right: i == _steps.length - 1 ? 0 : 5),
                            decoration: BoxDecoration(
                              color: i < current
                                  ? VigilColors.primary
                                  : i == current
                                  ? const Color(0xFF5499EE)
                                  : Colors.white.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(VigilRadius.chip),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        Text(
                          _steps[i],
                          style: VigilType.small(
                            color: i == current
                                ? Colors.white.withValues(alpha: 0.95)
                                : i < current
                                ? Colors.white.withValues(alpha: 0.50)
                                : Colors.white.withValues(alpha: 0.25),
                            size: 10,
                            weight: i == current ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (total != null && totalLabel != null)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              color: Colors.white.withValues(alpha: 0.06),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    totalLabel!,
                    style: VigilType.small(
                      color: Colors.white.withValues(alpha: 0.45),
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatMoney(total!),
                    style: VigilType.body(
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatMoney(int cents) {
    final int safe = cents < 0 ? 0 : cents;
    final int whole = safe ~/ 100;
    final int decimal = safe % 100;
    final String raw = whole.toString();
    final StringBuffer buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final int remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(".");
    }
    return "R\$ ${buffer.toString()},${decimal.toString().padLeft(2, "0")}";
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.title, required this.subtitle, required this.chips});

  final String title;
  final String subtitle;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: VigilColors.successSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_circle_rounded, size: 34, color: VigilColors.success),
            ),
            const SizedBox(height: 13),
            Text(title, style: _titleStyle(size: 18), textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: _smallStyle(color: VigilColors.textSecondary, size: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final String chip in chips)
                  VigilPill(
                    label: chip,
                    color: VigilColors.primary,
                    background: VigilColors.primarySoft,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: VigilColors.primary,
          foregroundColor: VigilColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: VigilRadius.cardRadius),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: VigilColors.textPrimary,
          side: VigilStroke.strong,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: VigilRadius.cardRadius),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: VigilColors.textSecondary),
        label: Text(label),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        foregroundColor: Colors.white.withValues(alpha: 0.80),
        fixedSize: const Size(34, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      icon: Icon(icon, size: 17),
    );
  }
}

TextStyle _titleStyle({Color color = VigilColors.textPrimary, double size = 20}) {
  return VigilType.title(color: color, size: size);
}

TextStyle _smallStyle({
  Color color = VigilColors.textMuted,
  FontWeight weight = FontWeight.w600,
  double size = 11,
}) {
  return VigilType.small(color: color, size: size, weight: weight);
}
