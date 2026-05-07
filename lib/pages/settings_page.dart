import "dart:typed_data";

import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/form_field_widget.dart";
import "package:delforte/design_system/widgets/form_section_divider.dart";
import "package:delforte/design_system/widgets/primary_button_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/business_info_data.dart";
import "package:delforte/store/pdf_settings_data.dart";
import "package:delforte/store/quote_defaults_data.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.store, required this.router, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _businessName = TextEditingController();
  final TextEditingController _cnpj = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _paymentMethod = TextEditingController();
  final TextEditingController _validity = TextEditingController();
  final TextEditingController _warranty = TextEditingController();
  final TextEditingController _terms = TextEditingController();
  final TextEditingController _accentColour = TextEditingController();

  bool _loaded = false;

  @override
  void dispose() {
    _businessName.dispose();
    _cnpj.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _phone.dispose();
    _email.dispose();
    _paymentMethod.dispose();
    _validity.dispose();
    _warranty.dispose();
    _terms.dispose();
    _accentColour.dispose();
    super.dispose();
  }

  void _initFromStore() {
    if (_loaded) return;
    _loaded = true;
    final BusinessInfoData info = widget.store.businessInfo;
    _businessName.text = info.name;
    _cnpj.text = info.cnpj;
    _address.text = info.address;
    _city.text = info.city;
    _state.text = info.state;
    _phone.text = info.phone;
    _email.text = info.email;

    final QuoteDefaultsData defaults = widget.store.quoteDefaults;
    _paymentMethod.text = defaults.paymentMethod;
    _validity.text = defaults.validity;
    _warranty.text = defaults.warranty;
    _terms.text = defaults.terms;

    final PdfSettingsData pdf = widget.store.pdfSettings;
    _accentColour.text = pdf.accentColour;
  }

  @override
  Widget build(BuildContext context) {
    _initFromStore();
    return AppShell(
      header: FlowHeader(
        title: "Settings",
        onBack: () => widget.router.goTo(const HomeRoute()),
      ),
      body: AnimatedBuilder(
        animation: widget.store.settingsNotifier,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _LogoPickerRow(),
              const SizedBox(height: 16),
              const FormSectionDivider(label: "Business"),
              const SizedBox(height: 16),
              FormFieldWidget(
                controller: _businessName,
                label: "Business Name",
                hint: "Your company name",
              ),
              const SizedBox(height: 16),
              FormFieldWidget(
                controller: _cnpj,
                label: "CNPJ",
                hint: "00.000.000/0000-00",
              ),
              const SizedBox(height: 16),
              FormFieldWidget(
                controller: _address,
                label: "Address",
                hint: "Street, number",
              ),
              const SizedBox(height: 16),
              FormFieldWidget(
                controller: _city,
                label: "City & State",
                hint: "City — State",
              ),
              const SizedBox(height: 16),
              FormFieldWidget(
                controller: _phone,
                label: "Phone",
                hint: "+55 (11) 00000-0000",
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              FormFieldWidget(
                controller: _email,
                label: "Email",
                hint: "contact@yourcompany.com",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              const FormSectionDivider(label: "Quote Defaults"),
              const SizedBox(height: 16),
              FormFieldWidget(
                controller: _paymentMethod,
                label: "Payment Method",
                hint: "e.g. Bank Transfer (PIX)",
              ),
              const SizedBox(height: 16),
              FormFieldWidget(
                controller: _validity,
                label: "Quote Validity",
                hint: "e.g. 30 days",
              ),
              const SizedBox(height: 16),
              FormFieldWidget(
                controller: _warranty,
                label: "Warranty",
                hint: "e.g. 90 days for parts & labour",
              ),
              const SizedBox(height: 16),
              FormFieldWidget(
                controller: _terms,
                label: "Terms & Conditions",
                hint: "Enter terms…",
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              const FormSectionDivider(label: "PDF Appearance"),
              const SizedBox(height: 16),
              FormFieldWidget(
                controller: _accentColour,
                label: "Accent Colour",
                hint: "e.g. Navy Blue (default)",
              ),
              const SizedBox(height: 24),
              const FormSectionDivider(label: "PDF Footer Preview"),
              const SizedBox(height: 16),
              _FooterPreview(store: widget.store),
              const SizedBox(height: 6),
              Text(
                "This footer appears at the bottom of every generated PDF",
                textAlign: TextAlign.center,
                style: VigilType.small(color: VigilColors.textMuted, size: 11),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: "Save Settings",
                icon: Icons.check_rounded,
                onPressed: _save,
              ),
            ],
          );
        },
      ),
    );
  }

  void _save() {
    widget.store.saveBusinessInfo(
      _businessName.text.trim(),
      _cnpj.text.trim(),
      _address.text.trim(),
      _city.text.trim(),
      _state.text.trim(),
      _phone.text.trim(),
      _email.text.trim(),
      Uint8List(0),
    );
    widget.store.saveQuoteDefaults(
      _paymentMethod.text.trim(),
      _validity.text.trim(),
      _warranty.text.trim(),
      _terms.text.trim(),
    );
    widget.store.savePdfSettings(_accentColour.text.trim());
    widget.router.goTo(const HomeRoute());
  }
}

