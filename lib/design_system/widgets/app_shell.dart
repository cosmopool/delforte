import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A reusable shell widget that wraps page content with the standard
/// Delforte app frame: gradient backdrop, centered max-width frame,
/// rounded corners, and an optional header area that sits above the
/// clipped content so it is never clipped by the top rounded corners.
class AppShell extends StatelessWidget {
  /// Creates an app shell.
  ///
  /// [body] is the main scrollable or expandable content.
  /// [header] is an optional widget (e.g. [FlowHeader] or [_BrandHeader])
  /// that appears at the top of the frame.
  const AppShell({required this.body, this.header, super.key});

  /// Optional header widget rendered above the clipped content area.
  final Widget? header;

  /// The main page content.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: VigilGradients.appBackdrop),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  if (header != null)
                    ColoredBox(
                      color: VigilColors.ink,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: double.infinity, height: VigilRadius.appFrame),
                          header!,
                        ],
                      ),
                    ),
                  Expanded(
                    child: ColoredBox(color: VigilColors.canvas, child: body),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
