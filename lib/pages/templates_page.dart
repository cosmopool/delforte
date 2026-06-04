import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/empty_panel.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:flutter/material.dart";

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({required this.router, super.key});

  final AppRouterDelegate router;

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  bool _modalShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showUnavailableModal());
  }

  Future<void> _showUnavailableModal() async {
    if (!mounted || _modalShown) return;
    _modalShown = true;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.pageUnavailable),
          content: Text(strings.templatesDisabledMessage),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.ok)),
          ],
        );
      },
    );
    if (mounted) widget.router.goTo(const HomeRoute());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: VigilGradients.appBackdrop),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ClipRRect(
                borderRadius: VigilRadius.appFrameRadius,
                child: ColoredBox(color: VigilColors.canvas, child: _buildBody()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        FlowHeader(title: strings.templates, onBack: () => widget.router.goTo(const HomeRoute())),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyPanel(
              icon: Icons.block_rounded,
              title: strings.pageUnavailable,
              subtitle: strings.templatesEmptySubtitle,
            ),
          ),
        ),
      ],
    );
  }
}
