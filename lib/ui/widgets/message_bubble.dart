import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

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
