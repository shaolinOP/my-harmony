import 'package:flutter/material.dart';
import '../../widgets/advanced_lyrics_widget.dart';

class LyricsWidget extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  const LyricsWidget({super.key, required this.padding});

  @override
  Widget build(BuildContext context) {
    return AdvancedLyricsWidget(
      padding: padding,
      showSelectionControls: false,
    );
  }
}
