import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/add_card_widget.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/initials_avatar_widget.dart";
import "package:delforte/design_system/widgets/search_field_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class ClientSelectPage extends StatefulWidget {
  const ClientSelectPage({required this.store, required this.router, this.draftId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int? draftId;

  @override
  State<ClientSelectPage> createState() => _ClientSelectPageState();
}

class _ClientSelectPageState extends State<ClientSelectPage> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedClientId;

  @override
  void initState() {
    super.initState();
    final int? draftId = widget.draftId;
    if (draftId != null) {
      final int clientId = widget.store.draftClientId(draftId);
      if (clientId != 0) _selectedClientId = clientId;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Client> clients = widget.store.searchClients(_searchController.text);
    return AppShell(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            FlowHeader(
              title: strings.selectClient,
              stepIndex: 0,
              onBack: _goBack,
              onContinue: _selectedClientId == null ? null : _continue,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SearchField(
                    controller: _searchController,
                    hintText: strings.searchClients,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  for (final Client client in clients) _clientCard(client),
                  AddCard(
                    label: strings.addNewClient,
                    onTap: () => widget.router.goTo(ClientCreateRoute(draftId: widget.draftId)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    final int? draftId = widget.draftId;
    if (draftId != null) widget.store.deleteDraftIfEmpty(draftId);
    widget.router.goTo(const HomeRoute());
  }

  void _continue() {
    final int clientId = _selectedClientId!;
    final int? existing = widget.draftId;
    final int draftId = existing ?? widget.store.createDraft(clientId);
    if (draftId == 0) {
      _showSnack(widget.store.latestErrorMessage());
      return;
    }
    if (existing != null) widget.store.setDraftClient(existing, clientId);
    widget.router.goTo(QuoteFlowRoute(QuoteStep.services, draftId: draftId));
  }

  void _showSnack(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _clientCard(Client client) {
    final int id = client.id;
    final bool selected = _selectedClientId == id;
    final String name = client.name;
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
                          client.address,
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
