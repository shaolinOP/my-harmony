import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/ui/player/components/lyrics_switch.dart';
import '/ui/widgets/advanced_lyrics_widget.dart';
import '/ui/widgets/common_dialog_widget.dart';
import '/ui/widgets/lyrics_menu.dart';
import '/ui/player/player_controller.dart';

class LyricsDialog extends StatelessWidget {
  const LyricsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    
    return CommonDialog(
      maxWidth: 700,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0, top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const LyricsSwitch(),
                Obx(() {
                  final currentSong = playerController.currentSong.value;
                  final lyricsEntity = playerController.currentLyricsEntity.value;
                  
                  if (currentSong == null) return const SizedBox.shrink();
                  
                  return IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => LyricsMenu(
                          mediaItem: currentSong,
                          lyricsEntity: lyricsEntity,
                          onDismiss: () => Navigator.pop(context),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
          const Expanded(
            child: AdvancedLyricsWidget(
              padding: EdgeInsets.symmetric(vertical: 40),
              showSelectionControls: true,
            ),
          ),
        ],
      ),
    );
  }
}
