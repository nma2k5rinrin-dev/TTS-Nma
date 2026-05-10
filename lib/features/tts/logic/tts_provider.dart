import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/voice_model.dart';

// Selected country
final selectedCountryProvider = NotifierProvider<SelectedCountryNotifier, Country>(SelectedCountryNotifier.new);

class SelectedCountryNotifier extends Notifier<Country> {
  @override
  Country build() => Country.all.first;
  void set(Country country) => state = country;
}

// Voices for selected country
final voicesProvider = Provider<List<VoiceModel>>((ref) {
  final country = ref.watch(selectedCountryProvider);
  return VoiceModel.getVoicesForLanguage(country.code);
});

// Selected voice
final selectedVoiceProvider = NotifierProvider<SelectedVoiceNotifier, VoiceModel?>(SelectedVoiceNotifier.new);

class SelectedVoiceNotifier extends Notifier<VoiceModel?> {
  @override
  VoiceModel? build() => null;
  void set(VoiceModel? voice) => state = voice;
}

// Rate
final ttsRateProvider = NotifierProvider<TtsRateNotifier, double>(TtsRateNotifier.new);

class TtsRateNotifier extends Notifier<double> {
  @override
  double build() => 1.0;
  void set(double v) => state = v;
}

// Pitch
final ttsPitchProvider = NotifierProvider<TtsPitchNotifier, double>(TtsPitchNotifier.new);

class TtsPitchNotifier extends Notifier<double> {
  @override
  double build() => 0.0;
  void set(double v) => state = v;
}

// Text input
final ttsTextProvider = NotifierProvider<TtsTextNotifier, String>(TtsTextNotifier.new);

class TtsTextNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

// Tab
final ttsTabProvider = NotifierProvider<TtsTabNotifier, int>(TtsTabNotifier.new);

class TtsTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int v) => state = v;
}

// Loading
final ttsLoadingProvider = NotifierProvider<TtsLoadingNotifier, bool>(TtsLoadingNotifier.new);

class TtsLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

// Audio URL
final ttsAudioUrlProvider = NotifierProvider<TtsAudioUrlNotifier, String?>(TtsAudioUrlNotifier.new);

class TtsAudioUrlNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? v) => state = v;
}
