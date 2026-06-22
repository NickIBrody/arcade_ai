import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';

/// Collapsible "reasoning" panel shown above a thinking model's answer.
class ThinkingBlock extends StatefulWidget {
  final String reasoning;
  final bool live;
  final L l;
  const ThinkingBlock(
      {super.key, required this.reasoning, required this.l, this.live = false});

  @override
  State<ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<ThinkingBlock> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.violetDeep.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: () => setState(() => open = !open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    widget.live ? Icons.bubble_chart_rounded : Icons.psychology_alt_rounded,
                    size: 17,
                    color: AppColors.violetSoft,
                  ).animate(target: widget.live ? 1 : 0, onPlay: (c) => c.repeat())
                      .rotate(duration: 2400.ms),
                  const SizedBox(width: 9),
                  Text(
                    widget.live ? l.thinking : l.thoughts,
                    style: TextStyle(
                        color: AppColors.violetSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                widget.reasoning,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            crossFadeState:
                open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}
