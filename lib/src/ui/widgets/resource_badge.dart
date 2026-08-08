import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';

class ResourceBadge extends StatelessWidget {
  const ResourceBadge({
    required this.icon,
    required this.value,
    this.label,
    this.accent = PixelPalette.mint,
    super.key,
  });

  final IconData icon;
  final String value;
  final String? label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PixelPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PixelPalette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 7),
          Text(
            value,
            style: const TextStyle(
              color: PixelPalette.cream,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (label != null) ...<Widget>[
            const SizedBox(width: 4),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
