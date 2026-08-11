import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/request_first/request_first_scope.dart';
import 'package:reality_diorama/src/request_first/widgets/specimen_mark.dart';
import 'package:reality_diorama/src/ui/number_format.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_button.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';

class SpecimenArchiveScreen extends StatelessWidget {
  const SpecimenArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '표본',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                Text(
                  '${formatNumber(controller.specimenTotal)}개 기록',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: <Widget>[
              Tab(text: '감각 표본'),
              Tab(text: '기념물'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _SpecimensTab(controller: controller),
                _KeepsakesTab(controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecimensTab extends StatelessWidget {
  const _SpecimensTab({required this.controller});

  final dynamic controller;

  @override
  Widget build(BuildContext context) {
    if (controller.specimens.isEmpty) {
      return const _EmptyState(
        icon: Icons.graphic_eq,
        title: '아직 표본이 없습니다',
        body: '손님의 부탁을 보고 현실에서 감각 표본을 찾아보세요.',
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
        final singleColumn = constraints.maxWidth < 360 || largeText;
        return CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: singleColumn ? 1 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: singleColumn ? 1.25 : 0.78,
                ),
                itemCount: controller.specimens.length,
                itemBuilder: (BuildContext context, int index) {
                  final specimen = controller.specimens[index] as Specimen;
                  return _SpecimenCard(
                    specimen: specimen,
                    assignment: controller.assignmentForSpecimen(specimen.id),
                  );
                },
              ),
            ),
            if (controller.hasMoreSpecimens)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: PixelButton(
                    label: controller.loadingMoreSpecimens
                        ? '표본 불러오는 중'
                        : '이전 표본 더 보기',
                    onPressed:
                        controller.loadingMoreSpecimens || controller.busy
                        ? null
                        : controller.loadMoreSpecimens,
                    fallbackIcon: Icons.expand_more,
                    tone: PixelButtonTone.quiet,
                    expand: true,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 92)),
          ],
        );
      },
    );
  }
}

class _SpecimenCard extends StatelessWidget {
  const _SpecimenCard({required this.specimen, required this.assignment});

  final Specimen specimen;
  final SpecimenAssignment? assignment;

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    final request = assignment == null
        ? null
        : controller.requestById(assignment!.requestId);
    final visitor = request == null
        ? null
        : controller.legacyCatalog.visitorById(request.visitorId);
    final status = specimen.eligibility == SpecimenEligibility.legacyArchive
        ? '이전 수집'
        : visitor != null
        ? '${visitor.nameKo}에게 건넴'
        : specimen.eligibility == SpecimenEligibility.lowConfidence
        ? '판정 신뢰도 부족'
        : '기록됨';
    return PixelCard(
      radius: PixelRadii.tile,
      color: PixelPalette.scene,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SpecimenMark(
              specimen: specimen,
              compact: true,
              height: double.infinity,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            specimenDescription(specimen),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _dateLabel(specimen.capturedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 5),
          Text(
            status,
            style: TextStyle(
              color: visitor != null
                  ? PixelPalette.visitor
                  : specimen.eligibility == SpecimenEligibility.assignable
                  ? PixelPalette.mint
                  : PixelPalette.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeepsakesTab extends StatelessWidget {
  const _KeepsakesTab({required this.controller});

  final dynamic controller;

  @override
  Widget build(BuildContext context) {
    if (controller.sceneObjects.isEmpty) {
      return const _EmptyState(
        icon: Icons.home_work_outlined,
        title: '아직 기념물이 없습니다',
        body: '손님과 가까워지면 기존 디오라마 아트가 관계 기념물로 열립니다.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      itemCount: controller.sceneObjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final object = controller.sceneObjects[index] as SceneObject;
        return _KeepsakeRow(object: object);
      },
    );
  }
}

class _KeepsakeRow extends StatelessWidget {
  const _KeepsakeRow({required this.object});

  final SceneObject object;

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    final recipeId = object.origin == SceneObjectOrigin.relationshipReward
        ? controller.catalog.sceneObjectById(object.definitionId).legacyRecipeId
        : object.definitionId;
    final recipe = controller.legacyCatalog.recipeById(recipeId);
    final name = object.origin == SceneObjectOrigin.relationshipReward
        ? controller.catalog.sceneObjectById(object.definitionId).nameKo
        : recipe.nameKo;
    return PixelCard(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
      radius: 0,
      child: Row(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: PixelPalette.scene,
              border: Border.all(color: PixelPalette.divider),
              borderRadius: BorderRadius.circular(PixelRadii.tile),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Image.asset(
                GeneratedArtPaths.object(recipe.kind),
                filterQuality: FilterQuality.none,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  object.origin == SceneObjectOrigin.legacyCrafted
                      ? '이전 버전에서 만든 물건'
                      : '손님이 남긴 관계 기념물',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  object.lifecycle == SceneObjectLifecycle.placed
                      ? '내 공간에 배치됨'
                      : '보관 중',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: object.lifecycle == SceneObjectLifecycle.placed
                        ? PixelPalette.mint
                        : PixelPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 50, color: PixelPalette.textMuted),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 7),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}.$month.$day · $hour:$minute';
}
