import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';

// STT state
final sttTextProvider = NotifierProvider<SttTextNotifier, String>(SttTextNotifier.new);
class SttTextNotifier extends Notifier<String> { @override String build() => ''; void set(String v) => state = v; }

final sttLoadingProvider = NotifierProvider<SttLoadingNotifier, bool>(SttLoadingNotifier.new);
class SttLoadingNotifier extends Notifier<bool> { @override bool build() => false; void set(bool v) => state = v; }

final sttLanguageProvider = NotifierProvider<SttLanguageNotifier, String>(SttLanguageNotifier.new);
class SttLanguageNotifier extends Notifier<String> { @override String build() => 'vi'; void set(String v) => state = v; }

class SttPage extends ConsumerWidget {
  const SttPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Giọng nói sang Văn bản',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildUploadCard(context, ref),
                  const SizedBox(height: 20),
                  _buildResultCard(ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard(BuildContext context, WidgetRef ref) {
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
                child: const Icon(Icons.mic, color: AppColors.sttPurple, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Tải lên hoặc ghi âm',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          // Language selector
          Row(
            children: [
              Text('Ngôn ngữ:',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              ...[
                ('vi', '🇻🇳 Tiếng Việt'),
                ('en', '🇺🇸 English'),
                ('ja', '🇯🇵 日本語'),
              ].map((l) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l.$2,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: lang == l.$1 ? Colors.white : AppColors.textSecondary)),
                      selected: lang == l.$1,
                      onSelected: (_) => ref.read(sttLanguageProvider.notifier).set(l.$1),
                      selectedColor: AppColors.sttPurple,
                      backgroundColor: AppColors.surfaceLight,
                      side: BorderSide(
                          color: lang == l.$1 ? AppColors.sttPurple : AppColors.surfaceBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 20),
          // Upload area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sttPurple.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_outlined,
                    color: AppColors.sttPurple.withValues(alpha: 0.7), size: 48),
                const SizedBox(height: 12),
                Text('Kéo thả file audio vào đây',
                    style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Hỗ trợ: WAV, MP3, M4A, FLAC (tối đa 30 phút)',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: File picker
                  },
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: Text('Chọn file',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sttPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Or record
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Record audio
              },
              icon: const Icon(Icons.mic, color: AppColors.sttPurple),
              label: Text('Ghi âm trực tiếp',
                  style: GoogleFonts.inter(
                      color: AppColors.sttPurple, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.sttPurple.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Transcribe button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () {
                      ref.read(sttLoadingProvider.notifier).set(true);
                      Future.delayed(const Duration(seconds: 2), () {
                        ref.read(sttLoadingProvider.notifier).set(false);
                        ref.read(sttTextProvider.notifier).set(
                            'Đây là kết quả demo cho tính năng chuyển giọng nói sang văn bản. '
                            'Khi kết nối API (OpenAI Whisper), kết quả sẽ được trả về chính xác.');
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sttPurple,
                disabledBackgroundColor: AppColors.sttPurple.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.transcribe, color: Colors.white),
              label: Text(
                isLoading ? 'Đang chuyển đổi...' : 'BẮT ĐẦU CHUYỂN ĐỔI',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(WidgetRef ref) {
    final text = ref.watch(sttTextProvider);
    if (text.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_snippet, color: AppColors.sttPurple, size: 20),
              const SizedBox(width: 8),
              Text('Kết quả',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, color: AppColors.textSecondary, size: 18),
                onPressed: () {},
                tooltip: 'Sao chép',
              ),
              IconButton(
                icon: const Icon(Icons.download, color: AppColors.textSecondary, size: 18),
                onPressed: () {},
                tooltip: 'Tải xuống',
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
                  fontSize: 14, color: AppColors.textPrimary, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
