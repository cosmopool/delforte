import "package:delforte/design_system.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store.dart";
import "package:flutter/material.dart";

class ItemsPage extends StatefulWidget {
  const ItemsPage({required this.store, required this.router, this.selectedClientId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int? selectedClientId;

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final TextEditingController _searchController = TextEditingController();
  int? _expandedId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<int> indexes = [
      for (var i = 0; i < widget.store.items.count; i++)
        if (query.isEmpty ||
            widget.store.items.nameAt(i).toLowerCase().contains(query) ||
            widget.store.items.descriptionAt(i).toLowerCase().contains(query))
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
        _FlowHeader(
          title: "Equipment",
          stepIndex: 2,
          total: _draftTotalFor(quoteLineItem),
          totalLabel: "Equipment Total",
          onBack: () => widget.router.goTo(
            QuoteFlowRoute(QuoteStep.services, selectedClientId: widget.selectedClientId),
          ),
          onContinue: () => widget.router.goTo(
            QuoteFlowRoute(QuoteStep.review, selectedClientId: widget.selectedClientId),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchField(
                controller: _searchController,
                hintText: "Search to add equipment...",
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              for (final int index in indexes)
                _CatalogCard(
                  name: widget.store.items.nameAt(index),
                  description: widget.store.items.descriptionAt(index),
                  price: _formatMoney(widget.store.items.priceCentsAt(index)),
                  icon: _catalogIcon(widget.store.items.nameAt(index)),
                  expanded: _expandedId == widget.store.items.idAt(index),
                  selectedQuantity: _draftQuantity(widget.store.items.idAt(index)),
                  onToggle: () => setState(() {
                    final int id = widget.store.items.idAt(index);
                    _expandedId = _expandedId == id ? null : id;
                  }),
                  onAdd: () => _addDraftLine(widget.store.items.idAt(index)),
                  onDecrease: () => _changeDraftQuantity(widget.store.items.idAt(index), -1),
                  onIncrease: () => _changeDraftQuantity(widget.store.items.idAt(index), 1),
                  onRemove: () => _removeDraftLine(widget.store.items.idAt(index)),
                ),
              _AddCard(label: "Add new equipment", onTap: _showCatalogDialog),
            ],
          ),
        ),
      ],
    );
  }

  int _draftQuantity(int refId) {
    final int index = widget.store.draft.lineIndex(quoteLineItem, refId);
    return index < 0 ? 0 : widget.store.draft.quantities[index];
  }

  int _draftTotalFor(int type) {
    var total = 0;
    for (var i = 0; i < widget.store.draft.count; i++) {
      if (widget.store.draft.types[i] == type) total += widget.store.draft.subtotalCents[i];
    }
    return total;
  }

  void _addDraftLine(int refId) {
    final bool ok = widget.store.addDraftLine(quoteLineItem, refId, 1);
    if (!ok) _showSnack(widget.store.latestErrorMessage());
  }

  void _changeDraftQuantity(int refId, int delta) {
    final int index = widget.store.draft.lineIndex(quoteLineItem, refId);
    if (index < 0) {
      if (delta > 0) _addDraftLine(refId);
      return;
    }
    final bool ok = widget.store.changeDraftQuantity(index, delta);
    if (!ok) _showSnack(widget.store.latestErrorMessage());
  }

  void _removeDraftLine(int refId) {
    final int index = widget.store.draft.lineIndex(quoteLineItem, refId);
    if (index >= 0 && !widget.store.removeDraftLine(index)) {
      _showSnack(widget.store.latestErrorMessage());
    }
  }

