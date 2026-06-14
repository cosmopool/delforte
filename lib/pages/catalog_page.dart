import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/destructive_icon_button.dart";
import "package:delforte/design_system/widgets/empty_panel.dart";
import "package:delforte/design_system/widgets/form_field_widget.dart";
import "package:delforte/design_system/widgets/manager_header_widget.dart";
import "package:delforte/design_system/widgets/search_field_widget.dart";
import "package:delforte/design_system/widgets/unit_dropdown_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

/// Catalog manager: browse, search, edit and delete saved services and
/// equipment. Editing happens inline in expandable cards (see the JSX
/// `CatalogScreen`). The "New" button opens the matching create page.
class CatalogPage extends StatefulWidget {
  const CatalogPage({required this.store, required this.router, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _search = TextEditingController();
  CatalogItemType _tab = CatalogItemType.service;
  int? _expandedId;

  bool get _isServices => _tab == CatalogItemType.service;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _switchTab(CatalogItemType tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _expandedId = null;
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            _CatalogHeader(
              tab: _tab,
              onBack: () => widget.router.goTo(const HomeRoute()),
              onTab: _switchTab,
              onNew: () => widget.router.goTo(
                _isServices ? const ServiceCreateRoute() : const EquipmentCreateRoute(),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  widget.store.servicesNotifier,
                  widget.store.equipmentNotifier,
                ]),
                builder: (BuildContext context, Widget? _) {
                  final List<CatalogItem> items = widget.store.searchCatalog(
                    _tab,
                    _search.text.trim(),
                  );
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SearchField(
                        controller: _search,
                        hintText: strings.search,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      if (items.isEmpty)
                        EmptyPanel(
                          icon: _isServices
                              ? Icons.build_circle_rounded
                              : Icons.inventory_2_rounded,
                          title: _isServices ? strings.noServicesYet : strings.noEquipmentYet,
                          subtitle: strings.catalogEmptySubtitle,
                        )
                      else
                        for (final CatalogItem item in items)
                          _CatalogEditCard(
                            key: ValueKey("${_tab.index}-${item.id}"),
                            store: widget.store,
                            type: _tab,
                            item: item,
                            expanded: _expandedId == item.id,
                            onToggle: () => setState(() {
                              _expandedId = _expandedId == item.id ? null : item.id;
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

/// Navy header: back + title + "New" button, with a Services/Equipment tab
/// switcher beneath.
class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({
    required this.tab,
    required this.onBack,
    required this.onTab,
    required this.onNew,
  });

  final CatalogItemType tab;
  final VoidCallback onBack;
  final ValueChanged<CatalogItemType> onTab;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return ManagerHeader(
      title: strings.catalog,
      actionLabel: strings.catalogNew,
      onBack: onBack,
      onAction: onNew,
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _tabButton(CatalogItemType.service, strings.services),
              _tabButton(CatalogItemType.equipment, strings.equipment),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(CatalogItemType value, String label) {
    final bool selected = value == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTab(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? VigilColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: VigilType.body(
              color: selected ? VigilColors.textPrimary : Colors.white.withValues(alpha: 0.45),
              size: 13,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// An expandable catalog row whose body edits the item in place.
class _CatalogEditCard extends StatefulWidget {
  const _CatalogEditCard({
    required this.store,
    required this.type,
    required this.item,
    required this.expanded,
    required this.onToggle,
    required this.onDeleted,
    super.key,
  });

  final QuoteStore store;
  final CatalogItemType type;
  final CatalogItem item;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onDeleted;

  @override
  State<_CatalogEditCard> createState() => _CatalogEditCardState();
}

class _CatalogEditCardState extends State<_CatalogEditCard> {
  late final TextEditingController _name = TextEditingController(text: widget.item.name);
  late final TextEditingController _description = TextEditingController(
    text: widget.item.description,
  );
  late final TextEditingController _price = TextEditingController(
    text: formatMoney(widget.item.priceCents),
  );
  late int _unitId = widget.item.unitId;

  bool get _isServices => widget.type == CatalogItemType.service;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CatalogItem item = widget.item;
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
                  VigilIconBox(
                    icon: catalogItemIcon(
                      item.name,
                      fallback: _isServices ? Icons.handyman_rounded : Icons.inventory_2_rounded,
                    ),
                    color: widget.expanded ? VigilColors.primary : VigilColors.textMuted,
                    background: VigilColors.canvas,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: VigilType.body(
                            color: VigilColors.textPrimary,
                            size: 14,
                            weight: FontWeight.w700,
                          ),
                        ),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.description,
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
                  const SizedBox(width: 8),
                  if (!widget.expanded)
                    Text(
                      formatMoney(item.priceCents),
                      style: VigilType.small(
                        color: VigilColors.textSecondary,
                        size: 11,
                        weight: FontWeight.w700,
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
                      FormFieldWidget(
                        controller: _name,
                        label: _isServices ? strings.serviceName : strings.equipmentName,
                      ),
                      const SizedBox(height: 12),
                      FormFieldWidget(
                        controller: _description,
                        label: strings.description,
                        minLines: 2,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FormFieldWidget(
                              controller: _price,
                              onChanged: _formatPrice,
                              label: _isServices ? strings.defaultPrice : strings.unitPrice,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: UnitDropdownWidget(
                              store: widget.store,
                              label: strings.unit,
                              selectedUnitId: _unitId,
                              onChanged: (value) => setState(() => _unitId = value ?? 0),
                            ),
                          ),
                        ],
                      ),
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

  void _formatPrice(String text) {
    final String decimal = formatMoney(moneyStringToCents(text));
    _price.value = TextEditingValue(
      text: decimal,
      selection: TextSelection.collapsed(offset: decimal.length),
    );
  }

  void _save() {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      _showSnack(_isServices ? strings.serviceNameRequired : strings.equipmentNameRequired);
      return;
    }
    final int cents = moneyStringToCents(_price.text);
    final String description = _description.text.trim();
    final bool saved = _isServices
        ? widget.store.updateService(widget.item.id, name, description, cents, _unitId)
        : widget.store.updateEquipment(widget.item.id, name, description, cents, _unitId);
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
        content: Text(strings.deleteCatalogItemConfirm(widget.item.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.delete)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final bool deleted = _isServices
        ? widget.store.deleteService(widget.item.id)
        : widget.store.deleteEquipment(widget.item.id);
    if (!deleted) {
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
