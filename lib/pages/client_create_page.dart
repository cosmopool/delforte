import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/form_field_widget.dart";
import "package:delforte/design_system/widgets/form_section_divider.dart";
import "package:delforte/design_system/widgets/primary_button_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";

class ClientCreatePage extends StatefulWidget {
  const ClientCreatePage({
    required this.store,
    required this.router,
    this.draftId,
    this.back,
    super.key,
  });

  final QuoteStore store;
  final AppRouterDelegate router;
  final int? draftId;

  /// Where to return after saving, when opened from the Clients manager.
  /// `null` returns to the quote-flow client step (the default flow).
  final AppRoute? back;

  @override
  State<ClientCreatePage> createState() => _ClientCreatePageState();
}

class _ClientCreatePageState extends State<ClientCreatePage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _city = TextEditingController();

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
    return AppShell(
      body: Column(
        children: [
          FlowHeader(
            title: strings.newClient,
            onBack: () => widget.router.goTo(
              widget.back ?? QuoteFlowRoute(QuoteStep.client, draftId: widget.draftId),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FormSectionDivider(label: strings.sectionContact),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _name,
                  label: strings.fullName,
                  hint: strings.fullNameHint,
                ),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _phone,
                  label: strings.phone,
                  hint: strings.phoneHint,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _email,
                  label: strings.email,
                  hint: strings.emailHint,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                FormSectionDivider(label: strings.sectionLocation),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _address,
                  label: strings.address,
                  hint: strings.addressHint,
                ),
                const SizedBox(height: 16),
                FormFieldWidget(controller: _city, label: strings.city, hint: strings.cityHint),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: strings.saveClient,
                  icon: Icons.check_rounded,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      _showSnack(strings.clientNameRequired);
      return;
    }
    final bool ok = widget.store.addClient(
      name,
      _phone.text.trim(),
      _email.text.trim(),
      _address.text.trim(),
      _city.text.trim(),
    );
    if (!ok) {
      _showSnack(widget.store.latestErrorMessage());
      return;
    }
    // From the Clients manager: just save and return to the list.
    final AppRoute? back = widget.back;
    if (back != null) {
      widget.router.goTo(back);
      return;
    }
    final int newId = widget.store.lastClientId();
    // Attach the new client to the draft (creating one lazily if needed) so the
    // client step returns with it preselected.
    final int? existing = widget.draftId;
    final int draftId = existing ?? widget.store.createDraft(newId);
    if (existing != null) widget.store.setDraftClient(existing, newId);
    widget.router.goTo(QuoteFlowRoute(QuoteStep.client, draftId: draftId == 0 ? null : draftId));
  }

  void _showSnack(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
