import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/services/capture_coordinator.dart';
import 'package:reality_diorama/src/ui/screens/crafting_screen.dart';
import 'package:reality_diorama/src/ui/widgets/material_visuals.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';

class CaptureSheet extends StatefulWidget {
  const CaptureSheet({super.key});

  @override
  State<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<CaptureSheet> {
  bool _loadingPreparation = true;
  bool _includeSurroundings = true;
  bool _capturing = false;
  CaptureBundle? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final controller = AppScope.read(context);
    await controller.refreshCapturePreparation();
    if (mounted) {
      setState(() => _loadingPreparation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final preparation = controller.capturePreparation;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: screenHeight * 0.90,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: PixelPalette.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _result == null ? '지금 수집' : '수집 완료',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                IconButton(
                  onPressed: _capturing
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: '닫기',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loadingPreparation
                  ? const Center(child: CircularProgressIndicator())
                  : _capturing
                  ? _CaptureProgress(
                      scansSurroundings:
                          _includeSurroundings &&
                          preparation?.surroundingReadiness.isReady == true,
                    )
                  : _result == null
                  ? _PreparationView(
                      preparation: preparation,
                      availableSteps: controller.availableSteps,
                      includeSurroundings: _includeSurroundings,
                      onSurroundingsChanged: (bool value) {
                        setState(() => _includeSurroundings = value);
                      },
                    )
                  : _ResultView(bundle: _result!),
            ),
            const SizedBox(height: 14),
            if (!_capturing && _result == null)
              FilledButton.icon(
                onPressed:
                    preparation == null ||
                        (!preparation.weatherReadiness.isReady &&
                            !preparation.surroundingReadiness.isReady)
                    ? null
                    : () => _capture(preparation),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('수집 시작'),
              ),
            if (!_capturing && _result != null) ...<Widget>[
              FilledButton.icon(
                onPressed: _result!.weatherMaterial == null
                    ? null
                    : () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => RecipeListScreen(
                            preselectedWeatherId: _result!.weatherMaterial?.id,
                            preselectedSurroundingId:
                                _result!.surroundingMaterial?.id,
                          ),
                        ),
                      ),
                icon: const Icon(Icons.handyman_outlined),
                label: const Text('이 재료로 만들기'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('보관하고 닫기'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _capture(CapturePreparation preparation) async {
    var include =
        _includeSurroundings && preparation.surroundingReadiness.isReady;
    if (include) {
      include = await _requestBluetoothPermission();
    }
    if (!mounted) {
      return;
    }
    setState(() => _capturing = true);
    final bundle = await AppScope.read(
      context,
    ).performCapture(includeSurroundings: include);
    if (!mounted) {
      return;
    }
    setState(() {
      _capturing = false;
      _result = bundle;
    });
  }

  Future<bool> _requestBluetoothPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();
      return scan.isGranted && connect.isGranted;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
    return false;
  }
}

class _PreparationView extends StatelessWidget {
  const _PreparationView({
    required this.preparation,
    required this.availableSteps,
    required this.includeSurroundings,
    required this.onSurroundingsChanged,
  });

  final CapturePreparation? preparation;
  final int availableSteps;
  final bool includeSurroundings;
  final ValueChanged<bool> onSurroundingsChanged;

  @override
  Widget build(BuildContext context) {
    final value = preparation;
    if (value == null) {
      return const Center(child: Text('수집 준비 상태를 확인하지 못했습니다.'));
    }
    return ListView(
      children: <Widget>[
        PixelCard(
          highlighted: value.weatherReadiness.isReady,
          child: _ReadinessRow(
            icon: value.weatherKind == null
                ? Icons.cloud_off_outlined
                : weatherIcon(value.weatherKind!),
            iconColor: value.weatherKind == null
                ? PixelPalette.muted
                : weatherColor(value.weatherKind!),
            title: '날씨',
            value: value.weatherKind == null
                ? '현재 날씨를 사용할 수 없음'
                : '${value.weatherKind!.labelKo} · ${value.timeBand.labelKo}',
            readiness: value.weatherReadiness,
          ),
        ),
        const SizedBox(height: 10),
        PixelCard(
          highlighted: value.surroundingReadiness.isReady,
          child: Column(
            children: <Widget>[
              _ReadinessRow(
                icon: Icons.radar,
                iconColor: PixelPalette.violet,
                title: '주변',
                value: '8초 동안 전파 패턴 읽기',
                readiness: value.surroundingReadiness,
              ),
              if (value.surroundingReadiness.isReady) ...<Widget>[
                const Divider(height: 20, color: PixelPalette.line),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: includeSurroundings,
                  onChanged: onSurroundingsChanged,
                  title: const Text('주변까지 함께 수집'),
                  subtitle: const Text('사람 수나 특정 기기를 기록하지 않습니다.'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        PixelCard(
          child: Row(
            children: <Widget>[
              const Icon(Icons.directions_walk, color: PixelPalette.mint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '제작에 쓸 수 있는 걸음',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$availableSteps걸음',
                      style: const TextStyle(
                        color: PixelPalette.mint,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '준비된 재료는 수집할 때까지 유지됩니다. 지금 만들지 않아도 자동으로 보관됩니다.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.readiness,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final ResourceReadiness readiness;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(value),
              const SizedBox(height: 5),
              Text(
                readiness.isReady ? '준비됨' : readiness.message ?? '아직 준비 중',
                style: TextStyle(
                  color: readiness.isReady
                      ? PixelPalette.success
                      : PixelPalette.muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CaptureProgress extends StatelessWidget {
  const _CaptureProgress({required this.scansSurroundings});

  final bool scansSurroundings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 112,
            height: 112,
            child: CircularProgressIndicator(
              strokeWidth: 7,
              color: scansSurroundings
                  ? PixelPalette.violet
                  : PixelPalette.mint,
              backgroundColor: PixelPalette.line,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            scansSurroundings ? '주변을 읽는 중' : '날씨를 기록하는 중',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            scansSurroundings ? '화면을 켠 상태로 잠시 기다려 주세요.' : '준비된 날씨 재료를 저장합니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.bundle});

  final CaptureBundle bundle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        if (bundle.weatherMaterial != null)
          PixelCard(
            highlighted: true,
            child: Row(
              children: <Widget>[
                MaterialOrb.weather(bundle.weatherMaterial!.kind),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '날씨 재료',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${bundle.weatherMaterial!.kind.labelKo} · '
                        '${bundle.weatherMaterial!.timeBand.labelKo}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (bundle.weatherMaterial != null &&
            bundle.surroundingMaterial != null)
          const SizedBox(height: 10),
        if (bundle.surroundingMaterial != null)
          PixelCard(
            highlighted: true,
            child: Row(
              children: <Widget>[
                MaterialOrb.surroundings(bundle.surroundingMaterial!.kind),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '주변 재료',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        bundle.surroundingMaterial!.kind.labelKo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '신뢰도 ${(bundle.surroundingMaterial!.confidence * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (bundle.weatherMaterial == null &&
            bundle.surroundingMaterial == null)
          const PixelCard(child: Text('새로 준비된 재료가 없어 기록만 확인했습니다.')),
        const SizedBox(height: 14),
        Text(
          '${bundle.record.userPlaceLabel ?? '현재 지역'} · '
          '${bundle.record.timeBand.labelKo}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
