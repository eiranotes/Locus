import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_surface.dart';

enum PixelButtonTone { primary, secondary, quiet, danger }

class PixelButton extends StatefulWidget {
  const PixelButton({
    required this.label,
    required this.onPressed,
    this.actionAsset,
    this.assetPath,
    this.fallbackIcon,
    this.tone = PixelButtonTone.primary,
    this.expand = false,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? actionAsset;
  final String? assetPath;
  final IconData? fallbackIcon;
  final PixelButtonTone tone;
  final bool expand;
  final bool compact;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final colors = switch (widget.tone) {
      PixelButtonTone.primary => (
        background: PixelPalette.action,
        foreground: PixelPalette.actionInk,
        border: PixelPalette.textStrong,
      ),
      PixelButtonTone.secondary => (
        background: PixelPalette.raised,
        foreground: PixelPalette.textStrong,
        border: PixelPalette.action,
      ),
      PixelButtonTone.quiet => (
        background: PixelPalette.panel,
        foreground: PixelPalette.textStrong,
        border: PixelPalette.divider,
      ),
      PixelButtonTone.danger => (
        background: PixelPalette.panel,
        foreground: PixelPalette.danger,
        border: PixelPalette.danger,
      ),
    };
    final shape = PixelCutBorder(color: colors.border, width: 2, cut: 6);
    final content = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 48,
        minWidth: widget.compact ? 48 : 72,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 10 : 14,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (widget.actionAsset != null ||
                widget.assetPath != null ||
                widget.fallbackIcon != null) ...[
              _PixelActionIcon(
                name: widget.actionAsset,
                assetPath: widget.assetPath,
                fallback: widget.fallbackIcon,
                color: colors.foreground,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.38,
      duration: const Duration(milliseconds: 80),
      child: Transform.translate(
        offset: Offset(0, _pressed && enabled ? 2 : 0),
        child: Material(
          color: colors.background,
          shape: shape,
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: widget.onPressed,
            customBorder: shape,
            splashColor: colors.foreground.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            onHighlightChanged: enabled
                ? (bool value) => setState(() => _pressed = value)
                : null,
            child: widget.expand
                ? SizedBox(width: double.infinity, child: content)
                : content,
          ),
        ),
      ),
    );
  }
}

class _PixelActionIcon extends StatelessWidget {
  const _PixelActionIcon({
    required this.name,
    required this.fallback,
    required this.color,
    required this.assetPath,
  });

  final String? name;
  final IconData? fallback;
  final Color color;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final fallbackWidget = Icon(
      fallback ?? Icons.square,
      color: color,
      size: 20,
    );
    final path =
        assetPath ?? (name == null ? null : GeneratedArtPaths.action(name!));
    if (path == null) return fallbackWidget;
    return SizedBox(
      width: 24,
      height: 24,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => fallbackWidget,
      ),
    );
  }
}