  Future<void> _showCatalogDialog() async {
    final TextEditingController name = TextEditingController();
    final TextEditingController description = TextEditingController();
    final TextEditingController price = TextEditingController();
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Add Equipment"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(controller: name, label: "Name"),
                _DialogField(controller: description, label: "Description"),
                _DialogField(controller: price, label: "Price", keyboardType: TextInputType.number),
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
      final int cents = _parseMoneyCents(price.text);
      final bool ok = widget.store.addItem(name.text.trim(), description.text.trim(), cents);
      if (!ok) _showSnack(widget.store.latestErrorMessage());
    }
    name.dispose();
    description.dispose();
    price.dispose();
  }

  void _showSnack(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  IconData _catalogIcon(String name) {
    final String value = name.toLowerCase();
    if (value.contains("camera") || value.contains("cctv")) return Icons.videocam_rounded;
    if (value.contains("alarm")) return Icons.alarm_on_rounded;
    if (value.contains("gate") || value.contains("motor")) return Icons.garage_rounded;
    if (value.contains("panel")) return Icons.electrical_services_rounded;
    return Icons.inventory_2_rounded;
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

  int _parseMoneyCents(String value) {
    final String normalized = value.trim().replaceAll(".", "").replaceAll(",", ".");
    final double parsed = double.tryParse(normalized) ?? 0;
    if (parsed <= 0) return 0;
    return (parsed * 100).round();
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    this.stepIndex,
    this.total,
    this.totalLabel,
    this.onBack,
    this.onContinue,
    this.continueLabel = "Continue",
  });

  static const List<String> _steps = ["Client", "Services", "Items", "Review", "Send"];

  final String title;
  final int? stepIndex;
  final int? total;
  final String? totalLabel;
  final String continueLabel;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final int? current = stepIndex;
    return ColoredBox(
      color: VigilColors.ink,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Row(
              children: [
                if (onBack != null) ...[
                  _HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: "Back",
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(title, style: VigilType.title(color: VigilColors.surface, size: 19)),
                ),
                if (onContinue != null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: VigilColors.primary,
                      foregroundColor: VigilColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    ),
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(continueLabel),
                  ),
              ],
            ),
          ),
          if (current != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(right: i == _steps.length - 1 ? 0 : 5),
                            decoration: BoxDecoration(
                              color: i < current
                                  ? VigilColors.primary
                                  : i == current
                                  ? const Color(0xFF5499EE)
                                  : Colors.white.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(VigilRadius.chip),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        Text(
                          _steps[i],
                          style: VigilType.small(
                            color: i == current
                                ? Colors.white.withValues(alpha: 0.95)
                                : i < current
                                ? Colors.white.withValues(alpha: 0.50)
                                : Colors.white.withValues(alpha: 0.25),
                            size: 10,
                            weight: i == current ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (total != null && totalLabel != null)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              color: Colors.white.withValues(alpha: 0.06),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    totalLabel!,
                    style: VigilType.small(
                      color: Colors.white.withValues(alpha: 0.45),
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatMoney(total!),
                    style: VigilType.body(
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hintText, required this.onChanged});

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded, color: VigilColors.textMuted),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.expanded,
    required this.selectedQuantity,
    required this.onToggle,
    required this.onAdd,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final String name;
  final String description;
  final String price;
  final IconData icon;
  final bool expanded;
  final int selectedQuantity;
  final VoidCallback onToggle;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool selected = selectedQuantity > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _TapCard(
        selected: expanded || selected,
        onTap: onToggle,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  VigilIconBox(
                    icon: icon,
                    color: expanded || selected ? VigilColors.primary : VigilColors.textMuted,
                    background: expanded || selected ? VigilColors.primarySoft : VigilColors.canvas,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: _bodyStyle(weight: FontWeight.w700)),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _smallStyle(color: VigilColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!expanded)
                    Text(
                      selected ? "$selectedQuantity x $price" : price,
                      style: _smallStyle(color: VigilColors.textSecondary, weight: FontWeight.w700),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: VigilColors.textMuted,
                  ),
                ],
              ),
            ),
            if (expanded)
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: VigilColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 11, 15, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FieldSummary(label: "Unit Price", value: price),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FieldSummary(label: "Qty", value: selectedQuantity.toString()),
                      ),
                      const SizedBox(width: 8),
                      if (selected)
                        Row(
                          children: [
                            _RoundButton(icon: Icons.remove_rounded, onPressed: onDecrease),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "$selectedQuantity",
                                style: _bodyStyle(weight: FontWeight.w800),
                              ),
                            ),
                            _RoundButton(icon: Icons.add_rounded, onPressed: onIncrease),
                            IconButton(
                              tooltip: "Remove",
                              onPressed: onRemove,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: VigilColors.textMuted,
                              ),
                            ),
                          ],
                        )
                      else
                        FilledButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text("Add"),
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
}

class _FieldSummary extends StatelessWidget {
  const _FieldSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VigilColors.canvas,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: _smallStyle(color: VigilColors.textMuted, size: 10)),
            const SizedBox(height: 4),
            Text(
              value,
              style: _smallStyle(color: VigilColors.textPrimary, weight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return VigilSurface(
      background: VigilColors.canvas,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          VigilIconBox(
            icon: Icons.add_rounded,
            color: VigilColors.textMuted,
            background: VigilColors.border,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: _bodyStyle(color: VigilColors.textSecondary, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TapCard extends StatelessWidget {
  const _TapCard({required this.child, required this.onTap, this.selected = false});

  final Widget child;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return VigilSurface(selected: selected, onTap: onTap, child: child);
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        foregroundColor: Colors.white.withValues(alpha: 0.80),
        fixedSize: const Size(34, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      icon: Icon(icon, size: 17),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: icon == Icons.add_rounded ? "Increase" : "Decrease",
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({required this.controller, required this.label, this.keyboardType});

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}

TextStyle _bodyStyle({
  Color color = VigilColors.textPrimary,
  FontWeight weight = FontWeight.w600,
  double size = 14,
}) {
  return VigilType.body(color: color, size: size, weight: weight);
}

TextStyle _smallStyle({
  Color color = VigilColors.textMuted,
  FontWeight weight = FontWeight.w600,
  double size = 11,
}) {
  return VigilType.small(color: color, size: size, weight: weight);
}
