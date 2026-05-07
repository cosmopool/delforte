import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/empty_panel.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/quote_card_widget.dart";
import "package:delforte/design_system/widgets/search_field_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
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
        FlowHeader(title: "Quotes", onBack: () => widget.router.goTo(const HomeRoute())),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SearchField(
                controller: _searchController,
                hintText: "Search quotes...",
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              if (indexes.isEmpty)
                const EmptyPanel(
                  icon: Icons.receipt_long_rounded,
                  title: "No quotes found",
                  subtitle: "Saved quotes will appear here.",
                )
              else
                for (final int index in indexes)
                  QuoteCard(
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
