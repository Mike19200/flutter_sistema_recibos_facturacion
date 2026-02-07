import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';
import 'router.dart';

void main() {
WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Recibos KALEYMAN');
    setWindowMinSize(const Size(500, 1000)); // tamaño mínimo
    setWindowMaxSize(const Size(900, 1100)); // tamaño máximo
    setWindowFrame(const Rect.fromLTWH(100, 100, 600, 1000)); // tamaño inicial
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Recibos',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
