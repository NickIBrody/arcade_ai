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

  final List<SshProfile> _profiles = [];
  final _terminal = Terminal(maxLines: 10000);
  final _ssh = SshSessionController();
  bool _connected = false;
  bool _connecting = false;
  String? _error;

  L get l => widget.l;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final raw = await context.read<AppState>().secure.readSshProfiles();
    final list = (jsonDecode(raw) as List)
        .map((e) => SshProfile.fromJson(e as Map<String, dynamic>))
        .toList();
    setState(() {
      _profiles
        ..clear()
        ..addAll(list);
    });
  }

  void _fill(SshProfile p) {
    _host.text = p.host;
    _port.text = '${p.port}';
    _user.text = p.username;
    _label.text = p.label;
    context.read<AppState>().secure.readSshPassword(p.id).then((pw) {
      if (pw != null) _pass.text = pw;
    });
  }

  Future<void> _connect() async {
    final host = _host.text.trim();
    final user = _user.text.trim();
    if (host.isEmpty || user.isEmpty) {
      setState(() => _error = '${l.errPrefix}: host / user');
      return;
    }
    setState(() {
      _connecting = true;
      _error = null;
      _connected = true;
    });

    if (_remember) await _saveProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await _ssh.connect(
        host: host,
        port: int.tryParse(_port.text.trim()) ?? 22,
        username: user,
        password: _pass.text,
        terminal: _terminal,
      );
      if (!mounted) return;
      setState(() {
        _connecting = false;
        if (!ok) {
          _connected = false;
          _error = _ssh.error;
        }
      });
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

  void _disconnect() {
    _ssh.close();
    setState(() => _connected = false);
  }

  Future<void> _exportKey() async {
    final app = context.read<AppState>();
    final p = app.activeProvider;
    if (p == null) return;
    final key = await app.secure.readKey(p.id);
    if (key == null || key.isEmpty) return;
    final env = _envForProvider[p.id] ?? 'API_KEY';
    _ssh.run('export $env="$key"');
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
          child: _connected ? _terminalView() : _connectForm(),
        ),
      ),
    );
  }

  Widget _connectForm() {
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
            Container(
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
            ),
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
        TextField(controller: _host, decoration: glassInput('192.168.1.10 / example.com')),
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
        const SizedBox(height: 14),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _remember,
          activeColor: AppColors.violet,
          onChanged: (v) => setState(() => _remember = v),
          title: Text(l.rememberMachine,
              style: const TextStyle(color: AppColors.textPrimary)),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ),
        const SizedBox(height: 14),
        GlowButton(
            label: l.connect, icon: Icons.terminal_rounded, onPressed: _connect),
      ],
    );
  }

  Widget _terminalView() {
    return Column(
      children: [
        _terminalBar(),
        Expanded(
          child: Container(
            color: const Color(0xFF050409),
            child: TerminalView(
              _terminal,
              autofocus: true,
              backgroundOpacity: 1,
            ),
          ),
        ),
        _quickKeys(),
      ],
    );
  }

  Widget _terminalBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: AppColors.stroke)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _disconnect,
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              _connecting ? l.connecting : '${_user.text}@${_host.text}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          TextButton(
            onPressed: _exportKey,
            child: Text(l.exportKey,
                style: const TextStyle(color: AppColors.violetSoft, fontSize: 12)),
          ),
          TextButton(
            onPressed: () => _ssh.run(kProvisionScript.replaceAll('\n', ' ')),
            child: Text(l.setupOpencode,
                style: const TextStyle(color: AppColors.violetSoft, fontSize: 12)),
          ),
          IconButton(
            onPressed: () => _ssh.run('opencode'),
            icon: const Icon(Icons.play_arrow_rounded, color: AppColors.success),
          ),
        ],
      ),
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
}
