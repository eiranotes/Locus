import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/ui/screens/capture_sheet.dart';
import 'package:reality_diorama/src/ui/screens/codex_screen.dart';
import 'package:reality_diorama/src/ui/screens/home_screen.dart';
import 'package:reality_diorama/src/ui/screens/inventory_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.demoMode, super.key});
  final bool demoMode;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  String? _shownError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    final controller = AppScope.read(context);
    unawaited(_refreshAfterResume(controller));
  }

  Future<void> _refreshAfterResume(AppController controller) async {
    if (controller.stepTrackingConfigured) {
      await controller.refreshSteps();
    }
    if (controller.capturePreparation != null) {
      await controller.refreshCapturePreparation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final error = controller.errorMessage;
    if (error != null && error != _shownError) {
      _shownError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      });
    }

    final screens = <Widget>[
      HomeScreen(demoMode: widget.demoMode),
      const InventoryScreen(),
      const CodexScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: controller.navigationIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: _BottomBar(
        currentIndex: controller.navigationIndex,
        readyCount: controller.captureReadyCount,
        onDestination: controller.setNavigationIndex,
        onCapture: () => _showCapture(context),
      ),
    );
  }

  Future<void> _showCapture(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: PixelPalette.background,
      builder: (BuildContext context) => const CaptureSheet(),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.readyCount,
    required this.onDestination,
    required this.onCapture,
  });

  final int currentIndex;
  final int readyCount;
  final ValueChanged<int> onDestination;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: PixelPalette.surface,
          border: Border(top: BorderSide(color: PixelPalette.line)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _Destination(
                selected: currentIndex == 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: '내 공간',
                onTap: () => onDestination(0),
              ),
            ),
            Expanded(
              child: Center(
                child: Badge(
                  isLabelVisible: readyCount > 0,
                  label: Text('$readyCount'),
                  backgroundColor: PixelPalette.danger,
                  child: Semantics(
                    button: true,
                    label: '수집',
                    child: InkResponse(
                      onTap: onCapture,
                      radius: 34,
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PixelPalette.mint,
                          border: Border.all(
                            color: PixelPalette.cream.withValues(alpha: 0.55),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: PixelPalette.background,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _Destination(
                selected: currentIndex == 1,
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2,
                label: '보관함',
                onTap: () => onDestination(1),
              ),
            ),
            Expanded(
              child: _Destination(
                selected: currentIndex == 2,
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book,
                label: '도감',
                onTap: () => onDestination(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? PixelPalette.mint : PixelPalette.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(selected ? selectedIcon : icon, color: color, size: 25),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
