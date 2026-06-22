import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../../models/ssh_profile.dart';
import '../../services/ssh_service.dart';
import '../widgets/ambient_background.dart';
import '../widgets/common.dart';

const Map<String, String> _envForProvider = {
  'openai': 'OPENAI_API_KEY',
  'anthropic': 'ANTHROPIC_API_KEY',
  'gemini': 'GEMINI_API_KEY',
  'groq': 'GROQ_API_KEY',
  'deepseek': 'DEEPSEEK_API_KEY',
  'xai': 'XAI_API_KEY',
  'mistral': 'MISTRAL_API_KEY',
  'openrouter': 'OPENROUTER_API_KEY',
  'together': 'TOGETHER_API_KEY',
  'cohere': 'COHERE_API_KEY',
};

enum _Stage { form, setup, terminal }

enum _StepState { pending, active, done, failed }

class _SetupStep {
  final String label;
  _StepState state = _StepState.pending;
  String log = '';
  _SetupStep(this.label);
}

class TerminalScreen extends StatefulWidget {
  final L l;
  const TerminalScreen({super.key, required this.l});
  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '22');
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _label = TextEditingController();
  bool _remember = true;
  bool _auto = false;

  final List<SshProfile> _profiles = [];
  final _terminal = Terminal(maxLines: 10000);
  final _ssh = SshSessionController();

  _Stage _stage = _Stage.form;
  late List<_SetupStep> _steps;
  bool _failed = false;
  bool _showLog = false;
  String? _formError;
  String _apiKey = '';

  L get l => widget.l;

  @override
  void initState() {
    super.initState();
    _resetSteps();
    _loadProfiles();
  }

  void _resetSteps() {
    _steps = [
      _SetupStep(l.stepConnect),
      _SetupStep(l.stepDeps),
      _SetupStep(l.stepOpencode),
      _SetupStep(l.stepLaunch),
    ];
  }

  Future<void> _loadProfiles() async {
    final raw = await context.read<AppState>().secure.readSshProfiles();
    final list = (jsonDecode(raw) as List)
        .map((e) => SshProfile.fromJson(e as Map<String, dynamic>))
        .toList();
    if (mounted) setState(() => _profiles..clear()..addAll(list));
  }

  void _fill(SshProfile p) {
    _host.text = p.host;
    _port.text = '${p.port}';
    _user.text = p.username;
    _label.text = p.label;
    context.read<AppState>().secure.readSshPassword(p.id).then((pw) {
      if (pw != null) setState(() => _pass.text = pw);
    });
  }

  Future<void> _saveProfile() async {
    final store = context.read<AppState>().secure;
    final id = '${_user.text.trim()}@${_host.text.trim()}';
    _profiles.removeWhere((p) => p.id == id);
    _profiles.add(SshProfile(
      id: id,
      label: _label.text.trim(),
      host: _host.text.trim(),
      port: int.tryParse(_port.text.trim()) ?? 22,
      username: _user.text.trim(),
    ));
    await store.saveSshProfiles(
        jsonEncode(_profiles.map((e) => e.toJson()).toList()));
    await store.saveSshPassword(id, _pass.text);
  }

  void _set(int i, _StepState s, [String log = '']) {
    if (!mounted) return;
    setState(() {
      _steps[i].state = s;
      if (log.isNotEmpty) _steps[i].log = log;
      if (s == _StepState.failed) _failed = true;
    });
  }

  String _launchCommand() {
    final env =
        _envForProvider[context.read<AppState>().activeProvider?.id] ?? 'API_KEY';
    final b = StringBuffer();
    if (_apiKey.isNotEmpty) b.write('export $env="$_apiKey"; ');
    if (_auto) b.write('export OPENCODE_AUTO_APPROVE=1; ');
    b.write('opencode');
    return b.toString();
  }

  Future<void> _runSetup() async {
    final host = _host.text.trim();
    final user = _user.text.trim();
    if (host.isEmpty || user.isEmpty) {
      setState(() => _formError = '${l.errPrefix}: host / user');
      return;
    }
    _formError = null;
    if (_remember) await _saveProfile();

    final app = context.read<AppState>();
    _apiKey = (await app.secure.readKey(app.activeProvider?.id ?? '')) ?? '';

    _resetSteps();
    setState(() {
      _stage = _Stage.setup;
      _failed = false;
      _showLog = false;
    });

    _set(0, _StepState.active);
    final ok = await _ssh.connect(
        host: host,
        port: int.tryParse(_port.text.trim()) ?? 22,
        username: user,
        password: _pass.text);
    if (!ok) return _set(0, _StepState.failed, _ssh.error ?? 'connect failed');
    _set(0, _StepState.done);

    _set(1, _StepState.active);
    final deps = await _ssh.exec(kInstallDepsCmd);
    if (!deps.ok) return _set(1, _StepState.failed, deps.output);
    _set(1, _StepState.done);

    _set(2, _StepState.active);
    final oc = await _ssh.exec(kInstallOpencodeCmd);
    if (!oc.ok) return _set(2, _StepState.failed, oc.output);
    _set(2, _StepState.done);

    _set(3, _StepState.active);
    setState(() => _stage = _Stage.terminal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ssh.startShell(_terminal, initialCommand: _launchCommand());
    });
  }

  Future<void> _manualTerminal() async {
    final host = _host.text.trim();
    if (host.isEmpty) {
      setState(() => _formError = '${l.errPrefix}: host');
      return;
    }
    final ok = await _ssh.connect(
        host: host,
        port: int.tryParse(_port.text.trim()) ?? 22,
        username: _user.text.trim(),
        password: _pass.text);
    if (!ok) {
      setState(() => _formError = _ssh.error);
      return;
    }
    setState(() => _stage = _Stage.terminal);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _ssh.startShell(_terminal));
  }

  void _disconnect() {
    _ssh.close();
    setState(() => _stage = _Stage.form);
  }

  @override
  void dispose() {
    _ssh.close();
    for (final c in [_host, _port, _user, _pass, _label]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        intensity: 0.5,
        child: SafeArea(
          child: switch (_stage) {
            _Stage.form => _formView(),
            _Stage.setup => _setupView(),
            _Stage.terminal => _terminalView(),
          },
        ),
      ),
    );
  }

  // ---------- form ----------
  Widget _formView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 4),
            Text(l.terminal, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(width: 8),
            _betaTag(),
          ],
        ),
        const SizedBox(height: 8),
        Text(l.terminalHint, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 18),
        if (_profiles.isNotEmpty) ...[
          FieldLabel(l.savedMachines),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _profiles
                .map((p) => GestureDetector(
                      onTap: () => _fill(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(color: AppColors.stroke),
                        ),
                        child: Text(p.display,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12.5)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),
        ],
        FieldLabel(l.sshHost),
        TextField(
            controller: _host,
            decoration: glassInput('192.168.1.10 / example.com')),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldLabel(l.sshUser),
                  TextField(controller: _user, decoration: glassInput('root')),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldLabel(l.sshPort),
                  TextField(
                      controller: _port,
                      keyboardType: TextInputType.number,
                      decoration: glassInput('22')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FieldLabel(l.sshPassword),
        TextField(
            controller: _pass,
            obscureText: true,
            decoration: glassInput('••••••••')),
        const SizedBox(height: 14),
        FieldLabel(l.sshLabel),
        TextField(controller: _label, decoration: glassInput(l.sshLabelHint)),
        const SizedBox(height: 18),
        FieldLabel(l.runMode),
        Row(
          children: [
            _modeChip(l.modeConfirm, !_auto, () => setState(() => _auto = false)),
            const SizedBox(width: 10),
            _modeChip(l.modeAuto, _auto, () => setState(() => _auto = true)),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _remember,
          activeColor: AppColors.violet,
          onChanged: (v) => setState(() => _remember = v),
          title: Text(l.rememberMachine,
              style: const TextStyle(color: AppColors.textPrimary)),
        ),
        if (_formError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child:
                Text(_formError!, style: const TextStyle(color: AppColors.danger)),
          ),
        const SizedBox(height: 8),
        GlowButton(
            label: l.start, icon: Icons.rocket_launch_rounded, onPressed: _runSetup),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _manualTerminal,
            child: Text(l.manualTerminal,
                style: const TextStyle(color: AppColors.textFaint, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _modeChip(String label, bool active, VoidCallback onTap) {
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
                : AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: active ? AppColors.violet : AppColors.stroke),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: active ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5)),
        ),
      ),
    );
  }

  // ---------- setup progress ----------
  Widget _setupView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: _disconnect,
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 4),
              Text(l.setupOpencode,
                  style: Theme.of(context).textTheme.displaySmall),
            ],
          ),
          const SizedBox(height: 30),
          ..._steps.map(_stepTile),
          const Spacer(),
          if (_failed) ...[
            GestureDetector(
              onTap: () => setState(() => _showLog = !_showLog),
              child: Row(
                children: [
                  Icon(_showLog ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary, size: 20),
                  Text(l.showDetails,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (_showLog)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _steps.firstWhere((s) => s.state == _StepState.failed,
                        orElse: () => _steps.last).log,
                    style: const TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 12,
                        fontFamily: 'monospace'),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GlowButton(
                      label: l.retry,
                      icon: Icons.refresh_rounded,
                      onPressed: _runSetup),
                ),
                const SizedBox(width: 12),
                TextButton(
                    onPressed: _manualTerminal,
                    child: Text(l.manualTerminal,
                        style: const TextStyle(color: AppColors.textFaint))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepTile(_SetupStep s) {
    Widget icon;
    switch (s.state) {
      case _StepState.done:
        icon = const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 24);
        break;
      case _StepState.active:
        icon = const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: AppColors.violetSoft));
        break;
      case _StepState.failed:
        icon = const Icon(Icons.error_rounded,
            color: AppColors.danger, size: 24);
        break;
      case _StepState.pending:
        icon = const Icon(Icons.circle_outlined,
            color: AppColors.textFaint, size: 22);
    }
    final dim = s.state == _StepState.pending;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 26, child: Center(child: icon)),
          const SizedBox(width: 14),
          Text(s.label,
              style: TextStyle(
                  color: dim ? AppColors.textFaint : AppColors.textPrimary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ---------- terminal ----------
  Widget _terminalView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: AppColors.stroke)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _disconnect,
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary),
              ),
              Expanded(
                child: Text('${_user.text}@${_host.text}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall),
              ),
              IconButton(
                onPressed: () => _ssh.run('opencode'),
                icon: const Icon(Icons.play_arrow_rounded,
                    color: AppColors.success),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFF050409),
            child: TerminalView(_terminal,
                autofocus: true, backgroundOpacity: 1),
          ),
        ),
        _quickKeys(),
      ],
    );
  }

  Widget _quickKeys() {
    Widget key(String label, String raw) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: GestureDetector(
            onTap: () => _ssh.send(raw),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5)),
            ),
          ),
        );
    return Container(
      color: AppColors.surface.withValues(alpha: 0.8),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            key('Esc', '\x1b'),
            key('Tab', '\t'),
            key('Ctrl-C', '\x03'),
            key('Ctrl-D', '\x04'),
            key('↑', '\x1b[A'),
            key('↓', '\x1b[B'),
            key('←', '\x1b[D'),
            key('→', '\x1b[C'),
            key('Enter', '\r'),
          ],
        ),
      ),
    );
  }

  Widget _betaTag() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.violet.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text('BETA',
            style: TextStyle(
                color: AppColors.violetSoft,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      );
}
