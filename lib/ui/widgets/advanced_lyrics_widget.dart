import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:get/get.dart';
import '../../services/lyrics/lyrics_utils.dart';
import '../player/player_controller.dart';
import 'loader.dart';

class AdvancedLyricsWidget extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  final bool showSelectionControls;
  
  const AdvancedLyricsWidget({
    super.key, 
    required this.padding,
    this.showSelectionControls = false,
  });

  @override
  State<AdvancedLyricsWidget> createState() => _AdvancedLyricsWidgetState();
}

class _AdvancedLyricsWidgetState extends State<AdvancedLyricsWidget> {
  final Set<int> _selectedLines = <int>{};
  bool _isSelectionMode = false;
  final int _maxSelectionLimit = 5;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    
    return Obx(() {
      if (playerController.isLyricsLoading.isTrue) {
        return const Center(child: LoadingIndicator());
      }
      
      final lyricsData = playerController.lyrics;
      final isPlainMode = playerController.lyricsMode.toInt() == 1;
      
      if (isPlainMode) {
        return _buildPlainLyrics(context, playerController, lyricsData);
      } else {
        return _buildSyncedLyrics(context, playerController, lyricsData);
      }
    });
  }
  
  Widget _buildPlainLyrics(
    BuildContext context, 
    PlayerController playerController, 
    Map<String, dynamic> lyricsData
  ) {
    final plainLyrics = lyricsData["plainLyrics"] as String? ?? "";
    
    if (plainLyrics == "NA" || plainLyrics.isEmpty) {
      return Center(
        child: Text(
          "lyricsNotAvailable".tr,
          style: _getTextStyle(context, playerController),
        ),
      );
    }
    
    if (widget.showSelectionControls) {
      return _buildSelectablePlainLyrics(context, playerController, plainLyrics);
    }
    
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: widget.padding,
        child: SelectableText(
          plainLyrics,
          textAlign: TextAlign.center,
          style: _getTextStyle(context, playerController),
        ),
      ),
    );
  }
  
  Widget _buildSelectablePlainLyrics(
    BuildContext context, 
    PlayerController playerController, 
    String plainLyrics
  ) {
    final lines = plainLyrics.split('\n');
    
    return Column(
      children: [
        if (_isSelectionMode) _buildSelectionControls(context, lines),
        Expanded(
          child: ListView.builder(
            padding: widget.padding,
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              final isSelected = _selectedLines.contains(index);
              
              return GestureDetector(
                onTap: () => _toggleLineSelection(index),
                onLongPress: () => _enterSelectionMode(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    style: _getTextStyle(context, playerController),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSyncedLyrics(
    BuildContext context, 
    PlayerController playerController, 
    Map<String, dynamic> lyricsData
  ) {
    final syncedLyrics = lyricsData['synced'] as String? ?? "";
    
    if (syncedLyrics.isEmpty) {
      return Center(
        child: Text(
          "syncedLyricsNotAvailable".tr,
          style: _getTextStyle(context, playerController),
        ),
      );
    }
    
    if (widget.showSelectionControls) {
      return _buildSelectableSyncedLyrics(context, playerController, syncedLyrics);
    }
    
    return IgnorePointer(
      child: LyricsReader(
        padding: const EdgeInsets.only(left: 5, right: 5),
        lyricUi: playerController.lyricUi,
        position: playerController.progressBarStatus.value.current.inMilliseconds,
        model: LyricsModelBuilder.create()
            .bindLyricToMain(syncedLyrics)
            .getModel(),
        emptyBuilder: () => Center(
          child: Text(
            "syncedLyricsNotAvailable".tr,
            style: _getTextStyle(context, playerController),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSelectableSyncedLyrics(
    BuildContext context, 
    PlayerController playerController, 
    String syncedLyrics
  ) {
    final entries = LyricsUtils.parseLyrics(syncedLyrics);
    
    return Column(
      children: [
        if (_isSelectionMode) _buildSelectionControls(context, entries.map((e) => e.text).toList()),
        Expanded(
          child: ListView.builder(
            padding: widget.padding,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isSelected = _selectedLines.contains(index);
              final isCurrent = _isCurrentLine(playerController, entries, index);
              
              return GestureDetector(
                onTap: () => _toggleLineSelection(index),
                onLongPress: () => _enterSelectionMode(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.3)
                        : isCurrent
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        entry.text,
                        textAlign: TextAlign.center,
                        style: _getTextStyle(context, playerController).copyWith(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (entry.romanizedText != null)
                        Text(
                          entry.romanizedText!,
                          textAlign: TextAlign.center,
                          style: _getTextStyle(context, playerController).copyWith(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSelectionControls(BuildContext context, List<String> lines) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _selectedLines.isEmpty ? null : () => _copySelectedLines(lines),
            icon: const Icon(Icons.copy),
            label: Text('Copy (${_selectedLines.length})'),
          ),
          ElevatedButton.icon(
            onPressed: _selectedLines.isEmpty ? null : () => _shareSelectedLines(lines),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
          ElevatedButton(
            onPressed: _exitSelectionMode,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  bool _isCurrentLine(PlayerController playerController, List<LyricsEntry> entries, int index) {
    final currentPosition = playerController.progressBarStatus.value.current.inMilliseconds;
    final currentIndex = LyricsUtils.findCurrentLineIndex(entries, currentPosition);
    return currentIndex == index;
  }
  
  void _toggleLineSelection(int index) {
    if (!_isSelectionMode) return;
    
    setState(() {
      if (_selectedLines.contains(index)) {
        _selectedLines.remove(index);
      } else if (_selectedLines.length < _maxSelectionLimit) {
        _selectedLines.add(index);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum $_maxSelectionLimit lines can be selected'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }
  
  void _enterSelectionMode(int index) {
    setState(() {
      _isSelectionMode = true;
      _selectedLines.clear();
      _selectedLines.add(index);
    });
  }
  
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedLines.clear();
    });
  }
  
  void _copySelectedLines(List<String> lines) {
    final selectedText = _selectedLines
        .map((index) => lines[index])
        .join('\n');
    
    Clipboard.setData(ClipboardData(text: selectedText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lyrics copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
    
    _exitSelectionMode();
  }
  
  void _shareSelectedLines(List<String> lines) {
    final selectedText = _selectedLines
        .map((index) => lines[index])
        .join('\n');
    
    // TODO: Implement sharing functionality
    // This would typically use share_plus package
    
    _exitSelectionMode();
  }
  
  TextStyle _getTextStyle(BuildContext context, PlayerController playerController) {
    return playerController.isDesktopLyricsDialogOpen
        ? Theme.of(context).textTheme.titleMedium!
        : Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white);
  }
}