import 'package:flutter/material.dart';

/// Minimal, dependency-free Markdown for Joi bubbles: **bold**, *italic*,
/// `code`, "- " / "* " bullets, "1. " numbered lists, "#" headings (bold).
/// Anything else is plain text. Selectable.
class JoiMarkdown extends StatelessWidget {
  const JoiMarkdown(this.text, {super.key});
  final String text;

  static final _inline = RegExp(
    r'\*\*(.+?)\*\*|__(.+?)__|`([^`]+)`|(?<![\*\w])\*(?!\s)([^*\n]+?)\*(?!\*)',
  );

  /// Exposed for tests.
  static TextSpan spans(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final lines = text.replaceAll('\r', '').split('\n');
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      var style = base;
      final h = RegExp(r'^\s*#{1,6}\s+').firstMatch(line);
      final b = RegExp(r'^(\s*)[-*•]\s+').firstMatch(line);
      final n = RegExp(r'^(\s*)(\d{1,3})[.)]\s+').firstMatch(line);
      if (h != null) {
        line = line.substring(h.end);
        style = base.copyWith(fontWeight: FontWeight.bold);
      } else if (b != null) {
        spans.add(TextSpan(text: '${b.group(1)}  •  ', style: base));
        line = line.substring(b.end);
      } else if (n != null) {
        spans.add(
          TextSpan(
            text: '${n.group(1)}  ${n.group(2)}. ',
            style: base.copyWith(fontWeight: FontWeight.w600),
          ),
        );
        line = line.substring(n.end);
      }
      spans.addAll(_inlineSpans(line, style));
      if (i < lines.length - 1) spans.add(TextSpan(text: '\n', style: base));
    }
    return TextSpan(style: base, children: spans);
  }

  static List<InlineSpan> _inlineSpans(String s, TextStyle style) {
    final out = <InlineSpan>[];
    var pos = 0;
    for (final m in _inline.allMatches(s)) {
      if (m.start > pos) {
        out.add(TextSpan(text: s.substring(pos, m.start), style: style));
      }
      if (m.group(1) != null || m.group(2) != null) {
        out.add(
          TextSpan(
            text: m.group(1) ?? m.group(2),
            style: style.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else if (m.group(3) != null) {
        out.add(
          TextSpan(
            text: m.group(3),
            style: style.copyWith(fontFamily: 'monospace'),
          ),
        );
      } else {
        out.add(
          TextSpan(
            text: m.group(4),
            style: style.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      }
      pos = m.end;
    }
    if (pos < s.length) out.add(TextSpan(text: s.substring(pos), style: style));
    return out;
  }

  /// Plain text (for TTS / copying): markers removed.
  static String plain(String text) =>
      spans(text, const TextStyle()).toPlainText();

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    return SelectableText.rich(JoiMarkdown.spans(text, base));
  }
}
