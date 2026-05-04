import "package:delforte/design_system.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store.dart";
import "package:flutter/material.dart";

class _QuoteTemplate {
  const _QuoteTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.itemNames,
    required this.serviceNames,
  });

  final String name;
  final String description;
  final IconData icon;
  final List<String> itemNames;
  final List<String> serviceNames;
}

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({required this.store, required this.router, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<_QuoteTemplate> _templates = const [
    _QuoteTemplate(
      name: "CCTV Basic",
      description: "4 cameras, one DVR, and installation labor",
      icon: Icons.videocam_rounded,
      itemNames: ["IP Camera 4MP"],
      serviceNames: ["CCTV Installation"],
    ),
    _QuoteTemplate(
      name: "Gate + Motor",
      description: "Motor kit, control panel, and gate installation",
      icon: Icons.garage_rounded,
      itemNames: ["Gate Motor Kit", "Control Panel Pro"],
      serviceNames: ["Gate Motor Install"],
    ),
    _QuoteTemplate(
      name: "Full Security",
      description: "Cameras, alarm setup, gate motor, and panel",
      icon: Icons.security_rounded,
      itemNames: ["IP Camera 4MP", "Gate Motor Kit", "Control Panel Pro"],
      serviceNames: ["CCTV Installation", "Alarm System Setup", "Gate Motor Install"],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<_QuoteTemplate> filtered = [
      for (final _QuoteTemplate template in _templates)
        if (query.isEmpty ||
            template.name.toLowerCase().contains(query) ||
            template.description.toLowerCase().contains(query))
          template,
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
                child: ColoredBox(color: VigilColors.canvas, child: _buildBody(filtered)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<_QuoteTemplate> filtered) {
    return Column(
      children: [
        _FlowHeader(title: "Templates", onBack: () => widget.router.goTo(const HomeRoute())),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchField(
                controller: _searchController,
                hintText: "Search templates...",
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              for (final _QuoteTemplate template in filtered)
                _TemplateCard(template: template, onUse: () => _useTemplate(template)),
            ],
          ),
        ),
      ],
    );
  }

  void _useTemplate(_QuoteTemplate template) {
    widget.store.clearDraft();
    for (final String name in template.serviceNames) {
      final int id = _catalogIdByName(widget.store.services, name);
      if (id > 0) widget.store.addDraftLine(quoteLineService, id, 1);
    }
    for (final String name in template.itemNames) {
      final int id = _catalogIdByName(widget.store.items, name);
      if (id > 0) widget.store.addDraftLine(quoteLineItem, id, name.contains("IP Camera") ? 4 : 1);
    }
    widget.router.goTo(const QuoteFlowRoute(QuoteStep.client));
  }

  int _catalogIdByName(ItemData data, String name) {
    for (var i = 0; i < data.count; i++) {
      if (data.nameAt(i) == name) return data.idAt(i);
    }
    return 0;
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    this.onBack,
    this.stepIndex,
    this.total,
    this.totalLabel,
    this.continueLabel = "Continue",
    this.onContinue,
  });

  final String title;
  final int? stepIndex;
  final int? total;
  final String? totalLabel;
  final String continueLabel;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VigilColors.ink,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(
          children: [
            if (onBack != null) ...[
              _HeaderIconButton(icon: Icons.arrow_back_rounded, tooltip: "Back", onPressed: onBack),
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
    );
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

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onUse});

  final _QuoteTemplate template;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _TapCard(
        onTap: onUse,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              VigilIconBox(
                icon: template.icon,
                color: VigilColors.primary,
                background: VigilColors.primarySoft,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name, style: _bodyStyle(weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      template.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _smallStyle(color: VigilColors.textMuted),
                    ),
                  ],
                ),
              ),
              FilledButton(onPressed: onUse, child: const Text("Use")),
            ],
          ),
        ),
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
