import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/search_field_widget.dart";
import "package:delforte/design_system/widgets/template_card_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store.dart";
import "package:flutter/material.dart";

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({required this.store, required this.router, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<QuoteTemplate> _templates = const [
    QuoteTemplate(
      name: "CCTV Basic",
      description: "4 cameras, one DVR, and installation labor",
      icon: Icons.videocam_rounded,
      itemNames: ["IP Camera 4MP"],
      serviceNames: ["CCTV Installation"],
    ),
    QuoteTemplate(
      name: "Gate + Motor",
      description: "Motor kit, control panel, and gate installation",
      icon: Icons.garage_rounded,
      itemNames: ["Gate Motor Kit", "Control Panel Pro"],
      serviceNames: ["Gate Motor Install"],
    ),
    QuoteTemplate(
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
    final List<QuoteTemplate> filtered = [
      for (final QuoteTemplate template in _templates)
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

  Widget _buildBody(List<QuoteTemplate> filtered) {
    return Column(
      children: [
        FlowHeader(title: "Templates", onBack: () => widget.router.goTo(const HomeRoute())),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SearchField(
                controller: _searchController,
                hintText: "Search templates...",
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              for (final QuoteTemplate template in filtered)
                TemplateCard(template: template, onUse: () => _useTemplate(template)),
            ],
          ),
        ),
      ],
    );
  }

  void _useTemplate(QuoteTemplate template) {
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
