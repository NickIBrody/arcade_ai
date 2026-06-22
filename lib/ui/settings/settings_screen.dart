import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../../services/update_service.dart';
import '../widgets/ambient_background.dart';
import '../onboarding/welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.settings;
    final l = L(s.locale);

    return Scaffold(
      body: AmbientBackground(
        intensity: 0.6,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 4),
                  Text(l.settings,
                      style: Theme.of(context).textTheme.displaySmall),
                ],
              ),
              const SizedBox(height: 16),

              _Section(title: l.chooseLanguage, children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      _LangChip(
                        label: 'Русский',
                        active: s.locale == 'ru',
                        onTap: () {
                          s.locale = 'ru';
                          app.persistSettings();
                        },
                      ),
                      const SizedBox(width: 12),
                      _LangChip(
                        label: 'English',
                        active: s.locale == 'en',
                        onTap: () {
                          s.locale = 'en';
                          app.persistSettings();
                        },
                      ),
                    ],
                  ),
                ),
              ]),

              _Section(title: l.security, children: [
                _SwitchRow(
                  icon: Icons.lock_rounded,
                  title: l.encryption,
                  subtitle: l.encryptionSub,
                  value: s.encryptionEnabled,
                  onChanged: (v) {
                    s.encryptionEnabled = v;
                    app.persistSettings();
                  },
                ),
                _SwitchRow(
                  icon: Icons.fingerprint_rounded,
                  title: l.autoLock,
                  subtitle: l.autoLockSub,
                  value: s.autoLockEnabled,
                  onChanged: (v) {
                    s.autoLockEnabled = v;
                    app.persistSettings();
                  },
                ),
              ]),

              _Section(title: l.generation, children: [
                _SliderRow(
                  icon: Icons.thermostat_rounded,
                  title: l.temperature,
                  value: s.temperature,
                  min: 0,
                  max: 2,
                  display: s.temperature.toStringAsFixed(2),
                  onChanged: (v) {
                    s.temperature = v;
                    app.persistSettings();
                  },
                ),
                _SliderRow(
                  icon: Icons.numbers_rounded,
                  title: l.maxTokens,
                  value: s.maxTokens.toDouble(),
                  min: 256,
                  max: 8192,
                  display: '${s.maxTokens}',
                  onChanged: (v) {
                    s.maxTokens = v.round();
                    app.persistSettings();
                  },
                ),
                _SwitchRow(
                  icon: Icons.stream_rounded,
                  title: l.streamResponses,
                  value: s.streamResponses,
                  onChanged: (v) {
                    s.streamResponses = v;
                    app.persistSettings();
                  },
                ),
                _SwitchRow(
                  icon: Icons.psychology_alt_rounded,
                  title: l.showReasoningSetting,
                  value: s.showReasoning,
                  onChanged: (v) {
                    s.showReasoning = v;
                    app.persistSettings();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                  child: TextField(
                    controller:
                        TextEditingController(text: s.systemPrompt)
                          ..selection = TextSelection.collapsed(
                              offset: s.systemPrompt.length),
                    onChanged: (v) {
                      s.systemPrompt = v;
                      app.persistSettings();
                    },
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l.systemPrompt,
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surfaceHigh.withValues(alpha: 0.6),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ]),

              _Section(title: l.chooseProvider, children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.violetSoft),
                  title: Text('${app.activeProvider?.name ?? "—"}  ·  ${s.activeModel}',
                      style: const TextStyle(color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const WelcomeScreen(initialStep: 1))),
                ),
              ]),

              _Section(title: l.updates, children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline_rounded,
                      color: AppColors.violetSoft),
                  title: Text('${l.version}  $kAppVersion',
                      style: const TextStyle(color: AppColors.textPrimary)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.system_update_rounded,
                      color: AppColors.violetSoft),
                  title: Text(l.checkUpdates,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary),
                  onTap: () => _checkUpdates(context, l),
                ),
              ]),

              _Section(title: l.about, children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.code_rounded,
                      color: AppColors.violetSoft),
                  title: const Text('github.com/NickIBrody/arcade_ai',
                      style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text('Arcade AI',
                      style: Theme.of(context).textTheme.labelSmall),
                  onTap: () => launchUrl(Uri.parse(kRepoUrl),
                      mode: LaunchMode.externalApplication),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child:
                Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          ),
          ...children,
        ],
      ),
    );
  }
}

Future<void> _checkUpdates(BuildContext context, L l) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(SnackBar(
    backgroundColor: AppColors.surfaceHigh,
    duration: const Duration(milliseconds: 900),
    content: Text('${l.checkUpdates}…',
        style: const TextStyle(color: AppColors.textPrimary)),
  ));
  final info = await UpdateService.check();
  if (!context.mounted) return;
  if (info == null) {
    messenger.showSnackBar(SnackBar(
      backgroundColor: AppColors.surfaceHigh,
      content: Text('${l.errPrefix}: network',
          style: const TextStyle(color: AppColors.textPrimary)),
    ));
    return;
  }
  if (!info.available) {
    messenger.showSnackBar(SnackBar(
      backgroundColor: AppColors.surfaceHigh,
      content: Text(l.upToDate,
          style: const TextStyle(color: AppColors.textPrimary)),
    ));
    return;
  }
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surfaceHigh,
      title: Text(l.updateAvailable,
          style: const TextStyle(color: AppColors.textPrimary)),
      content: Text('v${info.latest}',
          style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.back,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            launchUrl(Uri.parse(info.url),
                mode: LaunchMode.externalApplication);
            Navigator.pop(context);
          },
          child: Text(l.download,
              style: const TextStyle(color: AppColors.violetSoft)),
        ),
      ],
    ),
  );
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? AppColors.violet.withValues(alpha: 0.16)
                : AppColors.surfaceHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: active ? AppColors.violet : AppColors.stroke,
                width: active ? 1.4 : 1),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: AppColors.violetSoft),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      activeColor: AppColors.violet,
      onChanged: onChanged,
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String title, display;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  const _SliderRow({
    required this.icon,
    required this.title,
    required this.display,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.violetSoft, size: 22),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: AppColors.textPrimary)),
              const Spacer(),
              Text(display, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.violet,
              inactiveTrackColor: AppColors.stroke,
              thumbColor: AppColors.violetSoft,
              overlayColor: AppColors.glow,
              trackHeight: 3,
            ),
            child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
