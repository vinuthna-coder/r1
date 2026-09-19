import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

class AlumniConnectApp extends ConsumerWidget {
  const AlumniConnectApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'Alumni Connect',
        debugShowCheckedModeBanner: false,
        routerConfig: ref.watch(routerProvider),
        theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xff155eef),
            inputDecorationTheme:
                const InputDecorationTheme(border: OutlineInputBorder()),
            cardTheme: const CardThemeData(margin: EdgeInsets.zero)),
        darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xff84adff)),
        themeMode: ThemeMode.system,
      );
}
