import "dart:typed_data";

import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/primary_button_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/business_info_data.dart";
import "package:delforte/store/pdf_settings_data.dart";
import "package:delforte/store/quote_defaults_data.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";

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

  String _accentColour = "";
  Uint8List _logo = Uint8List(0);

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
    _logo = info.logo;

    final QuoteDefaultsData defaults = widget.store.quoteDefaults;
    _paymentMethod.text = defaults.paymentMethod;
    _validity.text = defaults.validity;
    _warranty.text = defaults.warranty;
    _terms.text = defaults.terms;

    final PdfSettingsData pdf = widget.store.pdfSettings;
    _accentColour = pdf.accentColour;
  }

  @override
  Widget build(BuildContext context) {
    _initFromStore();
    return AppShell(
      header: FlowHeader(
        title: strings.settings,
        onBack: () => widget.router.goTo(const HomeRoute()),
      ),
      body: AnimatedBuilder(
        animation: widget.store.settingsNotifier,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _SectionLabel(label: strings.sectionBusiness),
              _SettingsCard(
                children: [
                  _LogoRow(logo: _logo, onUpload: _pickLogo),
                  _FieldRow(
                    icon: Icons.storefront_rounded,
                    label: strings.businessName,
                    controller: _businessName,
                    hint: strings.businessNameHint,
                  ),
                  _FieldRow(
                    icon: Icons.badge_rounded,
                    label: strings.cnpj,
                    controller: _cnpj,
                    hint: strings.cnpjHint,
                  ),
                  _FieldRow(
                    icon: Icons.location_on_rounded,
                    label: strings.address,
                    controller: _address,
                    hint: strings.addressHint,
                  ),
                  _FieldRow(
                    icon: Icons.location_city_rounded,
                    label: strings.cityState,
                    controller: _city,
                    hint: strings.cityStateHint,
                  ),
                  _FieldRow(
                    icon: Icons.phone_rounded,
                    label: strings.phone,
                    controller: _phone,
                    hint: strings.businessPhoneHint,
                    keyboardType: TextInputType.phone,
                  ),
                  _FieldRow(
                    icon: Icons.mail_outline_rounded,
                    label: strings.email,
                    controller: _email,
                    hint: strings.businessEmailHint,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionLabel(label: strings.sectionQuoteDefaults),
              _SettingsCard(
                children: [
                  _FieldRow(
                    icon: Icons.event_available_rounded,
                    label: strings.quoteValidity,
                    controller: _validity,
                    hint: strings.quoteValidityHint,
                  ),
                  _FieldRow(
                    icon: Icons.payments_rounded,
                    label: strings.paymentMethod,
                    controller: _paymentMethod,
                    hint: strings.paymentMethodHint,
                    minLines: 2,
                    maxLines: 4,
                  ),
                  _FieldRow(
                    icon: Icons.verified_user_rounded,
                    label: strings.warranty,
                    controller: _warranty,
                    hint: strings.warrantyHint,
                    minLines: 2,
                    maxLines: 4,
                  ),
                  _FieldRow(
                    icon: Icons.gavel_rounded,
                    label: strings.termsConditions,
                    controller: _terms,
                    hint: strings.termsHint,
                    minLines: 2,
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionLabel(label: strings.sectionPdfFooterPreview),
              _FooterPreview(store: widget.store),
              const SizedBox(height: 7),
              Text(
                strings.footerPreviewNote,
                textAlign: TextAlign.center,
                style: VigilType.small(color: VigilColors.textMuted, size: 11),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: strings.saveSettings,
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
      _logo,
    );
    widget.store.saveQuoteDefaults(
      _paymentMethod.text.trim(),
      _validity.text.trim(),
      _warranty.text.trim(),
      _terms.text.trim(),
    );
    widget.store.savePdfSettings(_accentColour.trim());
    widget.router.goTo(const HomeRoute());
  }

  Future<void> _pickLogo() async {
    final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _logo = bytes);
  }
}

/// Left-aligned uppercase label that introduces a settings card.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
      child: Text(
        label.toUpperCase(),
        style: VigilType.small(
          color: VigilColors.textMuted,
          weight: FontWeight.w700,
          size: 11,
        ).copyWith(letterSpacing: 0.7),
      ),
    );
  }
}

/// Rounded, bordered container that stacks rows separated by hairline dividers.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(const Divider(height: 1, thickness: 1, color: VigilColors.border));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: VigilColors.surface,
        borderRadius: VigilRadius.cardRadius,
        border: Border.all(color: VigilColors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }
}

/// A row with a leading icon, an uppercase caption, and an inline text field.
class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.icon,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final bool multiline = (maxLines ?? 1) > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: multiline ? 2 : 0),
            child: Icon(icon, size: 17, color: VigilColors.textMuted),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RowCaption(label: label),
                const SizedBox(height: 3),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  minLines: minLines,
                  maxLines: maxLines,
                  style: VigilType.body(
                    color: VigilColors.textPrimary,
                    weight: FontWeight.w500,
                    size: 14,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: VigilType.body(
                      color: VigilColors.textMuted,
                      weight: FontWeight.w400,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase caption shown above an inline field or selector value.
class _RowCaption extends StatelessWidget {
  const _RowCaption({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: VigilType.small(
        color: VigilColors.textMuted,
        weight: FontWeight.w700,
        size: 10,
      ).copyWith(letterSpacing: 0.5),
    );
  }
}

/// First row inside the Business card: company logo avatar + upload action.
class _LogoRow extends StatelessWidget {
  const _LogoRow({required this.logo, required this.onUpload});

  final Uint8List logo;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: VigilColors.inkElevated,
              borderRadius: BorderRadius.circular(13),
            ),
            child: logo.isEmpty
                ? Icon(Icons.business_rounded, size: 22, color: Colors.white.withValues(alpha: 0.4))
                : Image.memory(logo, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.companyLogo,
                  style: VigilType.body(color: VigilColors.textPrimary, size: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.companyLogoNote,
                  style: VigilType.small(color: VigilColors.textMuted, size: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUpload,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              strings.change,
              style: VigilType.body(color: VigilColors.primary, size: 12, weight: FontWeight.w600),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1.5),
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
                          info.name,
                          style: VigilType.title(color: VigilColors.surface, size: 13),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          strings.cnpjLabel(info.cnpj),
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
              Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
              const SizedBox(height: 12),
              _FooterGrid(
                items: [
                  (Icons.location_on_rounded, "${info.address} — ${info.state}"),
                  (Icons.phone_rounded, info.phone),
                  (Icons.mail_outline_rounded, info.email),
                  (Icons.payments_rounded, defaults.paymentMethod),
                  (Icons.verified_user_rounded, defaults.warranty),
                  (Icons.event_available_rounded, defaults.validity),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
              const SizedBox(height: 10),
              Text(
                defaults.terms,
                style: VigilType.small(color: Colors.white.withValues(alpha: 0.25), size: 9),
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
                  child: Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.28)),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    text,
                    style: VigilType.small(color: Colors.white.withValues(alpha: 0.42), size: 10),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
