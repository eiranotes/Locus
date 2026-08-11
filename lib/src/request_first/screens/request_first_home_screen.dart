import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/diorama_view.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/request_first/request_first_scope.dart';
import 'package:reality_diorama/src/request_first/screens/request_first_settings_screen.dart';
import 'package:reality_diorama/src/request_first/widgets/request_card.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_button.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';

class RequestFirstHomeScreen extends StatelessWidget {
  const RequestFirstHomeScreen({required this.onCapture, super.key});

  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    final activeRequests = controller.activeRequests;
    final placedCount = controller.scenePlacements.length;
    final storedCount = controller.sceneObjects.length - placedCount;
    return RefreshIndicator(
      onRefresh: controller.refreshWorld,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            sliver: SliverList.list(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '내 공간',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '손님 ${controller.residentCount}명 · 표본 ${controller.specimenTotal}개',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const RequestFirstSettingsScreen(),
                        ),
                      ),
                      tooltip: '설정',
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 0.88,
                  child: Material(
                    color: PixelPalette.scene,
                    shape: const PixelCutBorder(
                      color: PixelPalette.divider,
                      width: 2,
                      cut: 8,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: DioramaView(
                            snapshot: controller.sceneSnapshot,
                            borderRadius: BorderRadius.zero,
                            semanticLabel:
                                '5 곱하기 5 관계 디오라마, 놓인 기념물 $placedCount개, 머무는 손님 ${controller.residentCount}명',
                          ),
                        ),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: PixelButton(
                            label: '표본 찾기',
                            onPressed: activeRequests.isEmpty
                                ? null
                                : onCapture,
                            fallbackIcon: Icons.graphic_eq,
                            actionAsset: 'capture',
                          ),
                        ),
                        if (storedCount > 0)
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: PixelPalette.panel.withValues(
                                  alpha: 0.92,
                                ),
                                border: Border.all(color: PixelPalette.divider),
                                borderRadius: BorderRadius.circular(
                                  PixelRadii.control,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Text(
                                  '보관 기념물 $storedCount',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '오늘의 부탁',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${activeRequests.length}/${controller.assignments.isEmpty ? controller.catalog.balance.tutorialRequestSlots : controller.catalog.balance.requestSlots}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  controller.assignments.isEmpty
                      ? '첫 표본을 건네면 두 손님의 부탁이 함께 열립니다.'
                      : '하나의 표본이 여러 부탁과 맞아도 한 손님에게만 줄 수 있습니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (activeRequests.isEmpty)
                  const PixelCard(
                    color: PixelPalette.scene,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '오늘의 부탁을 마쳤습니다',
                          style: TextStyle(
                            color: PixelPalette.textStrong,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text('새 부탁은 다음 게임 날짜에 도착합니다.'),
                      ],
                    ),
                  )
                else
                  for (
                    var index = 0;
                    index < activeRequests.length;
                    index += 1
                  ) ...<Widget>[
                    _RequestCardHost(
                      request: activeRequests[index],
                      selected:
                          controller.focusedRequest?.id ==
                          activeRequests[index].id,
                      onCapture: onCapture,
                    ),
                    if (index != activeRequests.length - 1)
                      const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCardHost extends StatelessWidget {
  const _RequestCardHost({
    required this.request,
    required this.selected,
    required this.onCapture,
  });

  final VisitorRequest request;
  final bool selected;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    return VisitorRequestCard(
      request: request,
      visitor: controller.legacyCatalog.visitorById(request.visitorId),
      relationship: controller.relationships[request.visitorId],
      selected: selected,
      onSelect: () => controller.focusRequest(request.id),
      onCapture: onCapture,
    );
  }
}
