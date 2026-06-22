import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme.dart';
import '../../data/providers_catalog.dart';
import '../../l10n/strings.dart';
import '../../models/llm_provider.dart';

class ProviderGrid extends StatelessWidget {
  final L l;
  final VoidCallback onBack;
  final ValueChanged<LlmProvider> onPick;
  const ProviderGrid(
      {super.key, required this.l, required this.onBack, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final items = [...ProvidersCatalog.builtIns, ProvidersCatalog.customTemplate()];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BackBtn(onBack),
              const SizedBox(width: 6),
              Text(l.chooseProvider,
                  style: Theme.of(context).textTheme.displaySmall),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.18,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final p = items[i];
                return _ProviderCard(provider: p, l: l, onTap: () => onPick(p))
                    .animate()
                    .fadeIn(delay: (40 * i).ms, duration: 360.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final LlmProvider provider;
  final L l;
  final VoidCallback onTap;
  const _ProviderCard(
      {required this.provider, required this.l, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Color(int.parse('FF${provider.accent}', radix: 16));
    final custom = !provider.builtIn;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              ),
              child: Icon(
                custom ? Icons.tune_rounded : Icons.bolt_rounded,
                color: accent,
                size: 22,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Flexible(
                  child: Text(provider.builtIn ? provider.name : l.customProvider,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (!provider.fullySupported)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.textFaint),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(ProvidersCatalog.tagline(provider, l.isRu),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn(this.onTap);
  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.stroke)),
        ),
      );
}
