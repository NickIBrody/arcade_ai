import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../../models/llm_provider.dart';
import '../widgets/ambient_background.dart';
import '../widgets/common.dart';
import '../chat/chat_screen.dart';
import 'provider_grid.dart';
import 'connect_form.dart';

class WelcomeScreen extends StatefulWidget {
  /// 0 = full onboarding (intro → provider → connect).
  /// 1 = jump straight to provider selection (used from Settings to switch
  /// provider without showing the greeting again).
  final int initialStep;
  const WelcomeScreen({super.key, this.initialStep = 0});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final PageController _controller =
      PageController(initialPage: widget.initialStep);
  LlmProvider? _picked;

  L get l => L(context.read<AppState>().settings.locale);

  void _go(int i) {
    setState(() {});
    _controller.animateToPage(i,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _Intro(onStart: () => _go(1), onLocale: () => setState(() {})),
              ProviderGrid(
                l: l,
                onBack: () =>
                    widget.initialStep >= 1 ? Navigator.pop(context) : _go(0),
                onPick: (p) {
                  setState(() => _picked = p);
                  _go(2);
                },
              ),
              if (_picked != null)
                ConnectForm(
                  provider: _picked!,
                  l: l,
                  onBack: () => _go(1),
                  onConnected: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => const ChatScreen()));
                  },
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onLocale;
  const _Intro({required this.onStart, required this.onLocale});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final l = L(app.settings.locale);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          const _Logo(),
          const SizedBox(height: 34),
          Text(l.welcomeTitle, style: Theme.of(context).textTheme.displayLarge)
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideX(begin: -0.1, end: 0),
          const SizedBox(height: 12),
          Text(l.welcomeSub, style: Theme.of(context).textTheme.bodyLarge)
              .animate()
              .fadeIn(delay: 400.ms, duration: 600.ms),
          const Spacer(flex: 2),
          FieldLabel(l.chooseLanguage),
          Row(
            children: [
              _LangPill(
                  code: 'ru',
                  label: 'Русский',
                  active: l.isRu,
                  onTap: () {
                    app.settings.locale = 'ru';
                    app.persistSettings();
                    onLocale();
                  }),
              const SizedBox(width: 12),
              _LangPill(
                  code: 'en',
                  label: 'English',
                  active: !l.isRu,
                  onTap: () {
                    app.settings.locale = 'en';
                    app.persistSettings();
                    onLocale();
                  }),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: GlowButton(
                label: l.getStarted,
                icon: Icons.arrow_forward_rounded,
                onPressed: onStart),
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: AppColors.violetGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: AppColors.violet.withValues(alpha: 0.6), blurRadius: 36)
        ],
      ),
      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 40),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.06, 1.06),
            duration: 2200.ms,
            curve: Curves.easeInOut)
        .animate()
        .fadeIn(duration: 700.ms)
        .slideY(begin: -0.2, end: 0);
  }
}

class _LangPill extends StatelessWidget {
  final String code, label;
  final bool active;
  final VoidCallback onTap;
  const _LangPill(
      {required this.code,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          color: active
              ? AppColors.violet.withValues(alpha: 0.16)
              : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
              color: active ? AppColors.violet : AppColors.stroke,
              width: active ? 1.4 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
