import 'dart:async';
import 'package:app_ui/app_ui.dart';

const _charDuration = Duration(milliseconds: 30);

/// {@template typewriter_text}
/// Reveals [text] one character at a time, then invokes [onCompleted].
///
/// The reveal cadence is fixed; there is no skip interaction. The widget
/// is single-shot — it animates from the moment it mounts and never
/// restarts. Use a `ValueKey` tied to the message identifier so a new
/// run of the conversation creates a fresh state.
/// {@endtemplate}
class TypewriterText extends StatefulWidget {
  /// {@macro typewriter_text}
  const TypewriterText({
    required this.text,
    required this.onCompleted,
    this.style,
    super.key,
  });

  /// The full text to reveal.
  final String text;

  /// Called once when [text] has been fully revealed.
  final VoidCallback onCompleted;

  /// Optional [TextStyle] applied to the rendered [Text].
  final TextStyle? style;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _visibleChars = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_charDuration, _tick);
  }

  void _tick(Timer timer) {
    if (_visibleChars >= widget.text.length) {
      timer.cancel();
      _timer = null;
      widget.onCompleted();
      return;
    }
    setState(() => _visibleChars++);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text.substring(0, _visibleChars),
      style: widget.style,
    );
  }
}
