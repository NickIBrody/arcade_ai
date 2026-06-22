import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../../models/llm_provider.dart';
import '../widgets/common.dart';

class ConnectForm extends StatefulWidget {
  final LlmProvider provider;
  final L l;
  final VoidCallback onBack;
  final VoidCallback onConnected;
  const ConnectForm({
    super.key,
    required this.provider,
    required this.l,
    required this.onBack,
    required this.onConnected,
  });

  @override
  State<ConnectForm> createState() => _ConnectFormState();
}

class _ConnectFormState extends State<ConnectForm> {
  final _key = TextEditingController();
  final _model = TextEditingController();
  final _name = TextEditingController();
  final _url = TextEditingController();
  final Map<String, TextEditingController> _extras = {};
  ApiFormat _format = ApiFormat.openai;
  bool _obscure = true;
  bool _busy = false;

  bool get isCustom => !widget.provider.builtIn;

  @override
  void initState() {
    super.initState();
    if (widget.provider.models.isNotEmpty) {
      _model.text = widget.provider.models.first;
    }
    for (final f in widget.provider.extraFields) {
      _extras[f.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in [_key, _model, _name, _url, ..._extras.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _connect() async {
    final l = widget.l;
    if (_model.text.trim().isEmpty) {
      _toast(l.model);
      return;
    }
    if (isCustom && _url.text.trim().isEmpty) {
      _toast(l.endpointUrl);
      return;
    }
    setState(() => _busy = true);
    final app = context.read<AppState>();

    LlmProvider provider = widget.provider;
    if (isCustom) {
      final name = _name.text.trim().isEmpty ? 'Custom' : _name.text.trim();
      provider = widget.provider.copyWith(
        id: 'custom_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}',
        name: name,
        baseUrl: _url.text.trim(),
        format: _format,
        models: [_model.text.trim()],
      );
    }

    await app.connect(
      provider: provider,
      apiKey: _key.text.trim(),
      model: _model.text.trim(),
      extras: {
        for (final e in _extras.entries) e.key: e.value.text.trim(),
      },
      isCustom: isCustom,
    );
    if (mounted) widget.onConnected();
  }

  void _toast(String field) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.surfaceHigh,
      content: Text('${widget.l.errPrefix}: $field'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final p = widget.provider;
    final accent = Color(int.parse('FF${p.accent}', radix: 16));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: ListView(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                ),
                child: Text(p.builtIn ? p.name : l.customProvider,
                    style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 22),

          if (!p.fullySupported)
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.violetSoft),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(l.notFullySupported,
                          style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            ),

          if (isCustom) ...[
            FieldLabel(l.providerName),
            TextField(controller: _name, decoration: glassInput('Мой провайдер')),
            const SizedBox(height: 18),
            FieldLabel(l.endpointUrl),
            TextField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: glassInput('https://api.example.com/v1')),
            const SizedBox(height: 18),
            FieldLabel(l.apiFormat),
            _FormatSelector(
                value: _format,
                l: l,
                onChanged: (f) => setState(() => _format = f)),
            const SizedBox(height: 18),
          ],

          FieldLabel(l.apiKey),
          TextField(
            controller: _key,
            obscureText: _obscure,
            decoration: glassInput(p.id == 'ollama' ? l.keyNotNeeded : p.keyHint,
                suffix: IconButton(
                  icon: Icon(
                      _obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: AppColors.textSecondary,
                      size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )),
          ),
          const SizedBox(height: 18),

          for (final f in p.extraFields) ...[
            FieldLabel(f.label),
            TextField(
                controller: _extras[f.key], decoration: glassInput(f.hint)),
            const SizedBox(height: 18),
          ],

          FieldLabel(l.model),
          TextField(controller: _model, decoration: glassInput('model-name')),
          if (p.models.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.models
                  .map((m) => GestureDetector(
                        onTap: () => setState(() => _model.text = m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(color: AppColors.stroke),
                          ),
                          child: Text(m,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12.5)),
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 30),
          GlowButton(
              label: l.continueBtn,
              loading: _busy,
              icon: Icons.check_rounded,
              onPressed: _connect),
        ],
      ).animate().fadeIn(duration: 320.ms),
    );
  }
}

class _FormatSelector extends StatelessWidget {
  final ApiFormat value;
  final L l;
  final ValueChanged<ApiFormat> onChanged;
  const _FormatSelector(
      {required this.value, required this.l, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const formats = [ApiFormat.openai, ApiFormat.anthropic];
    return Row(
      children: formats.map((f) {
        final active = f == value;
        final label = f == ApiFormat.openai ? l.formatOpenai : l.formatAnthropic;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 10),
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
                  style: TextStyle(
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
