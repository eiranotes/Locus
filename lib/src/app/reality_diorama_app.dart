import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/ui/app_shell.dart';

class RealityDioramaApp extends StatelessWidget {
  const RealityDioramaApp({required this.demoMode, super.key});
  final bool demoMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locus',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AppShell(demoMode: demoMode),
    );
  }
}
