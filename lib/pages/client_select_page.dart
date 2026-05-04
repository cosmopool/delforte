import "package:delforte/design_system.dart";
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
        _FlowHeader(
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
              _SearchField(
                controller: _searchController,
                hintText: "Search clients...",
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              for (final int index in indexes) _clientCard(index),
              _AddCard(label: "Add new client", onTap: _showClientDialog),
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
                  _InitialsAvatar(text: _initials(name), selected: selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: _bodyStyle(weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          widget.store.clients.addressAt(index),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _smallStyle(color: VigilColors.textMuted),
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
                _DialogField(controller: name, label: "Name"),
                _DialogField(controller: phone, label: "Phone"),
                _DialogField(controller: email, label: "Email"),
                _DialogField(controller: address, label: "Address"),
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

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    this.stepIndex,
    this.onBack,
    this.onContinue,
    this.continueLabel = "Continue",
    this.total,
    this.totalLabel,
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

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.text, required this.selected});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? VigilColors.primary : VigilColors.inkElevated,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: VigilType.small(color: VigilColors.surface, size: 13, weight: FontWeight.w900),
      ),
    );
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

class _DialogField extends StatelessWidget {
  const _DialogField({required this.controller, required this.label});

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
