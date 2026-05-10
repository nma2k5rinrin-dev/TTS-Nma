class Country {
  final String code;
  final String name;
  final String flag;

  const Country({required this.code, required this.name, required this.flag});

  static const List<Country> all = [
    Country(code: 'vi', name: 'Vietnam', flag: '🇻🇳'),
    Country(code: 'zh', name: 'China', flag: '🇨🇳'),
    Country(code: 'zh-HK', name: 'Hong Kong', flag: '🇭🇰'),
    Country(code: 'hi', name: 'India', flag: '🇮🇳'),
    Country(code: 'id', name: 'Indonesia', flag: '🇮🇩'),
    Country(code: 'ja', name: 'Japan', flag: '🇯🇵'),
    Country(code: 'fil', name: 'Philippines', flag: '🇵🇭'),
    Country(code: 'ar', name: 'Saudi Arabia', flag: '🇸🇦'),
    Country(code: 'en', name: 'English', flag: '🇺🇸'),
    Country(code: 'ko', name: 'Korea', flag: '🇰🇷'),
    Country(code: 'th', name: 'Thailand', flag: '🇹🇭'),
    Country(code: 'fr', name: 'France', flag: '🇫🇷'),
    Country(code: 'de', name: 'Germany', flag: '🇩🇪'),
    Country(code: 'es', name: 'Spain', flag: '🇪🇸'),
    Country(code: 'pt', name: 'Portugal', flag: '🇵🇹'),
    Country(code: 'ru', name: 'Russia', flag: '🇷🇺'),
  ];
}

class VoiceModel {
  final String id;
  final String name;
  final String gender;
  final String language;
  final String? preview;
  final bool isPremium;

  const VoiceModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.language,
    this.preview,
    this.isPremium = false,
  });

  String get genderIcon => gender == 'male' ? '👨' : '👩';
  String get genderColor => gender == 'male' ? 'blue' : 'pink';

  // Demo voices per language
  static List<VoiceModel> getVoicesForLanguage(String langCode) {
    return _demoVoices.where((v) => v.language == langCode).toList();
  }

  static const List<VoiceModel> _demoVoices = [
    // Vietnamese
    VoiceModel(id: 'vi-m-1', name: 'Trần Sơn', gender: 'male', language: 'vi'),
    VoiceModel(id: 'vi-m-2', name: 'Đông Tùng Duy', gender: 'male', language: 'vi'),
    VoiceModel(id: 'vi-f-1', name: 'Quang Minh', gender: 'male', language: 'vi'),
    VoiceModel(id: 'vi-f-2', name: 'Minh Trung', gender: 'male', language: 'vi'),
    VoiceModel(id: 'vi-f-3', name: 'Nguyễn Ngôn', gender: 'female', language: 'vi'),
    VoiceModel(id: 'vi-f-4', name: 'Nguyễn Huyền Trang', gender: 'female', language: 'vi'),
    // English
    VoiceModel(id: 'en-m-1', name: 'James', gender: 'male', language: 'en'),
    VoiceModel(id: 'en-m-2', name: 'Michael', gender: 'male', language: 'en'),
    VoiceModel(id: 'en-f-1', name: 'Sarah', gender: 'female', language: 'en'),
    VoiceModel(id: 'en-f-2', name: 'Emily', gender: 'female', language: 'en'),
    // Japanese
    VoiceModel(id: 'ja-m-1', name: 'Takeshi', gender: 'male', language: 'ja'),
    VoiceModel(id: 'ja-f-1', name: 'Sakura', gender: 'female', language: 'ja'),
    // Korean
    VoiceModel(id: 'ko-m-1', name: 'Minho', gender: 'male', language: 'ko'),
    VoiceModel(id: 'ko-f-1', name: 'Jisoo', gender: 'female', language: 'ko'),
    // Chinese
    VoiceModel(id: 'zh-m-1', name: 'Wei', gender: 'male', language: 'zh'),
    VoiceModel(id: 'zh-f-1', name: 'Xiaomei', gender: 'female', language: 'zh'),
    // Others - one each as demo
    VoiceModel(id: 'hi-m-1', name: 'Arjun', gender: 'male', language: 'hi'),
    VoiceModel(id: 'id-f-1', name: 'Sari', gender: 'female', language: 'id'),
    VoiceModel(id: 'th-f-1', name: 'Ploy', gender: 'female', language: 'th'),
    VoiceModel(id: 'fr-m-1', name: 'Pierre', gender: 'male', language: 'fr'),
    VoiceModel(id: 'de-m-1', name: 'Hans', gender: 'male', language: 'de'),
    VoiceModel(id: 'es-f-1', name: 'Maria', gender: 'female', language: 'es'),
    VoiceModel(id: 'pt-m-1', name: 'João', gender: 'male', language: 'pt'),
    VoiceModel(id: 'ru-f-1', name: 'Natasha', gender: 'female', language: 'ru'),
    VoiceModel(id: 'ar-m-1', name: 'Ahmed', gender: 'male', language: 'ar'),
    VoiceModel(id: 'fil-f-1', name: 'Maria', gender: 'female', language: 'fil'),
    VoiceModel(id: 'zh-HK-f-1', name: 'Wing', gender: 'female', language: 'zh-HK'),
  ];
}

class TtsRequest {
  final String text;
  final String voiceId;
  final double rate;
  final double pitch;

  const TtsRequest({
    required this.text,
    required this.voiceId,
    this.rate = 1.0,
    this.pitch = 0.0,
  });

  int get charCount => text.length;
}
