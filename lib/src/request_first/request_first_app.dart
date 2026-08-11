import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/request_first/request_first_shell.dart';

class RequestFirstApp extends StatelessWidget {
  const RequestFirstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locus',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RequestFirstShell(),
    );
  }
}
