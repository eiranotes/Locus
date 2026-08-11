import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_button.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';

class VisitorRequestCard extends StatelessWidget {
  const VisitorRequestCard({
    required this.request,
    required this.visitor,
    required this.relationship,
    required this.selected,
    required this.onSelect,
    required this.onCapture,
    super.key,
  });

  final VisitorRequest request;
  final VisitorDefinition visitor;
  final VisitorRelationship? relationship;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final remaining = request.expiresAt?.difference(DateTime.now());
    return PixelCard(
      onTap: onSelect,
      highlighted: selected,
      color: selected ? PixelPalette.raised : PixelPalette.scene,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: PixelPalette.blue.withValues(alpha: 0.10),
                  border: Border.all(color: PixelPalette.divider),
                  borderRadius: BorderRadius.circular(PixelRadii.tile),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    GeneratedArtPaths.visitor(visitor.id),
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            visitor.nameKo,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.adjust,
                            size: 18,
                            color: PixelPalette.mint,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _relationshipLabel(relationship),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PixelPalette.visitor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            request.promptKo,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(
                Icons.schedule_outlined,
                size: 17,
                color: PixelPalette.textMuted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _remainingLabel(remaining),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (request.difficulty > 1)
                Text(
                  '감각 ${request.difficulty}단계',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: PixelPalette.reward),
                ),
            ],
          ),
          if (selected) ...<Widget>[
            const SizedBox(height: 12),
            PixelButton(
              label: '이 표본 찾기',
              onPressed: onCapture,
              fallbackIcon: Icons.graphic_eq,
              actionAsset: 'capture',
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}

String _relationshipLabel(VisitorRelationship? relationship) {
  final stage = relationship?.stage ?? 0;
  return switch (stage) {
    0 => '낯선 손님',
    1 => '머무는 손님',
    2 => '익숙한 손님',
    3 => '가까운 손님',
    _ => '기억을 나누는 손님',
  };
}

String _remainingLabel(Duration? duration) {
  if (duration == null) return '천천히 찾아도 됩니다';
  if (duration <= Duration.zero) return '요청이 끝났습니다';
  if (duration.inHours < 1) return '${duration.inMinutes.clamp(1, 59)}분 남음';
  if (duration.inHours < 24) return '${duration.inHours}시간 남음';
  return '${(duration.inHours / 24).ceil()}일 남음';
}
