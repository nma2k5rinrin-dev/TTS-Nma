class Country {
  final String code;
  final String name;
  final String flag;

  const Country({required this.code, required this.name, required this.flag});

  static const List<Country> all = [
    Country(code: 'vi-VN', name: 'Vietnam', flag: '🇻🇳'),
    Country(code: 'en-US', name: 'Mỹ', flag: '🇺🇸'),
    Country(code: 'en-GB', name: 'Anh', flag: '🇬🇧'),
    Country(code: 'zh-CN', name: 'Trung Quốc', flag: '🇨🇳'),
    Country(code: 'zh-HK', name: 'Hồng Kông', flag: '🇭🇰'),
    Country(code: 'ja-JP', name: 'Nhật Bản', flag: '🇯🇵'),
    Country(code: 'ko-KR', name: 'Hàn Quốc', flag: '🇰🇷'),
    Country(code: 'hi-IN', name: 'Ấn Độ', flag: '🇮🇳'),
    Country(code: 'id-ID', name: 'Indonesia', flag: '🇮🇩'),
    Country(code: 'th-TH', name: 'Thái Lan', flag: '🇹🇭'),
    Country(code: 'fil-PH', name: 'Philippines', flag: '🇵🇭'),
    Country(code: 'ar-SA', name: 'Ả Rập', flag: '🇸🇦'),
    Country(code: 'fr-FR', name: 'Pháp', flag: '🇫🇷'),
    Country(code: 'de-DE', name: 'Đức', flag: '🇩🇪'),
    Country(code: 'es-ES', name: 'Tây Ban Nha', flag: '🇪🇸'),
    Country(code: 'pt-BR', name: 'Brazil', flag: '🇧🇷'),
    Country(code: 'ru-RU', name: 'Nga', flag: '🇷🇺'),
    Country(code: 'it-IT', name: 'Ý', flag: '🇮🇹'),
  ];
}

class VoiceModel {
  final String id; // Edge TTS voice name, e.g. "vi-VN-HoaiMyNeural"
  final String name;
  final String gender;
  final String language; // locale code, e.g. "vi-VN"
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

  /// Get voices for a given locale (e.g. "vi-VN")
  static List<VoiceModel> getVoicesForLanguage(String localeCode) {
    return _edgeTtsVoices.where((v) => v.language == localeCode).toList();
  }

