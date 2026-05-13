import '../../../core/services/edge_function_service.dart';

class TtsRepository {
  final EdgeFunctionService _edgeService;

  TtsRepository({EdgeFunctionService? edgeService})
    : _edgeService = edgeService ?? EdgeFunctionService();

  /// Generate TTS audio from text
  /// Returns audio URL and credit info
  Future<TtsResult> generate({
    required String text,
    required String voiceId,
    double rate = 1.0,
    double pitch = 0.0,
  }) async {
    final result = await _edgeService.generateTts(
      text: text,
      voiceId: voiceId,
      rate: rate,
      pitch: pitch,
    );

    return TtsResult(
      audioUrl: result['audio_url'] as String,
      creditsUsed: (result['credits_used'] as num?)?.toInt() ?? 0,
      balance: (result['balance'] as num?)?.toInt() ?? 0,
      provider: result['provider']?.toString(),
    );
  }
}

class TtsResult {
  final String audioUrl;
  final int creditsUsed;
  final int balance;
  final String? provider;

  const TtsResult({
    required this.audioUrl,
    required this.creditsUsed,
    required this.balance,
    this.provider,
  });
}
