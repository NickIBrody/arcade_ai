import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;

import '../../core/theme.dart';
import '../../l10n/strings.dart';

/// Renders fenced code blocks as a framed panel with a language label and a
/// copy button, instead of the plain markdown code box.
class CodeBlockBuilder extends MarkdownElementBuilder {
  final L l;
  CodeBlockBuilder(this.l);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var text = element.textContent;
    if (text.endsWith('\n')) text = text.substring(0, text.length - 1);

    String lang = '';
    final children = element.children;
    if (children != null && children.isNotEmpty) {
      final code = children.first;
      if (code is md.Element) {
        final cls = code.attributes['class'];
        if (cls != null && cls.startsWith('language-')) {
          lang = cls.substring('language-'.length);
        }
      }
    }
    return CodeBlock(code: text, language: lang, l: l);
  }
}

class CodeBlock extends StatefulWidget {
  final String code;
  final String language;
  final L l;
  const CodeBlock(
      {super.key, required this.code, required this.language, required this.l});

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.only(left: 14, right: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.stroke)),
            ),
            child: Row(
              children: [
                Text(
                  widget.language.isEmpty ? 'code' : widget.language,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5, color: AppColors.textFaint),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _copy,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        _copied ? AppColors.success : AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                      _copied
                          ? Icons.check_rounded
                          : Icons.copy_rounded,
                      size: 15),
                  label: Text(_copied ? widget.l.copied : widget.l.copy,
                      style: const TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              widget.code,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
