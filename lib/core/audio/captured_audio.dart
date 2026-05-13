import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class CapturedAudio {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final Duration? duration;
  final List<double> waveform;

  const CapturedAudio({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    this.duration,
    this.waveform = const [],
  });

  int get size => bytes.length;

  String get sizeLabel {
    if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${max(1, (size / 1024).round())} KB';
  }
}

class PcmWavEncoder {
  static Uint8List encode({
    required Uint8List pcmBytes,
    required int sampleRate,
    required int channels,
    int bitsPerSample = 16,
  }) {
    final bytes = BytesBuilder(copy: false);
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = pcmBytes.length;

    void writeString(String value) => bytes.add(ascii.encode(value));
    void writeUint16(int value) {
      final data = ByteData(2)..setUint16(0, value, Endian.little);
      bytes.add(data.buffer.asUint8List());
    }

    void writeUint32(int value) {
      final data = ByteData(4)..setUint32(0, value, Endian.little);
      bytes.add(data.buffer.asUint8List());
    }

    writeString('RIFF');
    writeUint32(36 + dataSize);
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16);
    writeUint16(1);
    writeUint16(channels);
    writeUint32(sampleRate);
    writeUint32(byteRate);
    writeUint16(blockAlign);
    writeUint16(bitsPerSample);
    writeString('data');
    writeUint32(dataSize);
    bytes.add(pcmBytes);

    return bytes.toBytes();
  }
}

class AudioLevelMapper {
  static double fromDbfs(double dbfs) {
    if (dbfs.isNaN || dbfs.isInfinite) return 0;
    return ((dbfs + 60) / 60).clamp(0, 1).toDouble();
  }

  static List<double> fromBytes(Uint8List bytes, {int samples = 48}) {
    if (bytes.isEmpty) return const [];

    final step = max(1, bytes.length ~/ samples);
    return List<double>.generate(samples, (index) {
      final start = min(index * step, bytes.length - 1);
      final end = min(start + step, bytes.length);
      var total = 0.0;

      for (var i = start; i < end; i++) {
        total += (bytes[i] - 128).abs() / 128;
      }

      final level = end == start ? 0.0 : total / (end - start);
      return level.clamp(0.06, 1).toDouble();
    });
  }

  static List<double> generated(String seed, {int samples = 48}) {
    final random = Random(seed.hashCode);
    return List<double>.generate(samples, (index) {
      final wave = (sin(index * 0.45) + 1) / 2;
      final jitter = random.nextDouble() * 0.35;
      return (0.12 + wave * 0.5 + jitter).clamp(0.08, 1).toDouble();
    });
  }
}
