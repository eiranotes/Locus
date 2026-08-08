import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/ui/screens/crafting_screen.dart';
import 'package:reality_diorama/src/ui/screens/placement_editor_screen.dart';
import 'package:reality_diorama/src/ui/widgets/material_visuals.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text('보관함', style: Theme.of(context).textTheme.headlineLarge),
                ),
                Text(
                  '${controller.captures.length}개 기록',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: <Widget>[
              Tab(text: '기록'),
              Tab(text: '재료'),
              Tab(text: '만든 것'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _RecordsTab(controller: controller),
                _MaterialsTab(controller: controller),
                _ObjectsTab(controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsTab extends StatelessWidget {
  const _RecordsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.captures.isEmpty) {
      return const _EmptyState(
        icon: Icons.photo_library_outlined,
        title: '아직 수집 기록이 없습니다',
        body: '준비된 날씨를 수집하면 이곳에 출처가 남습니다.',
      );
    }
    final weatherById = <String, WeatherMaterial>{
      for (final material in controller.weatherMaterials) material.id: material,
    };
    final surroundingById = <String, SurroundingMaterial>{
      for (final material in controller.surroundingMaterials) material.id: material,
    };
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.83,
      ),
      itemCount: controller.captures.length,
      itemBuilder: (BuildContext context, int index) {
        final record = controller.captures[index];
        return _RecordCard(
          record: record,
          weather: record.weatherMaterialId == null
              ? null
              : weatherById[record.weatherMaterialId],
          surroundings: record.surroundingMaterialId == null
              ? null
              : surroundingById[record.surroundingMaterialId],
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.weather,
    required this.surroundings,
  });

  final CaptureRecord record;
  final WeatherMaterial? weather;
  final SurroundingMaterial? surroundings;

  @override
  Widget build(BuildContext context) {
    final kind = weather?.kind ?? WeatherMaterialKind.cloudy;
    final accent = weatherColor(kind);
    return PixelCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RecordStampPainter(
                        accent: accent,
                        seed: record.capturedAt.millisecondsSinceEpoch,
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      weatherIcon(kind),
                      color: accent,
                      size: 42,
                    ),
                  ),
                  if (surroundings != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Icon(
                        surroundingIcon(surroundings!.kind),
                        color: PixelPalette.violet,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            record.userPlaceLabel ?? '현재 지역',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 3),
          Text(
            '${_time(record.capturedAt)} · ${record.timeBand.labelKo}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 5),
          Text(
            weather == null ? '기록만 저장됨' : weather!.kind.labelKo,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MaterialsTab extends StatelessWidget {
  const _MaterialsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final weather = controller.weatherMaterials;
    final surroundings = controller.surroundingMaterials;
    if (weather.isEmpty && surroundings.isEmpty) {
      return const _EmptyState(
        icon: Icons.blur_circular,
        title: '보관된 재료가 없습니다',
        body: '수집한 재료는 사용하기 전까지 이곳에 남습니다.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      children: <Widget>[
        Text('날씨', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final material in weather) ...<Widget>[
          _WeatherMaterialRow(material: material),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        Text('주변', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (surroundings.isEmpty)
          const PixelCard(child: Text('주변 재료는 선택 수집입니다.'))
        else
          for (final material in surroundings) ...<Widget>[
            _SurroundingMaterialRow(material: material),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _WeatherMaterialRow extends StatelessWidget {
  const _WeatherMaterialRow({required this.material});

  final WeatherMaterial material;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      child: Row(
        children: <Widget>[
          MaterialOrb.weather(material.kind),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${material.kind.labelKo} · ${material.timeBand.labelKo}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  material.isAvailable ? '사용 가능' : '제작에 사용됨',
                  style: TextStyle(
                    color: material.isAvailable
                        ? PixelPalette.success
                        : PixelPalette.muted,
                  ),
                ),
              ],
            ),
          ),
          if (material.isAvailable)
            IconButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => RecipeListScreen(
                    preselectedWeatherId: material.id,
                  ),
                ),
              ),
              tooltip: '이 재료로 만들기',
              icon: const Icon(Icons.handyman_outlined),
            ),
        ],
      ),
    );
  }
}

class _SurroundingMaterialRow extends StatelessWidget {
  const _SurroundingMaterialRow({required this.material});

  final SurroundingMaterial material;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      child: Row(
        children: <Widget>[
          MaterialOrb.surroundings(material.kind),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  material.kind.labelKo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  material.isAvailable
                      ? '사용 가능 · 신뢰도 ${(material.confidence * 100).round()}%'
                      : '제작에 사용됨',
                  style: TextStyle(
                    color: material.isAvailable
                        ? PixelPalette.success
                        : PixelPalette.muted,
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

class _ObjectsTab extends StatelessWidget {
  const _ObjectsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.craftedObjects.isEmpty) {
      return const _EmptyState(
        icon: Icons.handyman_outlined,
        title: '아직 만든 물건이 없습니다',
        body: '날씨 재료와 걸음을 사용해 첫 물건을 만들어 보세요.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      itemCount: controller.craftedObjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (BuildContext context, int index) {
        final object = controller.craftedObjects[index];
        final recipe = controller.catalog.recipeById(object.recipeId);
        return PixelCard(
          child: Row(
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: weatherColor(object.weatherKind).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  objectIcon(object.kind),
                  color: weatherColor(object.weatherKind),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(recipe.nameKo, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      object.isComplete
                          ? object.lifecycle == ObjectLifecycle.placed
                              ? '내 공간에 배치됨'
                              : '보관 중'
                          : '${object.remainingSteps}걸음 남음',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (!object.isComplete) ...<Widget>[
                      const SizedBox(height: 7),
                      LinearProgressIndicator(
                        value: object.appliedSteps / object.requiredSteps,
                        color: PixelPalette.mint,
                        backgroundColor: PixelPalette.line,
                      ),
                    ],
                  ],
                ),
              ),
              if (object.isComplete)
                IconButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          PlacementEditorScreen(initialObjectId: object.id),
                    ),
                  ),
                  tooltip: '배치 편집',
                  icon: const Icon(Icons.grid_view_outlined),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RecordStampPainter extends CustomPainter {
  const _RecordStampPainter({required this.accent, required this.seed});

  final Color accent;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..color = accent.withValues(alpha: 0.14);
    for (var index = 0; index < 18; index += 1) {
      final x = ((seed ~/ (index + 3) + index * 31) % 100) / 100 * size.width;
      final y = ((seed ~/ (index + 7) + index * 47) % 100) / 100 * size.height;
      final unit = index.isEven ? 3.0 : 2.0;
      canvas.drawRect(Rect.fromLTWH(x, y, unit, unit), paint);
    }
    final line = Paint()
      ..isAntiAlias = false
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.25);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.75,
        height: size.height * 0.55,
      ),
      0.3,
      4.3,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(_RecordStampPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.seed != seed;
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
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 52, color: PixelPalette.muted),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
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

String _time(DateTime date) {
  final local = date.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
