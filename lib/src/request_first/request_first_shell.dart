import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/request_first/request_first_controller.dart';
import 'package:reality_diorama/src/request_first/request_first_scope.dart';
import 'package:reality_diorama/src/request_first/screens/request_first_capture_sheet.dart';
import 'package:reality_diorama/src/request_first/screens/request_first_home_screen.dart';
import 'package:reality_diorama/src/request_first/screens/specimen_archive_screen.dart';
import 'package:reality_diorama/src/request_first/screens/visitor_relationships_screen.dart';

class RequestFirstShell extends StatefulWidget {
  const RequestFirstShell({super.key});

  @override
  State<RequestFirstShell> createState() => _RequestFirstShellState();
}

class _RequestFirstShellState extends State<RequestFirstShell>
    with WidgetsBindingObserver {
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
    if (state != AppLifecycleState.resumed || !mounted) return;
    unawaited(RequestFirstScope.read(context).refreshWorld());
  }

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    final error = controller.errorMessage;
    if (error != null && error != _shownError) {
      _shownError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_cleanError(error)),
            action: SnackBarAction(
              label: '닫기',
              onPressed: controller.clearError,
            ),
          ),
        );
      });
    }
    final screens = <Widget>[
      RequestFirstHomeScreen(onCapture: () => _showCapture(context)),
      const SpecimenArchiveScreen(),
      const VisitorRelationshipsScreen(),
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
    final controller = RequestFirstScope.read(context);
    if (controller.focusedRequest == null) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: PixelPalette.canvas.withValues(alpha: 0.72),
      builder: (BuildContext context) => const RequestFirstCaptureSheet(),
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
                icon: Icons.graphic_eq,
                selectedIcon: Icons.equalizer,
                label: '표본',
                onTap: () => onDestination(1),
              ),
            ),
            Expanded(
              child: _Destination(
                selected: currentIndex == 2,
                icon: Icons.people_outline,
                selectedIcon: Icons.people,
                label: '손님',
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

String _cleanError(String value) {
  if (value.startsWith('Bad state: ')) return value.substring(11);
  if (value.startsWith('StateError: ')) return value.substring(12);
  return value;
}
