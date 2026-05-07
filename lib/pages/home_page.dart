import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/empty_panel.dart";
import "package:delforte/design_system/widgets/quote_card_widget.dart";
import "package:delforte/design_system/widgets/tap_card_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
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
        return AppShell(
          body: Column(
            children: [
              _BrandHeader(
                onSettings: () => router.goTo(const SettingsRoute()),
              ),
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
                      child: _ActionTile(
                        label: "Continue",
                        subtitle: "Resume a draft",
                        icon: Icons.edit_note_rounded,
                        onTap: () => router.goTo(
                          QuoteFlowRoute(
                            QuoteStep.client,
                            selectedClientId: store.draft.clientId == 0
                                ? null
                                : store.draft.clientId,
                          ),
                        ),
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
                      const EmptyPanel(
                        icon: Icons.receipt_long_rounded,
                        title: "No saved quotes yet",
                        subtitle: "Create a quote and save it from the review flow.",
                      )
                    else
                      for (var i = 0; i < store.quotes.count && i < 3; i++)
                        QuoteCard(
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
          ),
        );
      },
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
  const _BrandHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VigilColors.ink,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Delforte",
              style: TextStyle(
                color: VigilColors.surface,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
            IconButton(
              onPressed: onSettings,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.07),
                foregroundColor: Colors.white.withValues(alpha: 0.60),
                fixedSize: const Size(36, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              icon: const Icon(Icons.settings_rounded, size: 18),
            ),
          ],
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
    return ClipRRect(
      borderRadius: VigilRadius.featureRadius,
      child: Material(
        color: Colors.transparent,
        borderRadius: VigilRadius.featureRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: VigilGradients.primaryAction,
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
                        Text(
                          "New Quote",
                          style: VigilType.title(color: VigilColors.surface, size: 19),
                        ),
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
    const Color color = VigilColors.textMuted;
    const FontWeight weight = FontWeight.w700;
    return TapCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VigilIconBox(
              icon: icon,
              color: VigilColors.textSecondary,
              background: VigilColors.canvas,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: VigilType.body(color: VigilColors.textPrimary, size: 14, weight: weight),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: VigilType.small(color: color, size: 11, weight: FontWeight.w600),
            ),
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
    const FontWeight weight = FontWeight.w800;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: VigilType.body(color: VigilColors.textPrimary, size: 14, weight: weight),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
    );
  }
}