  // ============================================================
  // Microsoft Edge TTS Neural Voices (FREE)
  // Full list: https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list
  // ============================================================
  static const List<VoiceModel> _edgeTtsVoices = [
    // ===== Vietnamese =====
    VoiceModel(id: 'vi-VN-HoaiMyNeural', name: 'Hoài My', gender: 'female', language: 'vi-VN'),
    VoiceModel(id: 'vi-VN-NamMinhNeural', name: 'Nam Minh', gender: 'male', language: 'vi-VN'),

    // ===== English US =====
    VoiceModel(id: 'en-US-JennyNeural', name: 'Jenny', gender: 'female', language: 'en-US'),
    VoiceModel(id: 'en-US-GuyNeural', name: 'Guy', gender: 'male', language: 'en-US'),
    VoiceModel(id: 'en-US-AriaNeural', name: 'Aria', gender: 'female', language: 'en-US'),
    VoiceModel(id: 'en-US-DavisNeural', name: 'Davis', gender: 'male', language: 'en-US'),
    VoiceModel(id: 'en-US-AmberNeural', name: 'Amber', gender: 'female', language: 'en-US'),
    VoiceModel(id: 'en-US-AnaNeural', name: 'Ana', gender: 'female', language: 'en-US'),
    VoiceModel(id: 'en-US-AshleyNeural', name: 'Ashley', gender: 'female', language: 'en-US'),
    VoiceModel(id: 'en-US-BrandonNeural', name: 'Brandon', gender: 'male', language: 'en-US'),
    VoiceModel(id: 'en-US-ChristopherNeural', name: 'Christopher', gender: 'male', language: 'en-US'),
    VoiceModel(id: 'en-US-CoraNeural', name: 'Cora', gender: 'female', language: 'en-US'),
    VoiceModel(id: 'en-US-ElizabethNeural', name: 'Elizabeth', gender: 'female', language: 'en-US'),
    VoiceModel(id: 'en-US-EricNeural', name: 'Eric', gender: 'male', language: 'en-US'),
    VoiceModel(id: 'en-US-JacobNeural', name: 'Jacob', gender: 'male', language: 'en-US'),
    VoiceModel(id: 'en-US-MichelleNeural', name: 'Michelle', gender: 'female', language: 'en-US'),
    VoiceModel(id: 'en-US-MonicaNeural', name: 'Monica', gender: 'female', language: 'en-US'),
    VoiceModel(id: 'en-US-RogerNeural', name: 'Roger', gender: 'male', language: 'en-US'),
    VoiceModel(id: 'en-US-SteffanNeural', name: 'Steffan', gender: 'male', language: 'en-US'),
    VoiceModel(id: 'en-US-TonyNeural', name: 'Tony', gender: 'male', language: 'en-US'),

    // ===== English UK =====
    VoiceModel(id: 'en-GB-SoniaNeural', name: 'Sonia', gender: 'female', language: 'en-GB'),
    VoiceModel(id: 'en-GB-RyanNeural', name: 'Ryan', gender: 'male', language: 'en-GB'),
    VoiceModel(id: 'en-GB-LibbyNeural', name: 'Libby', gender: 'female', language: 'en-GB'),
    VoiceModel(id: 'en-GB-ThomasNeural', name: 'Thomas', gender: 'male', language: 'en-GB'),
    VoiceModel(id: 'en-GB-MaisieNeural', name: 'Maisie', gender: 'female', language: 'en-GB'),

    // ===== Chinese Mandarin =====
    VoiceModel(id: 'zh-CN-XiaoxiaoNeural', name: 'Xiǎo Xiǎo', gender: 'female', language: 'zh-CN'),
    VoiceModel(id: 'zh-CN-YunxiNeural', name: 'Yún Xī', gender: 'male', language: 'zh-CN'),
    VoiceModel(id: 'zh-CN-YunjianNeural', name: 'Yún Jiàn', gender: 'male', language: 'zh-CN'),
    VoiceModel(id: 'zh-CN-XiaoyiNeural', name: 'Xiǎo Yì', gender: 'female', language: 'zh-CN'),
    VoiceModel(id: 'zh-CN-YunyangNeural', name: 'Yún Yáng', gender: 'male', language: 'zh-CN'),

    // ===== Chinese HK =====
    VoiceModel(id: 'zh-HK-HiuMaanNeural', name: 'Hiu Maan', gender: 'female', language: 'zh-HK'),
    VoiceModel(id: 'zh-HK-WanLungNeural', name: 'Wan Lung', gender: 'male', language: 'zh-HK'),
    VoiceModel(id: 'zh-HK-HiuGaaiNeural', name: 'Hiu Gaai', gender: 'female', language: 'zh-HK'),

    // ===== Japanese =====
    VoiceModel(id: 'ja-JP-NanamiNeural', name: 'Nanami', gender: 'female', language: 'ja-JP'),
    VoiceModel(id: 'ja-JP-KeitaNeural', name: 'Keita', gender: 'male', language: 'ja-JP'),
    VoiceModel(id: 'ja-JP-AoiNeural', name: 'Aoi', gender: 'female', language: 'ja-JP'),
    VoiceModel(id: 'ja-JP-DaichiNeural', name: 'Daichi', gender: 'male', language: 'ja-JP'),

    // ===== Korean =====
    VoiceModel(id: 'ko-KR-SunHiNeural', name: 'Sun Hi', gender: 'female', language: 'ko-KR'),
    VoiceModel(id: 'ko-KR-InJoonNeural', name: 'In Joon', gender: 'male', language: 'ko-KR'),
    VoiceModel(id: 'ko-KR-BongJinNeural', name: 'Bong Jin', gender: 'male', language: 'ko-KR'),
    VoiceModel(id: 'ko-KR-YuJinNeural', name: 'Yu Jin', gender: 'female', language: 'ko-KR'),

    // ===== Hindi =====
    VoiceModel(id: 'hi-IN-SwaraNeural', name: 'Swara', gender: 'female', language: 'hi-IN'),
    VoiceModel(id: 'hi-IN-MadhurNeural', name: 'Madhur', gender: 'male', language: 'hi-IN'),

    // ===== Indonesian =====
    VoiceModel(id: 'id-ID-GadisNeural', name: 'Gadis', gender: 'female', language: 'id-ID'),
    VoiceModel(id: 'id-ID-ArdiNeural', name: 'Ardi', gender: 'male', language: 'id-ID'),

    // ===== Thai =====
    VoiceModel(id: 'th-TH-PremwadeeNeural', name: 'Premwadee', gender: 'female', language: 'th-TH'),
    VoiceModel(id: 'th-TH-NiwatNeural', name: 'Niwat', gender: 'male', language: 'th-TH'),

    // ===== Filipino =====
    VoiceModel(id: 'fil-PH-BlessicaNeural', name: 'Blessica', gender: 'female', language: 'fil-PH'),
    VoiceModel(id: 'fil-PH-AngeloNeural', name: 'Angelo', gender: 'male', language: 'fil-PH'),

    // ===== Arabic =====
    VoiceModel(id: 'ar-SA-ZariyahNeural', name: 'Zariyah', gender: 'female', language: 'ar-SA'),
    VoiceModel(id: 'ar-SA-HamedNeural', name: 'Hamed', gender: 'male', language: 'ar-SA'),

    // ===== French =====
    VoiceModel(id: 'fr-FR-DeniseNeural', name: 'Denise', gender: 'female', language: 'fr-FR'),
    VoiceModel(id: 'fr-FR-HenriNeural', name: 'Henri', gender: 'male', language: 'fr-FR'),
    VoiceModel(id: 'fr-FR-EloiseNeural', name: 'Eloise', gender: 'female', language: 'fr-FR'),

    // ===== German =====
    VoiceModel(id: 'de-DE-KatjaNeural', name: 'Katja', gender: 'female', language: 'de-DE'),
    VoiceModel(id: 'de-DE-ConradNeural', name: 'Conrad', gender: 'male', language: 'de-DE'),
    VoiceModel(id: 'de-DE-AmalaNeural', name: 'Amala', gender: 'female', language: 'de-DE'),
    VoiceModel(id: 'de-DE-KillianNeural', name: 'Killian', gender: 'male', language: 'de-DE'),

    // ===== Spanish =====
    VoiceModel(id: 'es-ES-ElviraNeural', name: 'Elvira', gender: 'female', language: 'es-ES'),
    VoiceModel(id: 'es-ES-AlvaroNeural', name: 'Alvaro', gender: 'male', language: 'es-ES'),

    // ===== Portuguese Brazil =====
    VoiceModel(id: 'pt-BR-FranciscaNeural', name: 'Francisca', gender: 'female', language: 'pt-BR'),
    VoiceModel(id: 'pt-BR-AntonioNeural', name: 'Antonio', gender: 'male', language: 'pt-BR'),

    // ===== Russian =====
    VoiceModel(id: 'ru-RU-SvetlanaNeural', name: 'Svetlana', gender: 'female', language: 'ru-RU'),
    VoiceModel(id: 'ru-RU-DmitryNeural', name: 'Dmitry', gender: 'male', language: 'ru-RU'),

    // ===== Italian =====
    VoiceModel(id: 'it-IT-ElsaNeural', name: 'Elsa', gender: 'female', language: 'it-IT'),
    VoiceModel(id: 'it-IT-DiegoNeural', name: 'Diego', gender: 'male', language: 'it-IT'),
    VoiceModel(id: 'it-IT-IsabellaNeural', name: 'Isabella', gender: 'female', language: 'it-IT'),
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
