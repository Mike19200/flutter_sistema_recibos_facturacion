
import 'package:flutter_facturacion_sistema/Screens/archivos_screen.dart';
import 'package:flutter_facturacion_sistema/Screens/recibos_screen.dart';
import 'package:go_router/go_router.dart';


final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'recibos',
      builder: (context, state) => const RecibosScreen(),
    ),
    GoRoute(
      path: '/archivos',
      name: 'archivos',
      builder: (context, state) => const ArchivosScreen(),
    ),
  ],
);
