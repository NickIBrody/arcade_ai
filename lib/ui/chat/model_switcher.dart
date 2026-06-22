import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';

class ModelSwitcher extends StatefulWidget {
  final L l;
  const ModelSwitcher({super.key, required this.l});
  @override
  State<ModelSwitcher> createState() => _ModelSwitcherState();
}

class _ModelSwitcherState extends State<ModelSwitcher> {
  final _manual = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.activeProvider;
    final models = p?.models ?? const [];
    final maxH = MediaQuery.of(context).size.height * 0.7;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        border: Border(top: BorderSide(color: AppColors.stroke)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.stroke,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.l.model,
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 14),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: models.map((m) {
                final active = m == app.settings.activeModel;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    app.setActiveModel(m);
                    Navigator.pop(context);
                  },
                  leading: Icon(
                      active
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: active ? AppColors.violet : AppColors.textFaint),
                  title: Text(m,
                      style: const TextStyle(color: AppColors.textPrimary)),
                );
              }).toList(),
            ),
          ),
          const Divider(color: AppColors.stroke),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manual,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'model-name',
                    hintStyle: const TextStyle(color: AppColors.textFaint),
                    filled: true,
                    fillColor: AppColors.surfaceHigh,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () {
                  if (_manual.text.trim().isEmpty) return;
                  app.setActiveModel(_manual.text.trim());
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_rounded, color: AppColors.violet),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
