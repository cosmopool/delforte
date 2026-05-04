import "package:delforte/design_system.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store.dart";
import "package:flutter/material.dart";

class ReviewPage extends StatelessWidget {
  const ReviewPage({required this.store, required this.router, this.selectedClientId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int? selectedClientId;

  @override
  Widget build(BuildContext context) {
    final int total = store.draft.computeTotals();
    final int clientIndex = selectedClientId == null
        ? -1
        : store.clients.indexOfId(selectedClientId!);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: VigilGradients.appBackdrop),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ClipRRect(
                borderRadius: VigilRadius.appFrameRadius,
                child: ColoredBox(color: VigilColors.canvas, child: _buildBody(total, clientIndex)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(int total, int clientIndex) {
    return Column(
      children: [
        _FlowHeader(
          title: "Review",
          stepIndex: 3,
          continueLabel: "Looks Good",
          onBack: () =>
              router.goTo(QuoteFlowRoute(QuoteStep.items, selectedClientId: selectedClientId)),
          onContinue: _canSaveQuote ? () => _saveAndContinue(total) : null,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Panel(
                title: "Client",
                child: Row(
                  children: [
                    _InitialsAvatar(
                      text: clientIndex >= 0 ? _initials(store.clients.nameAt(clientIndex)) : "--",
                      selected: false,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientIndex >= 0
                                ? store.clients.nameAt(clientIndex)
                                : "No client selected",
                            style: _bodyStyle(weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            clientIndex >= 0
                                ? store.clients.addressAt(clientIndex)
                                : "Return to client step",
                            style: _smallStyle(color: VigilColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "Edit client",
                      onPressed: () => router.goTo(
                        QuoteFlowRoute(QuoteStep.client, selectedClientId: selectedClientId),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _LineGroup(
                title: "Services",
                lines: _draftLines(quoteLineService),
                onEdit: () => router.goTo(
                  QuoteFlowRoute(QuoteStep.services, selectedClientId: selectedClientId),
                ),
              ),
              const SizedBox(height: 10),
              _LineGroup(
                title: "Equipment",
                lines: _draftLines(quoteLineItem),
                onEdit: () => router.goTo(
                  QuoteFlowRoute(QuoteStep.items, selectedClientId: selectedClientId),
                ),
              ),
              const SizedBox(height: 10),
              _TotalBanner(label: "Total", amount: _formatMoney(total)),
            ],
          ),
        ),
      ],
    );
  }

  bool get _canSaveQuote => selectedClientId != null && store.draft.count > 0;

  void _saveAndContinue(int total) {
    if (selectedClientId == null) return;
    final bool saved = store.saveQuote(selectedClientId!);
    if (!saved) {
      // Show error - but we're in a StatelessWidget, need context
      return;
    }
    router.goTo(QuoteFlowRoute(QuoteStep.send, selectedClientId: selectedClientId));
  }

  List<_DraftLineView> _draftLines(int type) {
    return [
      for (var i = 0; i < store.draft.count; i++)
        if (store.draft.types[i] == type)
          _DraftLineView(
            name: store.nameFor(type, store.draft.refIds[i]),
            quantity: store.draft.quantities[i],
            subtotal: _formatMoney(store.draft.subtotalCents[i]),
          ),
    ];
  }

  String _initials(String value) {
    final List<String> parts = value
        .trim()
        .split(RegExp(r"\s+"))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return "--";
    if (parts.length == 1) return parts.first.characters.take(2).toUpperCase().toString();
    return "${parts.first.characters.first}${parts.last.characters.first}".toUpperCase();
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

class _DraftLineView {
  const _DraftLineView({required this.name, required this.quantity, required this.subtotal});

  final String name;
  final int quantity;
  final String subtotal;
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    this.stepIndex,
    this.continueLabel = "Continue",
    this.onBack,
    this.onContinue,
    this.total,
    this.totalLabel,
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

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: _smallStyle(
                      color: VigilColors.textMuted,
                      size: 10,
                      weight: FontWeight.w900,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

class _LineGroup extends StatelessWidget {
  const _LineGroup({required this.title, required this.lines, required this.onEdit});

  final String title;
  final List<_DraftLineView> lines;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      trailing: IconButton(
        tooltip: "Edit $title",
        onPressed: onEdit,
        icon: const Icon(Icons.edit_rounded, size: 18),
      ),
      child: lines.isEmpty
          ? Text("No lines added", style: _smallStyle(color: VigilColors.textMuted, size: 13))
          : Column(
              children: [
                for (var i = 0; i < lines.length; i++)
                  _LineRow(line: lines[i], showDivider: i < lines.length - 1),
              ],
            ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.showDivider});

  final _DraftLineView line;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: showDivider ? VigilColors.border : Colors.transparent),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      line.name,
                      overflow: TextOverflow.ellipsis,
                      style: _smallStyle(color: VigilColors.textSecondary, size: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  VigilPill(
                    label: "${line.quantity}x",
                    color: VigilColors.textMuted,
                    background: VigilColors.canvas,
                  ),
                ],
              ),
            ),
            Text(
              line.subtotal,
              style: _smallStyle(color: VigilColors.textPrimary, weight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalBanner extends StatelessWidget {
  const _TotalBanner({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: VigilColors.ink, borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: _bodyStyle(color: Colors.white, weight: FontWeight.w800, size: 15),
            ),
            Text(amount, style: _titleStyle(color: Colors.white, size: 26)),
          ],
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.text, required this.selected});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? VigilColors.primary : VigilColors.inkElevated,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: VigilType.small(color: VigilColors.surface, size: 13, weight: FontWeight.w900),
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

TextStyle _bodyStyle({
  Color color = VigilColors.textPrimary,
  FontWeight weight = FontWeight.w600,
  double size = 14,
}) {
  return VigilType.body(color: color, size: size, weight: weight);
}

TextStyle _smallStyle({
  Color color = VigilColors.textMuted,
  FontWeight weight = FontWeight.w600,
  double size = 11,
}) {
  return VigilType.small(color: color, size: size, weight: weight);
}
