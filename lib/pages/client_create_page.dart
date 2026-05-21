import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/form_field_widget.dart";
import "package:delforte/design_system/widgets/form_section_divider.dart";
import "package:delforte/design_system/widgets/primary_button_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";

class ClientCreatePage extends StatefulWidget {
  const ClientCreatePage({
    required this.store,
    required this.router,
    this.selectedClientId,
    super.key,
  });

  final QuoteStore store;
  final AppRouterDelegate router;
  final int? selectedClientId;

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
            title: "New Client",
            onBack: () => widget.router.goTo(
              QuoteFlowRoute(QuoteStep.client, selectedClientId: widget.selectedClientId),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const FormSectionDivider(label: "Contact"),
                const SizedBox(height: 16),
                FormFieldWidget(controller: _name, label: "Full Name", hint: "e.g. João da Silva"),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _phone,
                  label: "Phone",
                  hint: "+55 (11) 99999-0000",
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _email,
                  label: "Email",
                  hint: "joao@email.com",
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                const FormSectionDivider(label: "Location"),
                const SizedBox(height: 16),
                FormFieldWidget(controller: _address, label: "Address", hint: "Street, number"),
                const SizedBox(height: 16),
                FormFieldWidget(controller: _city, label: "City", hint: "São Paulo"),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: "Save Client",
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
      _showSnack("Client name is required");
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
    final int newId = widget.store.clients.idAt(widget.store.clients.count - 1);
    widget.store.draft.clientId = newId;
    widget.router.goTo(QuoteFlowRoute(QuoteStep.client, selectedClientId: newId));
  }
}
