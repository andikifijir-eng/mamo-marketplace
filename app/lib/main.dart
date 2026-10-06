import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'router.dart';

void main() {
  runApp(const ProviderScope(child: MamoApp()));
}

class MamoApp extends ConsumerWidget {
  const MamoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MAMO',
      debugShowCheckedModeBanner: false,
      theme: MamoTheme.light(),
      routerConfig: router,
    );
  }
}
