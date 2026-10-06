import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final auth = ref.read(authProvider);
    final onboarded = await SessionStore.onboarded;
    if (!mounted) return;
    if (auth.loggedIn) {
      context.go('/home');
    } else if (!onboarded) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: MamoColors.brandGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MamoLogo(size: 64, showWordmark: false, textColor: Colors.white),
              SizedBox(height: 20),
              Text('MAMO',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              SizedBox(height: 8),
              Text('Marketplace Mahasiswa Online',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(height: 36),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
