import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/add_card_widget.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/initials_avatar_widget.dart";
import "package:delforte/design_system/widgets/search_field_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class ClientSelectPage extends StatefulWidget {
  const ClientSelectPage({
    required this.store,
    required this.router,
    this.selectedClientId,
    super.key,
  });

  final QuoteStore store;
  final AppRouterDelegate router;
  final int? selectedClientId;

  @override
  State<ClientSelectPage> createState() => _ClientSelectPageState();
}

class _ClientSelectPageState extends State<ClientSelectPage> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedClientId;
  late final List<int> indexes = widget.store.clients.allClients();

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.selectedClientId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: Column(
        children: [
          FlowHeader(
            title: "Select Client",
            stepIndex: 0,
            onBack: () => widget.router.goTo(const HomeRoute()),
            onContinue: _selectedClientId == null
                ? null
                : () {
                    widget.store.draft.clientId = _selectedClientId!;
                    widget.router.goTo(
                      QuoteFlowRoute(QuoteStep.services, selectedClientId: _selectedClientId),
                    );
                  },
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SearchField(
                  controller: _searchController,
                  hintText: "Search clients...",
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                for (final int index in indexes) _clientCard(index),
                AddCard(
                  label: "Add new client",
                  onTap: () =>
                      widget.router.goTo(ClientCreateRoute(selectedClientId: _selectedClientId)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientCard(int index) {
    final int id = widget.store.clients.idAt(index);
    final bool selected = _selectedClientId == id;
    final String name = widget.store.clients.nameAt(index);
    const FontWeight weight = FontWeight.w700;
    const Color color = VigilColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? VigilColors.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _selectedClientId = id),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? VigilColors.primary : VigilColors.border,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  InitialsAvatar(text: initials(name), selected: selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: VigilType.body(
                            color: VigilColors.textPrimary,
                            size: 14,
                            weight: weight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.store.clients.addressAt(index),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VigilType.small(color: color, size: 11, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (selected) const Icon(Icons.check_circle_rounded, color: VigilColors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
