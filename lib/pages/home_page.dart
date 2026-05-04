import "package:delforte/design_system.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store.dart";
import "package:flutter/material.dart";

class HomePage extends StatelessWidget {
  const HomePage({required this.store, required this.router, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        store.clientsNotifier,
        store.itemsNotifier,
        store.servicesNotifier,
        store.quotesNotifier,
        store.quoteDraftNotifier,
        store.errorsNotifier,
      ]),
      builder: (context, _) {
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(gradient: VigilGradients.appBackdrop),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: ClipRRect(
                    borderRadius: VigilRadius.appFrameRadius,
                    child: ColoredBox(color: VigilColors.canvas, child: _buildBody()),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        const _BrandHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            children: [
              Transform.translate(
                offset: const Offset(0, -16),
                child: _NewQuoteCard(
                  onTap: () {
                    store.clearDraft();
                    router.goTo(const QuoteFlowRoute(QuoteStep.client));
                  },
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -6),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        label: "Continue",
                        subtitle: "Resume a draft",
                        icon: Icons.edit_note_rounded,
                        onTap: () => router.goTo(const QuoteFlowRoute(QuoteStep.client)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        label: "Templates",
                        subtitle: "Start from preset",
                        icon: Icons.layers_rounded,
                        onTap: () => router.goTo(const TemplatesRoute()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionTitle(
                title: "Recent Quotes",
                action: "See all",
                onAction: () => router.goTo(const QuotesListRoute()),
              ),
              const SizedBox(height: 12),
              if (store.quotes.count == 0)
                const _EmptyPanel(
                  icon: Icons.receipt_long_rounded,
                  title: "No saved quotes yet",
                  subtitle: "Create a quote and save it from the review flow.",
                )
              else
                for (var i = 0; i < store.quotes.count && i < 3; i++)
                  _QuoteCard(
                    clientName: _clientNameById(store.quotes.clientIdAt(i)),
                    meta: _dateLabel(store.quotes.timestampAt(i)),
                    total: _formatMoney(store.quotes.totalCentsAt(i)),
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
    final int index = store.clients.indexOfId(id);
    return index < 0 ? "Unknown client" : store.clients.nameAt(index);
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VigilColors.ink,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 34),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Delforte",
            style: TextStyle(
              color: VigilColors.surface,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewQuoteCard extends StatelessWidget {
  const _NewQuoteCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: VigilRadius.featureRadius,
      child: Ink(
        decoration: BoxDecoration(
          gradient: VigilGradients.primaryAction,
          borderRadius: VigilRadius.featureRadius,
          boxShadow: VigilShadow.primaryLift,
        ),
        child: InkWell(
          borderRadius: VigilRadius.featureRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("New Quote", style: VigilType.title(color: VigilColors.surface, size: 19)),
                      const SizedBox(height: 4),
                      Text(
                        "Build a quote step by step",
                        style: VigilType.small(
                          color: Colors.white.withValues(alpha: 0.70),
                          size: 12,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: VigilRadius.cardRadius,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TapCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VigilIconBox(icon: icon, color: VigilColors.textSecondary, background: VigilColors.canvas),
            const SizedBox(height: 10),
            Text(label, style: _bodyStyle(weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(subtitle, style: _smallStyle(color: VigilColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action, required this.onAction});

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: _bodyStyle(weight: FontWeight.w800)),
        ),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
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

class _TapCard extends StatelessWidget {
  const _TapCard({required this.child, required this.onTap, this.selected = false});

  final Widget child;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return VigilSurface(selected: selected, onTap: onTap, child: child);
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
