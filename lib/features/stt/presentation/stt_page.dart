import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio/captured_audio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/edge_function_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/audio_input_panel.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/logic/auth_provider.dart';

final sttTextProvider = NotifierProvider<SttTextNotifier, String>(
  SttTextNotifier.new,
);

class SttTextNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final sttLoadingProvider = NotifierProvider<SttLoadingNotifier, bool>(
  SttLoadingNotifier.new,
);

class SttLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final sttLanguageProvider = NotifierProvider<SttLanguageNotifier, String>(
  SttLanguageNotifier.new,
);

class SttLanguageNotifier extends Notifier<String> {
  @override
  String build() => 'vi';
  void set(String value) => state = value;
}

class SttPage extends ConsumerStatefulWidget {
  const SttPage({super.key});

  @override
  ConsumerState<SttPage> createState() => _SttPageState();
}

class _SttPageState extends ConsumerState<SttPage> {
  CapturedAudio? _selectedAudio;

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
          'Giọng nói sang văn bản',
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
                children: [
                  _buildUploadCard(context),
                  const SizedBox(height: 20),
                  _buildResultCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard(BuildContext context) {
    final isLoading = ref.watch(sttLoadingProvider);
    final lang = ref.watch(sttLanguageProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sttPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mic,
                  color: AppColors.sttPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tải lên hoặc ghi âm',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  'Ngôn ngữ:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ...[('vi', 'Tiếng Việt'), ('en', 'English'), ('ja', '日本語')].map(
                (item) => ChoiceChip(
                  label: Text(
                    item.$2,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: lang == item.$1
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                  selected: lang == item.$1,
                  onSelected: (_) =>
                      ref.read(sttLanguageProvider.notifier).set(item.$1),
                  selectedColor: AppColors.sttPurple,
                  backgroundColor: AppColors.surfaceLight,
                  side: BorderSide(
                    color: lang == item.$1
                        ? AppColors.sttPurple
                        : AppColors.surfaceBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AudioInputPanel(
            title: 'Chọn audio hoặc ghi âm trực tiếp',
            subtitle:
                'WAV, MP3, M4A, FLAC, OGG, WEBM • tối đa ${AppConfig.maxSttDurationMinutes} phút',
            pickLabel: 'Chọn file',
            recordLabel: 'Ghi âm trực tiếp',
            accentColor: AppColors.sttPurple,
            maxSeconds: AppConfig.maxSttDurationMinutes * 60,
            onChanged: (audio) {
              setState(() => _selectedAudio = audio);
              ref.read(sttTextProvider.notifier).set('');
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isLoading || _selectedAudio == null
                  ? null
                  : () => _handleTranscribe(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sttPurple,
                disabledBackgroundColor: AppColors.sttPurple.withValues(
                  alpha: 0.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
                  : const Icon(Icons.transcribe, color: Colors.white),
              label: Text(
                isLoading ? 'Đang chuyển đổi...' : 'Bắt đầu chuyển đổi',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTranscribe(BuildContext context) async {
    final audio = _selectedAudio;
    if (audio == null) return;

    ref.read(sttLoadingProvider.notifier).set(true);
    try {
      final result = await EdgeFunctionService().transcribeAudio(
        audioBytes: audio.bytes,
        fileName: audio.fileName,
        language: ref.read(sttLanguageProvider),
      );

      ref.read(sttTextProvider.notifier).set(result['text']?.toString() ?? '');

      if (!context.mounted) return;
      AppToast.success(
        context,
        'Chuyển đổi xong. Trừ ${result['credits_used']} xu, còn ${result['balance']} xu.',
      );
    } on EdgeFunctionException catch (error) {
      if (!context.mounted) return;
      if (error.isInsufficientCredits) {
        AppToast.warning(context, error.displayMessage);
      } else {
        AppToast.error(context, error.displayMessage);
      }
    } catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, 'Lỗi STT: $error');
    } finally {
      ref.read(sttLoadingProvider.notifier).set(false);
    }
  }

  Widget _buildResultCard() {
    final text = ref.watch(sttTextProvider);
    if (text.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.text_snippet,
                color: AppColors.sttPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Kết quả',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  AppToast.success(context, 'Đã sao chép');
                },
                tooltip: 'Sao chép',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
