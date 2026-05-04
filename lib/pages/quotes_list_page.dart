import "package:delforte/design_system.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store.dart";
import "package:flutter/material.dart";

class QuotesListPage extends StatefulWidget {
  const QuotesListPage({required this.store, required this.router, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;

  @override
  State<QuotesListPage> createState() => _QuotesListPageState();
}

class _QuotesListPageState extends State<QuotesListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<int> indexes = [
      for (var i = 0; i < widget.store.quotes.count; i++)
        if (query.isEmpty ||
            _clientNameById(widget.store.quotes.clientIdAt(i)).toLowerCase().contains(query))
          i,
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: VigilGradients.appBackdrop),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ClipRRect(
                borderRadius: VigilRadius.appFrameRadius,
                child: ColoredBox(color: VigilColors.canvas, child: _buildBody(indexes)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<int> indexes) {
    return Column(
      children: [
        _FlowHeader(title: "Quotes", onBack: () => widget.router.goTo(const HomeRoute())),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchField(
                controller: _searchController,
                hintText: "Search quotes...",
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              if (indexes.isEmpty)
                const _EmptyPanel(
                  icon: Icons.receipt_long_rounded,
                  title: "No quotes found",
                  subtitle: "Saved quotes will appear here.",
                )
              else
                for (final int index in indexes)
                  _QuoteCard(
                    clientName: _clientNameById(widget.store.quotes.clientIdAt(index)),
                    meta: _dateLabel(widget.store.quotes.timestampAt(index)),
                    total: _formatMoney(widget.store.quotes.totalCentsAt(index)),
                    status: "Saved",
                    statusColor: VigilColors.success,
                    statusBg: VigilColors.successSoft,
                  ),
            ],
          ),
        ),
      ],
    );
  }

  String _clientNameById(int id) {
    final int index = widget.store.clients.indexOfId(id);
    return index < 0 ? "Unknown client" : widget.store.clients.nameAt(index);
  }

  String _dateLabel(int millis) {
    if (millis <= 0) return "Draft";
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(millis);
    final DateTime now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Today";
    }
    return "${date.month.toString().padLeft(2, "0")}/${date.day.toString().padLeft(2, "0")}/${date.year}";
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
    this.onBack,
    this.stepIndex,
    this.total,
    this.totalLabel,
    this.continueLabel = "Continue",
    this.onContinue,
  });

  final String title;
  final int? stepIndex;
  final int? total;
  final String? totalLabel;
  final String continueLabel;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VigilColors.ink,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(
          children: [
            if (onBack != null) ...[
              _HeaderIconButton(icon: Icons.arrow_back_rounded, tooltip: "Back", onPressed: onBack),
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
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hintText, required this.onChanged});

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded, color: VigilColors.textMuted),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: VigilColors.textMuted),
            const SizedBox(height: 8),
            Text(title, style: _bodyStyle(weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: _smallStyle(color: VigilColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.clientName,
    required this.meta,
    required this.total,
    required this.status,
    required this.statusColor,
    required this.statusBg,
  });

  final String clientName;
  final String meta;
  final String total;
  final String status;
  final Color statusColor;
  final Color statusBg;

  @override
  Widget build(BuildContext context) {
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
                    child: Text(clientName, style: _bodyStyle(weight: FontWeight.w700)),
                  ),
                  Text(
                    total,
                    style: _smallStyle(
                      color: VigilColors.textPrimary,
                      weight: FontWeight.w800,
                      size: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(meta, style: _smallStyle(color: VigilColors.textMuted)),
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
