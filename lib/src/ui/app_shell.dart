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
    await controller.refreshWorld();
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
      HomeScreen(
        demoMode: widget.demoMode,
        onCapture: () => _showCapture(context),
      ),
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
        onDestination: controller.setNavigationIndex,
      ),
    );
  }

  Future<void> _showCapture(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: PixelPalette.canvas.withValues(alpha: 0.72),
      builder: (BuildContext context) => const CaptureSheet(),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onDestination});

  final int currentIndex;
  final ValueChanged<int> onDestination;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: PixelPalette.panel,
          border: Border(top: BorderSide(color: PixelPalette.divider)),
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
    final color = selected ? PixelPalette.action : PixelPalette.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PixelRadii.control),
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
