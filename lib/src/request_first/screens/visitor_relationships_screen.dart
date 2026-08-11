import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/request_first_catalog.dart';
import 'package:reality_diorama/src/request_first/request_first_scope.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';

class VisitorRelationshipsScreen extends StatelessWidget {
  const VisitorRelationshipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('손님', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Text(
                  '부탁을 채운 횟수만 관계에 반영됩니다. 배치와 현재 날씨는 관계 조건이 아닙니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
          sliver: SliverList.separated(
            itemCount: controller.catalog.relationshipTracks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final track = controller.catalog.relationshipTracks[index];
              return _RelationshipCard(track: track);
            },
          ),
        ),
      ],
    );
  }
}

class _RelationshipCard extends StatelessWidget {
  const _RelationshipCard({required this.track});

  final RelationshipTrackDefinition track;

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    final visitor = controller.legacyCatalog.visitorById(track.visitorId);
    final relationship = controller.relationships[track.visitorId];
    final activeRequest = controller.activeRequestForVisitor(track.visitorId);
    final fulfilled = relationship?.fulfilledCount ?? 0;
    final stage = relationship?.stage ?? 0;
    final nextMilestone = track.milestones
        .where(
          (RelationshipMilestoneDefinition value) =>
              value.fulfilledCount > fulfilled,
        )
        .firstOrNull;
    final denominator =
        nextMilestone?.fulfilledCount ?? fulfilled.clamp(1, 1 << 20);
    final previousThreshold = track.milestones
        .where(
          (RelationshipMilestoneDefinition value) =>
              value.fulfilledCount <= fulfilled,
        )
        .map((RelationshipMilestoneDefinition value) => value.fulfilledCount)
        .fold<int>(0, (int a, int b) => a > b ? a : b);
    final segmentLength = (denominator - previousThreshold).clamp(1, 1 << 20);
    final segmentProgress = ((fulfilled - previousThreshold) / segmentLength)
        .clamp(0.0, 1.0);
    return PixelCard(
      color: stage > 0 ? PixelPalette.scene : Colors.transparent,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: PixelPalette.blue.withValues(alpha: 0.10),
                  border: Border.all(color: PixelPalette.divider),
                  borderRadius: BorderRadius.circular(PixelRadii.tile),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(
                    GeneratedArtPaths.visitor(visitor.id),
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      visitor.nameKo,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stageLabel(stage),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PixelPalette.visitor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      visitor.descriptionKo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '부탁 $fulfilled회 완료',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                nextMilestone == null
                    ? '가장 가까운 관계'
                    : '${nextMilestone.fulfilledCount - fulfilled}회 남음',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: nextMilestone == null ? 1 : segmentProgress,
            minHeight: 6,
            backgroundColor: PixelPalette.line,
            color: PixelPalette.mint,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 12),
          if (activeRequest != null)
            DecoratedBox(
              decoration: BoxDecoration(
                color: PixelPalette.raised,
                borderRadius: BorderRadius.circular(PixelRadii.tile),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 19,
                      color: PixelPalette.mint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(activeRequest.promptKo)),
                  ],
                ),
              ),
            )
          else
            Text(
              stage > 0
                  ? '오늘은 내 공간에서 쉬고 있습니다.'
                  : '이 손님의 부탁이 도착하면 첫 표본을 건넬 수 있습니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (nextMilestone != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _milestoneLabel(nextMilestone),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: PixelPalette.reward),
            ),
          ],
        ],
      ),
    );
  }
}

String _stageLabel(int stage) => switch (stage) {
  0 => '낯선 손님',
  1 => '머무는 손님',
  2 => '익숙한 손님',
  3 => '가까운 손님',
  _ => '기억을 나누는 손님',
};

String _milestoneLabel(RelationshipMilestoneDefinition milestone) {
  if (milestone.unlockAxis != null) {
    return '다음 변화 · ${milestone.unlockAxis!.labelKo} 감각 해금';
  }
  if (milestone.sceneObjectId != null) {
    return '다음 변화 · 관계 기념물';
  }
  if (milestone.becomesResident) {
    return '다음 변화 · 내 공간에 머무름';
  }
  return '다음 변화 · 기억 요청 해금';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
