import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Service to call Supabase Edge Functions for TTS, Voice Clone, STT
class EdgeFunctionService {
  final SupabaseClient _client;

  EdgeFunctionService() : _client = Supabase.instance.client;

  String get _baseUrl => '${AppConfig.supabaseUrl}/functions/v1';
  String get _apiKey => AppConfig.supabaseAnonKey;
  String? get _accessToken => _client.auth.currentSession?.accessToken;

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $_accessToken',
    'apikey': _apiKey,
  };

  // ==================== TTS ====================

  /// Generate TTS audio
  /// Returns: { audio_url: String, credits_used: int, balance: int }
  Future<Map<String, dynamic>> generateTts({
    required String text,
    required String voiceId,
    double rate = 1.0,
    double pitch = 0.0,
  }) async {
    final response = await _client.functions.invoke(
      'tts-generate',
      body: {
        'text': text,
        'voice_id': voiceId,
        'rate': rate,
        'pitch': pitch,
      },
    );

    if (response.status != 200) {
      throw _parseError(response.data);
    }

    return response.data as Map<String, dynamic>;
  }

  // ==================== VOICE CLONE ====================

  /// Create a voice clone from audio sample
  /// Returns: { voice_id: String, name: String, credits_used: int, balance: int }
  Future<Map<String, dynamic>> createVoiceClone({
    required String name,
    required Uint8List audioBytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('$_baseUrl/voice-clone');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders);
    request.fields['name'] = name;
    request.files.add(http.MultipartFile.fromBytes(
      'audio', audioBytes, filename: fileName,
    ));

    final streamedResponse = await request.send();
    final body = await streamedResponse.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (streamedResponse.statusCode != 200) {
      throw _parseError(data);
    }
    return data;
  }

  // ==================== STT ====================

  /// Transcribe audio to text
  /// Returns: { text: String, duration_minutes: int, credits_used: int, balance: int }
  Future<Map<String, dynamic>> transcribeAudio({
    required Uint8List audioBytes,
    required String fileName,
    String language = 'vi',
  }) async {
    final uri = Uri.parse('$_baseUrl/stt-transcribe');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders);
    request.fields['language'] = language;
    request.files.add(http.MultipartFile.fromBytes(
      'audio', audioBytes, filename: fileName,
    ));

    final streamedResponse = await request.send();
    final body = await streamedResponse.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (streamedResponse.statusCode != 200) {
      throw _parseError(data);
    }
    return data;
  }

  // ==================== HELPERS ====================

  EdgeFunctionException _parseError(dynamic data) {
    if (data is Map<String, dynamic>) {
      return EdgeFunctionException(
        data['error']?.toString() ?? 'Unknown error',
        required: data['required'] as int?,
        balance: data['balance'] as int?,
      );
    }
    return EdgeFunctionException(data?.toString() ?? 'Unknown error');
  }
}

class EdgeFunctionException implements Exception {
  final String message;
  final int? required;
  final int? balance;

  EdgeFunctionException(this.message, {this.required, this.balance});

  bool get isInsufficientCredits => required != null;

  String get displayMessage {
    if (isInsufficientCredits) {
      return 'Không đủ xu! Cần $required xu, bạn có $balance xu.';
    }
    return message;
  }

  @override
  String toString() => 'EdgeFunctionException: $message';
}
