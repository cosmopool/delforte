import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/primary_button_widget.dart";
import "package:delforte/design_system/widgets/ready_card_widget.dart";
import "package:delforte/design_system/widgets/secondary_button_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class SendPage extends StatefulWidget {
  const SendPage({required this.store, required this.router, required this.draftId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int draftId;

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  @override
  Widget build(BuildContext context) {
    final int total = widget.store.quoteTotal(widget.draftId);
    final int serviceCount = widget.store.quoteLineCount(widget.draftId, .service);
    final int equipmentCount = widget.store.quoteLineCount(widget.draftId, .equipment);
    final Client? client = widget.store.clientById(widget.store.draftClientId(widget.draftId));
    final String clientName = client?.name ?? "Unknown client";

    return AppShell(
      body: Column(
        children: [
          FlowHeader(
            title: "Send Quote",
            stepIndex: 4,
            onBack: () =>
                widget.router.goTo(QuoteFlowRoute(QuoteStep.review, draftId: widget.draftId)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              children: [
                ReadyCard(
                  title: "Quote Ready",
                  subtitle: "Saved locally - $clientName - ${formatMoney(total)}",
                  chips: [
                    "$serviceCount services",
                    "$equipmentCount equipment",
                    formatMoney(total),
                  ],
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: "Share via WhatsApp",
                  icon: Icons.share_rounded,
                  onPressed: () => _showSnack(context, "Sharing is not wired yet."),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: "Export PDF",
                  icon: Icons.picture_as_pdf_rounded,
                  onPressed: () => _showSnack(context, "PDF export is not wired to the UI yet."),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: "Copy Link",
                  icon: Icons.link_rounded,
                  onPressed: () =>
                      _showSnack(context, "Link sharing is not available for local drafts."),
                ),
                TextButton(
                  onPressed: () => widget.router.goTo(const HomeRoute()),
                  child: const Text("Back to Home"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    if (message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
