import "package:delforte/design_system/colors.dart";
import "package:delforte/design_system/radius.dart";
import "package:delforte/design_system/stroke.dart";
import "package:flutter/material.dart";

class VigilSurface extends StatelessWidget {
  const VigilSurface({
    required this.child,
    super.key,
    this.selected = false,
    this.padding,
    this.onTap,
    this.radius,
    this.background,
  });

  final Widget child;
  final bool selected;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BorderRadius? radius;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final BorderRadius resolvedRadius = radius ?? VigilRadius.cardRadius;
    final Color resolvedBackground =
        background ?? (selected ? VigilColors.primarySoft : VigilColors.surface);
    final BorderSide side = selected ? VigilStroke.primary : VigilStroke.subtle;
    final Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedBackground,
        border: Border.all(color: side.color, width: side.width),
        borderRadius: resolvedRadius,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    if (onTap == null) return content;
    return Material(
      color: resolvedBackground,
      borderRadius: resolvedRadius,
      child: InkWell(borderRadius: resolvedRadius, onTap: onTap, child: content),
    );
  }
}
