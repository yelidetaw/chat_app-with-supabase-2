import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final VoidCallback onPlay;
  final bool isDark;

  const AudioPlayerWidget({
    Key? key,
    required this.audioUrl,
    required this.onPlay,
    this.isDark = false,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _audioPlayer.setUrl(widget.audioUrl);
      
      _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration ?? Duration.zero;
          });
        }
      });
      
      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
      
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _audioPlayer.seek(Duration.zero);
              _isPlaying = false;
            }
          });
        }
      });
    } catch (e) {
      print('Error initializing audio player: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: widget.isDark 
            ? Colors.white.withOpacity(0.1) 
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _isLoading 
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isDark ? Colors.white : Theme.of(context).primaryColor,
                ),
              ),
            )
          : Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: textColor,
                  ),
                  onPressed: () {
                    if (_isPlaying) {
                      _audioPlayer.pause();
                    } else {
                      widget.onPlay();
                      _audioPlayer.play();
                    }
                  },
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      thumbColor: widget.isDark
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      activeTrackColor: widget.isDark
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(context).primaryColor.withOpacity(0.7),
                      inactiveTrackColor: widget.isDark
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                    ),
                    child: Slider(
                      min: 0.0,
                      max: _duration.inMilliseconds.toDouble(),
                      value: _position.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        final position = Duration(milliseconds: value.toInt());
                        _audioPlayer.seek(position);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}