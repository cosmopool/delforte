import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/add_card_widget.dart";
import "package:delforte/design_system/widgets/dialog_field_widget.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/initials_avatar_widget.dart";
import "package:delforte/design_system/widgets/search_field_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store.dart";
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
    final String query = _searchController.text.trim().toLowerCase();
    final List<int> indexes = [
      for (var i = 0; i < widget.store.clients.count; i++)
        if (query.isEmpty ||
            widget.store.clients.nameAt(i).toLowerCase().contains(query) ||
            widget.store.clients.addressAt(i).toLowerCase().contains(query))
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
        FlowHeader(
          title: "Select Client",
          stepIndex: 0,
          onBack: () => widget.router.goTo(const HomeRoute()),
          onContinue: _selectedClientId == null
              ? null
              : () => widget.router.goTo(
                  QuoteFlowRoute(QuoteStep.services, selectedClientId: _selectedClientId),
                ),
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
              AddCard(label: "Add new client", onTap: _showClientDialog),
            ],
          ),
        ),
      ],
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
                  InitialsAvatar(text: _initials(name), selected: selected),
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

  Future<void> _showClientDialog() async {
    final TextEditingController name = TextEditingController();
    final TextEditingController phone = TextEditingController();
    final TextEditingController email = TextEditingController();
    final TextEditingController address = TextEditingController();
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Add Client"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogField(controller: name, label: "Name"),
                DialogField(controller: phone, label: "Phone"),
                DialogField(controller: email, label: "Email"),
                DialogField(controller: address, label: "Address"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
    if (saved == true) {
      final bool ok = widget.store.addClient(
        name.text.trim(),
        phone.text.trim(),
        email.text.trim(),
        address.text.trim(),
      );
      if (ok) {
        setState(
          () => _selectedClientId = widget.store.clients.idAt(widget.store.clients.count - 1),
        );
      } else {
        _showSnack(widget.store.latestErrorMessage());
      }
    }
    name.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
  }

  void _showSnack(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
}
