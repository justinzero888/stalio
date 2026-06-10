import 'package:intl/intl.dart';
import '../../models/entry.dart';

class ShareFormat {
  static String toPlainText(List<Entry> entries, bool isZh) {
    final sb = StringBuffer();
    for (final e in entries) {
      sb.writeln('${_fmt(e.createdAt, isZh)}');
      sb.writeln(e.content);
      sb.writeln('---');
    }
    return sb.toString();
  }

  static String toMarkdown(List<Entry> entries, bool isZh) {
    final sb = StringBuffer();
    sb.writeln('# Stalio Notes');
    sb.writeln();
    for (final e in entries) {
      sb.writeln('## ${_fmt(e.createdAt, isZh)}');
      if (e.emotion != null) sb.writeln('*Mood: ${e.emotion}*  ');
      sb.writeln();
      sb.writeln(e.content);
      sb.writeln();
      sb.writeln('---');
      sb.writeln();
    }
    return sb.toString();
  }

  static String toRichText(List<Entry> entries, bool isZh) {
    final sb = StringBuffer();
    sb.writeln('STALIO NOTES');
    sb.writeln('═════════════');
    sb.writeln();
    for (final e in entries) {
      sb.writeln('┌─ ${_fmt(e.createdAt, isZh)}');
      if (e.emotion != null) sb.writeln('│ Mood: ${e.emotion}');
      sb.writeln('│');
      for (final line in e.content.split('\n')) {
        sb.writeln('│ $line');
      }
      sb.writeln('└${'─' * 40}');
      sb.writeln();
    }
    return sb.toString();
  }

  static String _fmt(DateTime dt, bool isZh) {
    if (isZh) return DateFormat('yyyy年M月d日 HH:mm').format(dt);
    return DateFormat('MMM d, y HH:mm').format(dt);
  }
}
