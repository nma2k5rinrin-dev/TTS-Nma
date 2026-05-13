import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../audio/captured_audio.dart';
import '../theme/app_colors.dart';
import 'waveform_view.dart';

class AudioPlayerCard extends StatefulWidget {
  final String? audioUrl;
  final Uint8List? audioBytes;
  final String title;
  final String? fileName;
  final String? subtitle;
  final String? mimeType;
  final List<double> waveform;
  final Color accentColor;
  final Gradient? gradient;
  final int? creditsUsed;
  final VoidCallback? onClose;

  const AudioPlayerCard({
    super.key,
    this.audioUrl,
    this.audioBytes,
    this.title = 'Kết quả audio',
    this.fileName,
    this.subtitle,
    this.mimeType,
    this.waveform = const [],
    this.accentColor = AppColors.ttsGreen,
    this.gradient,
    this.creditsUsed,
    this.onClose,
  }) : assert(audioUrl != null || audioBytes != null);

  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant AudioPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl ||
        oldWidget.audioBytes != widget.audioBytes) {
      _player.stop();
      setState(() {
        _duration = Duration.zero;
        _position = Duration.zero;
        _playerState = PlayerState.stopped;
      });
    }
  }

  void _initPlayer() {
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
    _player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    final waveform = widget.waveform.isNotEmpty
        ? widget.waveform
        : AudioLevelMapper.generated(widget.audioUrl ?? widget.fileName ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
            widget.gradient ??
            LinearGradient(
              colors: [
                widget.accentColor.withValues(alpha: 0.15),
                AppColors.primary.withValues(alpha: 0.08),
              ],
            ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.graphic_eq, color: widget.accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.creditsUsed != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.coinGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-${widget.creditsUsed} xu',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.coinGold,
                    ),
                  ),
                ),
              if (widget.onClose != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          if (widget.subtitle != null || widget.fileName != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle ?? widget.fileName!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          WaveformView(
            levels: waveform,
            color: widget.accentColor,
            progress: progress,
            isActive: _playerState == PlayerState.playing,
            height: 46,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accentColor,
                  ),
                  child: Icon(
                    _playerState == PlayerState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: widget.accentColor,
                        inactiveTrackColor: widget.accentColor.withValues(
                          alpha: 0.2,
                        ),
                        thumbColor: widget.accentColor,
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        value: progress.clamp(0, 1).toDouble(),
                        onChanged: _duration.inMilliseconds <= 0
                            ? null
                            : (value) {
                                final position = Duration(
                                  milliseconds:
                                      (value * _duration.inMilliseconds)
                                          .toInt(),
                                );
                                _player.seek(position);
                              },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.download,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: _download,
                tooltip: 'Tải xuống',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlay() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
      return;
    }

    if (widget.audioBytes != null) {
      await _player.play(
        BytesSource(widget.audioBytes!, mimeType: widget.mimeType),
      );
    } else {
      await _player.play(
        UrlSource(widget.audioUrl!, mimeType: widget.mimeType),
      );
    }
  }

  Future<void> _download() async {
    if (widget.audioBytes != null) {
      await FilePicker.saveFile(
        fileName: widget.fileName ?? 'audio.wav',
        bytes: widget.audioBytes,
      );
      return;
    }

    final url = Uri.tryParse(widget.audioUrl ?? '');
    if (url != null) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
