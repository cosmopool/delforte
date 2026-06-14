import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/destructive_icon_button.dart";
import "package:delforte/design_system/widgets/empty_panel.dart";
import "package:delforte/design_system/widgets/form_field_widget.dart";
import "package:delforte/design_system/widgets/initials_avatar_widget.dart";
import "package:delforte/design_system/widgets/manager_header_widget.dart";
import "package:delforte/design_system/widgets/search_field_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

/// Clients manager: browse, search, edit and delete saved clients. Editing
/// happens inline in expandable cards (modelled on `CatalogPage`). The "New"
/// button opens the client create page, returning here.
class ClientsPage extends StatefulWidget {
  const ClientsPage({required this.store, required this.router, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final TextEditingController _search = TextEditingController();
  int? _expandedId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            ManagerHeader(
              title: strings.clients,
              actionLabel: strings.catalogNew,
              onBack: () => widget.router.goTo(const HomeRoute()),
              onAction: () => widget.router.goTo(const ClientCreateRoute(back: ClientsRoute())),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.store.clientsNotifier,
                builder: (BuildContext context, Widget? _) {
                  final List<Client> clients = widget.store.searchClients(_search.text.trim());
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SearchField(
                        controller: _search,
                        hintText: strings.search,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      if (clients.isEmpty)
                        EmptyPanel(
                          icon: Icons.people_alt_rounded,
                          title: strings.noClientsYet,
                          subtitle: strings.clientsEmptySubtitle,
                        )
                      else
                        for (final Client client in clients)
                          _ClientEditCard(
                            key: ValueKey(client.id),
                            store: widget.store,
                            client: client,
                            expanded: _expandedId == client.id,
                            onToggle: () => setState(() {
                              _expandedId = _expandedId == client.id ? null : client.id;
                            }),
                            onDeleted: () => setState(() => _expandedId = null),
                          ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An expandable client row whose body edits the client in place.
class _ClientEditCard extends StatefulWidget {
  const _ClientEditCard({
    required this.store,
    required this.client,
    required this.expanded,
    required this.onToggle,
    required this.onDeleted,
    super.key,
  });

  final QuoteStore store;
  final Client client;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onDeleted;

  @override
  State<_ClientEditCard> createState() => _ClientEditCardState();
}

class _ClientEditCardState extends State<_ClientEditCard> {
  late final TextEditingController _name = TextEditingController(text: widget.client.name);
  late final TextEditingController _phone = TextEditingController(text: widget.client.phone);
  late final TextEditingController _email = TextEditingController(text: widget.client.email);
  late final TextEditingController _address = TextEditingController(text: widget.client.address);
  late final TextEditingController _city = TextEditingController(text: widget.client.city);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Client client = widget.client;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: VigilSurface(
        selected: widget.expanded,
        onTap: widget.onToggle,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  InitialsAvatar(text: initials(client.name), selected: widget.expanded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: VigilType.body(
                            color: VigilColors.textPrimary,
                            size: 14,
                            weight: FontWeight.w700,
                          ),
                        ),
                        if (client.address.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            client.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VigilType.small(
                              color: VigilColors.textMuted,
                              size: 11,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    widget.expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: VigilColors.textMuted,
                  ),
                ],
              ),
            ),
            if (widget.expanded)
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: VigilColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
                  child: Column(
                    children: [
                      FormFieldWidget(controller: _name, label: strings.fullName),
                      const SizedBox(height: 12),
                      FormFieldWidget(
                        controller: _phone,
                        label: strings.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      FormFieldWidget(
                        controller: _email,
                        label: strings.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      FormFieldWidget(controller: _address, label: strings.address),
                      const SizedBox(height: 12),
                      FormFieldWidget(controller: _city, label: strings.city),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: VigilColors.primary,
                                foregroundColor: VigilColors.surface,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: VigilRadius.cardRadius),
                              ),
                              onPressed: _save,
                              child: Text(strings.saveChanges),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DestructiveIconButton(onPressed: _confirmDelete),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      _showSnack(strings.clientNameRequired);
      return;
    }
    final bool saved = widget.store.updateClient(
      widget.client.id,
      name,
      _phone.text.trim(),
      _email.text.trim(),
      _address.text.trim(),
      _city.text.trim(),
    );
    if (!saved) {
      _showSnack(widget.store.latestErrorMessage());
      return;
    }
    FocusScope.of(context).unfocus();
    _showSnack(strings.changesSaved);
    widget.onToggle();
  }

  Future<void> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.delete),
        content: Text(strings.deleteCatalogItemConfirm(widget.client.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.delete)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!widget.store.deleteClient(widget.client.id)) {
      _showSnack(widget.store.latestErrorMessage());
      return;
    }
    widget.onDeleted();
  }

  void _showSnack(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