class _LogoPickerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: VigilColors.inkElevated,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.business_rounded,
              size: 22,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Company Logo",
                  style: VigilType.body(color: VigilColors.textPrimary, size: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  "Shown on PDF header · PNG or SVG",
                  style: VigilType.small(color: VigilColors.textMuted, size: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              "Upload",
              style: VigilType.body(
                color: VigilColors.primary,
                size: 12,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterPreview extends StatelessWidget {
  const _FooterPreview({required this.store});

  final QuoteStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VigilColors.inkElevated,
        borderRadius: VigilRadius.cardRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: AnimatedBuilder(
        animation: store.settingsNotifier,
        builder: (context, _) {
          final BusinessInfoData info = store.businessInfo;
          final QuoteDefaultsData defaults = store.quoteDefaults;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.business_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.name.isNotEmpty ? info.name : "Delforte Sistemas",
                          style: VigilType.title(
                            color: VigilColors.surface,
                            size: 13,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          info.cnpj.isNotEmpty ? "CNPJ ${info.cnpj}" : "CNPJ 12.345.678/0001-90",
                          style: VigilType.small(
                            color: Colors.white.withValues(alpha: 0.35),
                            size: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 12),
              _FooterGrid(
                items: [
                  (
                    Icons.location_on_rounded,
                    "${info.address.isNotEmpty ? info.address : "Rua das Palmeiras, 200"} — ${info.state.isNotEmpty ? info.state : "SP"}",
                  ),
                  (
                    Icons.phone_rounded,
                    info.phone.isNotEmpty ? info.phone : "+55 (11) 98888-0000",
                  ),
                  (
                    Icons.mail_outline_rounded,
                    info.email.isNotEmpty ? info.email : "contato@delforte.com.br",
                  ),
                  (
                    Icons.payments_rounded,
                    defaults.paymentMethod.isNotEmpty
                        ? defaults.paymentMethod
                        : "PIX · Credit Card · Boleto",
                  ),
                  (
                    Icons.verified_user_rounded,
                    defaults.warranty.isNotEmpty ? defaults.warranty : "90-day warranty",
                  ),
                  (
                    Icons.event_available_rounded,
                    defaults.validity.isNotEmpty ? "Valid for ${defaults.validity}" : "Valid for 30 days",
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.07),
              ),
              const SizedBox(height: 10),
              Text(
                defaults.terms.isNotEmpty
                    ? defaults.terms
                    : "Services subject to prior site visit. Prices may vary after inspection.",
                style: VigilType.small(
                  color: Colors.white.withValues(alpha: 0.25),
                  size: 9,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FooterGrid extends StatelessWidget {
  const _FooterGrid({required this.items});

  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 7,
      children: [
        for (final (icon, text) in items)
          SizedBox(
            width: (MediaQuery.of(context).size.width - 68) / 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1.5),
                  child: Icon(
                    icon,
                    size: 11,
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    text,
                    style: VigilType.small(
                      color: Colors.white.withValues(alpha: 0.42),
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
