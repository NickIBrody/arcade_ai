import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../../models/chat.dart';
import 'thinking_block.dart';
import 'code_block.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final L l;
  final bool showReasoning;
  const MessageBubble(
      {super.key,
      required this.msg,
      required this.l,
      this.showReasoning = true});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == Role.user;
    if (!isUser && msg.compare) return _comparison(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.84),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser && showReasoning && msg.hasReasoning)
              ThinkingBlock(reasoning: msg.reasoning, live: msg.streaming, l: l),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.violetGradient : null,
                color: isUser ? null : AppColors.surfaceHigh.withValues(alpha: 0.85),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadii.md),
                  topRight: const Radius.circular(AppRadii.md),
                  bottomLeft: Radius.circular(isUser ? AppRadii.md : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppRadii.md),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.images.isNotEmpty) _images(),
                  if (msg.error != null)
                    Text('${l.errPrefix}: ${msg.error}',
                        style: const TextStyle(color: AppColors.danger))
                  else if (isUser)
                    Text(msg.text,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15.5, height: 1.45))
                  else if (msg.text.isEmpty && msg.streaming)
                    const _Dots()
                  else
                    MarkdownBody(
                      data: msg.text,
                      styleSheet: _md(context),
                      selectable: true,
                      builders: {'pre': CodeBlockBuilder(l)},
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(
        begin: 0.12, end: 0, duration: 280.ms, curve: Curves.easeOutCubic);
  }

  Widget _images() => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: msg.images
              .map((a) => ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    child: Image.memory(base64Decode(a.base64),
                        width: 150, height: 150, fit: BoxFit.cover),
                  ))
              .toList(),
        ),
      );

  Widget _comparison(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _candidateCard(context, msg.modelA, msg.text, msg.reasoning,
              msg.streaming, msg.error, true),
          const SizedBox(height: 10),
          _candidateCard(context, msg.modelB, msg.altText, msg.altReasoning,
              msg.altStreaming, msg.altError, false),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms);
  }

  Widget _candidateCard(BuildContext context, String model, String text,
      String reasoning, bool streaming, String? error, bool isA) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance_rounded,
                  size: 14, color: AppColors.violetSoft),
              const SizedBox(width: 6),
              Expanded(
                child: Text(model.isEmpty ? '—' : model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (showReasoning && reasoning.trim().isNotEmpty)
            ThinkingBlock(reasoning: reasoning, live: streaming, l: l),
          if (error != null)
            Text('${l.errPrefix}: $error',
                style: const TextStyle(color: AppColors.danger))
          else if (text.isEmpty && streaming)
            const _Dots()
          else
            MarkdownBody(
              data: text,
              styleSheet: _md(context),
              selectable: true,
              builders: {'pre': CodeBlockBuilder(l)},
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: streaming
                  ? null
                  : () => context.read<AppState>().pickComparison(msg, isA),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text(l.keepThis),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.violetSoft,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _md(BuildContext context) => MarkdownStyleSheet(
        p: const TextStyle(
            color: AppColors.textPrimary, fontSize: 15.5, height: 1.55),
        code: GoogleFonts.jetBrainsMono(
            fontSize: 13.5, color: AppColors.violetSoft, backgroundColor: Colors.transparent),
        codeblockDecoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: AppColors.stroke),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          border: Border(
              left: BorderSide(color: AppColors.violet, width: 3)),
        ),
        a: const TextStyle(color: AppColors.violetSoft),
        strong: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      );
}

class _Dots extends StatelessWidget {
  const _Dots();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 6),
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
              color: AppColors.violetSoft, shape: BoxShape.circle),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(duration: 400.ms, delay: (i * 160).ms)
            .then()
            .fadeOut(duration: 400.ms);
      }),
    );
  }
}
