import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/config/app_config.dart';
import '../data/models/voice_model.dart';
import '../data/tts_repository.dart';
import '../logic/tts_provider.dart';
import '../../../core/services/edge_function_service.dart';
import 'widgets/audio_player_card.dart';
import '../../auth/logic/auth_provider.dart';

class TtsPage extends ConsumerStatefulWidget {
  const TtsPage({super.key});

  @override
  ConsumerState<TtsPage> createState() => _TtsPageState();
}

class _TtsPageState extends ConsumerState<TtsPage> {
  final AudioPlayer _voicePreviewPlayer = AudioPlayer();
  String? _previewingVoiceId;
  String? _playingPreviewVoiceId;
  StreamSubscription<PlayerState>? _previewStateSub;
  StreamSubscription<void>? _previewCompleteSub;

  @override
  void initState() {
    super.initState();
    _previewStateSub = _voicePreviewPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted || state == PlayerState.playing) return;
      setState(() => _playingPreviewVoiceId = null);
    });
    _previewCompleteSub = _voicePreviewPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playingPreviewVoiceId = null);
    });
  }

  @override
  void dispose() {
    _previewStateSub?.cancel();
    _previewCompleteSub?.cancel();
    _voicePreviewPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Văn bản sang Âm thanh',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final profileAsync = ref.watch(userProfileProvider);
              return profileAsync.when(
                data: (p) => p != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: CreditBadge(credits: p.credits, compact: true),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main card
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with icon
                        _buildCardHeader(),
                        // Tabs
                        _buildTabs(ref),
                        const SizedBox(height: 20),
                        // Step 1: Country
                        _buildCountrySection(ref),
                        const SizedBox(height: 24),
                        // Step 2: Voice
                        _buildVoiceSection(ref),
                        const SizedBox(height: 24),
                        // Rate & Pitch sliders
                        _buildSliders(ref),
                        const SizedBox(height: 24),
                        // Step 3: Text input
                        _buildTextInput(ref),
                        const SizedBox(height: 24),
                        // Generate button
                        _buildGenerateButton(context, ref),
                        const SizedBox(height: 16),
                        // Audio player (shows after generation)
                        _buildAudioResult(ref),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.ttsGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.record_voice_over,
              color: AppColors.ttsGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Văn bản sang Âm thanh',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(WidgetRef ref) {
    final currentTab = ref.watch(ttsTabProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          _tabButton(ref, 0, '⚙️ Mặc định', currentTab == 0),
          const SizedBox(width: 12),
          _tabButton(ref, 1, '❤️ Yêu thích', currentTab == 1),
        ],
      ),
    );
  }

  Widget _tabButton(WidgetRef ref, int index, String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(ttsTabProvider.notifier).set(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.surfaceBorder,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountrySection(WidgetRef ref) {
    final selected = ref.watch(selectedCountryProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('1', 'Chọn Quốc Gia'),
          const SizedBox(height: 12),
          // Search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Tìm quốc gia...',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Country flags grid
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Country.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final c = Country.all[i];
                final isSelected = selected.code == c.code;
                return GestureDetector(
                  onTap: () =>
                      ref.read(selectedCountryProvider.notifier).set(c),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceBorder,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.surfaceLight,
                        ),
                        child: Center(
                          child: Text(
                            c.flag,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.name.length > 8
                            ? '${c.name.substring(0, 7)}…'
                            : c.name,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSection(WidgetRef ref) {
    final allVoices = ref.watch(allVoicesProvider);
    final voices = ref.watch(voicesProvider);
    final genderFilter = ref.watch(ttsVoiceGenderFilterProvider);
    final selectedVoice = ref.watch(selectedVoiceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('2', 'Chọn Tone Giọng'),
          const SizedBox(height: 12),
          // Search voice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Tìm tên giọng đọc...',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildGenderFilter(ref, genderFilter, allVoices),
          const SizedBox(height: 14),
          // Voice grid
          if (voices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Chưa có giọng đọc cho quốc gia này',
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 3.2,
              ),
              itemCount: voices.length,
              itemBuilder: (_, i) {
                final v = voices[i];
                final isSelected = selectedVoice?.id == v.id;
                return _voiceCard(ref, v, isSelected);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGenderFilter(
    WidgetRef ref,
    VoiceGenderFilter activeFilter,
    List<VoiceModel> allVoices,
  ) {
    return Row(
      children: VoiceGenderFilter.values.map((filter) {
        final isActive = activeFilter == filter;
        final count = _voiceCountForFilter(allVoices, filter);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: filter == VoiceGenderFilter.values.last ? 0 : 8,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () =>
                  ref.read(ttsVoiceGenderFilterProvider.notifier).set(filter),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.surfaceBorder,
                  ),
                ),
                child: Text(
                  '${filter.label} ($count)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  int _voiceCountForFilter(List<VoiceModel> voices, VoiceGenderFilter filter) {
    switch (filter) {
      case VoiceGenderFilter.all:
        return voices.length;
      case VoiceGenderFilter.female:
        return voices.where((v) => v.gender == 'female').length;
      case VoiceGenderFilter.male:
        return voices.where((v) => v.gender == 'male').length;
    }
  }

  Widget _voiceCard(WidgetRef ref, VoiceModel voice, bool isSelected) {
    final bgColor = voice.gender == 'male'
        ? const Color(0xFF1E3A5F)
        : voice.gender == 'female'
        ? const Color(0xFF5F1E3A)
        : const Color(0xFF334155);
    final isPreviewing = _previewingVoiceId == voice.id;
    final isPlaying = _playingPreviewVoiceId == voice.id;
    return GestureDetector(
      onTap: () => ref.read(selectedVoiceProvider.notifier).set(voice),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? bgColor.withValues(alpha: 0.8)
              : bgColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: voice.gender == 'male'
                    ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                    : voice.gender == 'female'
                    ? const Color(0xFFEC4899).withValues(alpha: 0.3)
                    : AppColors.textMuted.withValues(alpha: 0.25),
              ),
              child: Center(
                child: Text(
                  voice.genderIcon,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voice.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      _voiceMetaChip(voice.genderLabel),
                      _voiceMetaChip(voice.providerLabel),
                    ],
                  ),
                ],
              ),
            ),
            // Preview & Fav
            SizedBox(
              width: 30,
              height: 30,
              child: isPreviewing
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: Icon(
                        isPlaying ? Icons.stop_rounded : Icons.play_arrow,
                        size: 20,
                      ),
                      color: isPlaying
                          ? AppColors.error
                          : AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      tooltip: isPlaying ? 'Dừng' : 'Nghe thử',
                      onPressed: () => _handlePreviewVoice(ref, voice),
                    ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.favorite_border, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _voiceMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSliders(WidgetRef ref) {
    final rate = ref.watch(ttsRateProvider);
    final pitch = ref.watch(ttsPitchProvider);
    final selectedVoice = ref.watch(selectedVoiceProvider);
    final pitchSupported = selectedVoice?.supportsPitch ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Rate slider
          Expanded(
            child: _sliderCard(
              ref,
              'Tốc độ (Rate)',
              rate,
              0.5,
              2.0,
              '${rate.toStringAsFixed(1)}x',
              AppColors.primary,
              (v) => ref.read(ttsRateProvider.notifier).set(v),
            ),
          ),
          const SizedBox(width: 12),
          // Pitch slider
          Expanded(
            child: _sliderCard(
              ref,
              'Độ cao (Pitch)',
              pitch,
              -1.0,
              1.0,
              '${(pitch * 100).toInt()}%',
              AppColors.cloneOrange,
              pitchSupported
                  ? (v) => ref.read(ttsPitchProvider.notifier).set(v)
                  : null,
              helperText: pitchSupported
                  ? null
                  : '${selectedVoice?.providerLabel ?? 'Provider'} không hỗ trợ đổi cao độ',
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderCard(
    WidgetRef ref,
    String label,
    double value,
    double min,
    double max,
    String display,
    Color color,
    ValueChanged<double>? onChanged, {
    String? helperText,
  }) {
    final enabled = onChanged != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: enabled
                      ? AppColors.textSecondary
                      : AppColors.textMuted,
                ),
              ),
              Text(
                display,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: enabled ? color : AppColors.textMuted,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: enabled ? color : AppColors.textMuted,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 2),
            Text(
              helperText,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextInput(WidgetRef ref) {
    final text = ref.watch(ttsTextProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('3', 'Lời đọc đó của sếp:'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                TextField(
                  maxLines: 6,
                  maxLength: AppConfig.maxTtsChars,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Sếp nhập văn bản vào đây nhé...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    counterText: '',
                  ),
                  onChanged: (v) => ref.read(ttsTextProvider.notifier).set(v),
                ),
                // Bottom bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.surfaceBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'CHIẾN ĐỐI',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${text.length} / ${AppConfig.maxTtsChars}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error,
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(ttsLoadingProvider);
    final text = ref.watch(ttsTextProvider);
    final voice = ref.watch(selectedVoiceProvider);
    final canGenerate = text.trim().isNotEmpty && voice != null && !isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: canGenerate ? () => _handleGenerate(context, ref) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.play_arrow, color: Colors.white, size: 24),
          label: Text(
            isLoading ? 'Đang tạo...' : 'BẮT ĐẦU RẶN CHỮ',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _handleGenerate(BuildContext context, WidgetRef ref) async {
    final text = ref.read(ttsTextProvider).trim();
    final voice = ref.read(selectedVoiceProvider);
    final rate = ref.read(ttsRateProvider);
    final pitch = ref.read(ttsPitchProvider);

    if (voice == null || text.isEmpty) {
      if (context.mounted) {
        AppToast.warning(context, 'Hay nhap text va chon voice truoc.');
      }
      return;
    }

    ref.read(ttsLoadingProvider.notifier).set(true);

    try {
      final ttsRepo = TtsRepository();
      final result = await ttsRepo.generate(
        text: text,
        voiceId: voice.id,
        rate: rate,
        pitch: pitch,
      );

      ref.read(ttsAudioUrlProvider.notifier).set(result.audioUrl);
      await ref.read(userProfileProvider.notifier).refreshProfile();

      if (context.mounted) {
        final usedFallback =
            result.provider == 'google_translate_tts' &&
            !voice.isGoogleFallback;
        if (usedFallback) {
          AppToast.warning(
            context,
            'Đã tạo audio bằng Google fallback vì Edge TTS lỗi. Giọng/pitch có thể không đúng model. Trừ ${result.creditsUsed} xu, còn ${result.balance} xu.',
          );
        } else {
          AppToast.show(
            context,
            message:
                'Tạo thành công! Trừ ${result.creditsUsed} xu. Còn ${result.balance} xu.',
            backgroundColor: AppColors.ttsGreen,
          );
        }
      }
    } on EdgeFunctionException catch (e) {
      if (context.mounted) {
        if (e.isInsufficientCredits) {
          AppToast.warning(context, e.displayMessage);
        } else {
          AppToast.error(context, e.displayMessage);
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Lỗi: $e');
      }
    } finally {
      ref.read(ttsLoadingProvider.notifier).set(false);
    }
  }

  Future<void> _handlePreviewVoice(WidgetRef ref, VoiceModel voice) async {
    if (_playingPreviewVoiceId == voice.id && _previewingVoiceId == null) {
      await _voicePreviewPlayer.stop();
      if (mounted) setState(() => _playingPreviewVoiceId = null);
      return;
    }

    ref.read(selectedVoiceProvider.notifier).set(voice);
    setState(() {
      _previewingVoiceId = voice.id;
      _playingPreviewVoiceId = null;
    });

    try {
      await _voicePreviewPlayer.stop();
      final result = await EdgeFunctionService().previewTts(
        voiceId: voice.id,
        text: _voicePreviewText(voice.name),
        rate: ref.read(ttsRateProvider),
        pitch: ref.read(ttsPitchProvider),
        allowFallback: voice.isGoogleFallback,
      );
      await _voicePreviewPlayer.play(
        BytesSource(result.audioBytes, mimeType: result.mimeType),
      );
      if (mounted) setState(() => _playingPreviewVoiceId = voice.id);
      if (mounted &&
          result.provider == 'google_translate_tts' &&
          !voice.supportsPitch &&
          ref.read(ttsPitchProvider).abs() > 0.01) {
        AppToast.warning(context, 'Google Viet không hỗ trợ đổi cao độ.');
      }
    } on EdgeFunctionException catch (e) {
      if (mounted) AppToast.error(context, e.displayMessage);
    } catch (e) {
      if (mounted) AppToast.error(context, 'Loi nghe thu voice: $e');
    } finally {
      if (mounted) setState(() => _previewingVoiceId = null);
    }
  }

  String _voicePreviewText(String modelName) {
    return 'Mình là: $modelName. Chào mừng bạn đến với TTS en em ây Free, tool hỗ trợ chuyển văn bản thành giọng nói.';
  }

  Widget _buildAudioResult(WidgetRef ref) {
    final audioUrl = ref.watch(ttsAudioUrlProvider);
    if (audioUrl == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AudioPlayerCard(
        audioUrl: audioUrl,
        title: 'Kết quả TTS',
        accentColor: AppColors.ttsGreen,
        onClose: () => ref.read(ttsAudioUrlProvider.notifier).set(null),
      ),
    );
  }

  Widget _sectionLabel(String step, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Text(
              step,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
