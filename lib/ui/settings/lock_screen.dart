import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../widgets/ambient_background.dart';
import '../widgets/common.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _auth = LocalAuthentication();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l = L(context.read<AppState>().settings.locale);
    try {
      final ok = await _auth.authenticate(
        localizedReason: l.unlock,
        options: const AuthenticationOptions(
            stickyAuth: true, biometricOnly: false),
      );
      if (ok && mounted) context.read<AppState>().unlock();
    } catch (_) {
      // device without enrolled auth: fall back to unlocking on tap
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L(context.read<AppState>().settings.locale);
    return Scaffold(
      body: AmbientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded,
                      size: 56, color: AppColors.violetSoft)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.08, 1.08),
                      duration: 1600.ms),
              const SizedBox(height: 18),
              Text(l.locked, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GlowButton(
                    label: l.unlock,
                    icon: Icons.fingerprint_rounded,
                    loading: _busy,
                    onPressed: _authenticate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
