import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';

import '../audio/captured_audio.dart';
import '../theme/app_colors.dart';
import 'app_toast.dart';
import 'audio_player_card.dart';
import 'waveform_view.dart';

class AudioInputPanel extends StatefulWidget {
  final String title;
  final String subtitle;
  final String pickLabel;
  final String recordLabel;
  final Color accentColor;
  final int maxSeconds;
  final ValueChanged<CapturedAudio?> onChanged;
  final List<String> allowedExtensions;

  const AudioInputPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pickLabel,
    required this.recordLabel,
    required this.accentColor,
    required this.onChanged,
    this.maxSeconds = 60,
    this.allowedExtensions = const ['wav', 'mp3', 'm4a', 'flac', 'ogg', 'webm'],
  });

  @override
  State<AudioInputPanel> createState() => _AudioInputPanelState();
}

class _AudioInputPanelState extends State<AudioInputPanel> {
  static const int _sampleRate = 16000;
  static const int _channels = 1;

  final AudioRecorder _recorder = AudioRecorder();
  final List<Uint8List> _pcmChunks = [];
  final List<double> _levels = [];

  StreamSubscription<Uint8List>? _recordSub;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Completer<void>? _recordDone;
  Timer? _timer;

  CapturedAudio? _audio;
  bool _isRecording = false;
  bool _isStopping = false;
  Duration _recordDuration = Duration.zero;
  DateTime? _recordStartedAt;

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_recordSub?.cancel());
    unawaited(_amplitudeSub?.cancel());
    unawaited(_recorder.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                _isRecording ? Icons.mic : Icons.cloud_upload_outlined,
                color: widget.accentColor.withValues(alpha: 0.85),
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              WaveformView(
                levels: _isRecording ? _levels : (_audio?.waveform ?? const []),
                color: widget.accentColor,
                isActive: _isRecording,
                height: 44,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isRecording ? null : _pickFile,
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: Text(
                      widget.pickLabel,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isStopping ? null : _toggleRecording,
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 18,
                      color: widget.accentColor,
                    ),
                    label: Text(
                      _isRecording
                          ? 'Dừng (${_formatDuration(_recordDuration)})'
                          : widget.recordLabel,
                      style: GoogleFonts.inter(
                        color: widget.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: widget.accentColor.withValues(alpha: 0.55),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_audio != null) ...[
          const SizedBox(height: 14),
          AudioPlayerCard(
            audioBytes: _audio!.bytes,
            title: 'Audio đầu vào',
            fileName: _audio!.fileName,
            subtitle: '${_audio!.fileName} - ${_audio!.sizeLabel}',
            mimeType: _audio!.mimeType,
            waveform: _audio!.waveform,
            accentColor: widget.accentColor,
            onClose: _clearAudio,
          ),
        ],
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        _showMessage('Không đọc được file audio này.');
        return;
      }

      _setAudio(
        CapturedAudio(
          bytes: bytes,
          fileName: file.name,
          mimeType: _mimeTypeFor(file.name),
          waveform: AudioLevelMapper.fromBytes(bytes),
        ),
      );
    } catch (error) {
      _showMessage('Lỗi chọn file: $error');
    }
  }

  Future<void> _toggleRecording() {
    if (_isRecording) {
      return _stopRecording();
    }
    return _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _showMessage('Ứng dụng chưa có quyền dùng microphone.');
        return;
      }

      _pcmChunks.clear();
      _levels.clear();
      _recordDone = Completer<void>();

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: _channels,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );

      _recordSub = stream.listen(
        (chunk) => _pcmChunks.add(Uint8List.fromList(chunk)),
        onDone: () {
          if (!(_recordDone?.isCompleted ?? true)) {
            _recordDone?.complete();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!(_recordDone?.isCompleted ?? true)) {
            _recordDone?.completeError(error, stackTrace);
          }
        },
      );

      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amplitude) {
            if (!mounted) return;
            setState(() {
              _levels.add(AudioLevelMapper.fromDbfs(amplitude.current));
              if (_levels.length > 64) {
                _levels.removeAt(0);
              }
            });
          });

      _recordStartedAt = DateTime.now();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!mounted || _recordStartedAt == null) return;
        final duration = DateTime.now().difference(_recordStartedAt!);
        setState(() => _recordDuration = duration);
        if (duration.inSeconds >= widget.maxSeconds && !_isStopping) {
          unawaited(_stopRecording());
        }
      });

      setState(() {
        _audio = null;
        _recordDuration = Duration.zero;
        _isRecording = true;
      });
      widget.onChanged(null);
    } catch (error) {
      _showMessage('Không bắt đầu ghi âm được: $error');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _isStopping) return;

    setState(() => _isStopping = true);
    _timer?.cancel();

    try {
      final done = _recordDone;
      await _recorder.stop();
      await done?.future.timeout(const Duration(seconds: 2), onTimeout: () {});
      await _recordSub?.cancel();
      await _amplitudeSub?.cancel();

      final pcmBytes = _combineChunks(_pcmChunks);
      if (pcmBytes.isEmpty) {
        _showMessage('Bản ghi đang trống.');
        return;
      }

      final wavBytes = PcmWavEncoder.encode(
        pcmBytes: pcmBytes,
        sampleRate: _sampleRate,
        channels: _channels,
      );

      _setAudio(
        CapturedAudio(
          bytes: wavBytes,
          fileName: 'recording_${DateTime.now().millisecondsSinceEpoch}.wav',
          mimeType: 'audio/wav',
          duration: _recordDuration,
          waveform: _levels.isEmpty
              ? AudioLevelMapper.fromBytes(wavBytes)
              : List<double>.from(_levels),
        ),
      );
    } catch (error) {
      _showMessage('Không dừng ghi âm được: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isStopping = false;
          _recordStartedAt = null;
        });
      }
    }
  }

  Uint8List _combineChunks(List<Uint8List> chunks) {
    final totalLength = chunks.fold<int>(
      0,
      (total, chunk) => total + chunk.length,
    );
    final bytes = Uint8List(totalLength);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setAll(offset, chunk);
      offset += chunk.length;
    }
    return bytes;
  }

  void _setAudio(CapturedAudio audio) {
    setState(() => _audio = audio);
    widget.onChanged(audio);
  }

  void _clearAudio() {
    setState(() => _audio = null);
    widget.onChanged(null);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    AppToast.error(context, message);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _mimeTypeFor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'flac' => 'audio/flac',
      'ogg' => 'audio/ogg',
      'webm' => 'audio/webm',
      _ => 'audio/wav',
    };
  }
}
