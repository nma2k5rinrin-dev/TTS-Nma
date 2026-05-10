import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';

// History data provider
final historyProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, service) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  String table;
  switch (service) {
    case 'tts': table = 'tts_history'; break;
    case 'stt': table = 'stt_history'; break;
    case 'voice_clone': table = 'voice_clones'; break;
    default: return [];
  }

  final response = await client
      .from(table)
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);

  return List<Map<String, dynamic>>.from(response);
});

class HistoryPage extends ConsumerWidget {
  final String service; // 'tts', 'stt', 'voice_clone'
  const HistoryPage({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider(service));
    final titles = {'tts': 'Lịch sử TTS', 'stt': 'Lịch sử STT', 'voice_clone': 'Voice Clones'};
    final icons = {'tts': Icons.record_voice_over, 'stt': Icons.mic, 'voice_clone': Icons.graphic_eq};
    final colors = {'tts': AppColors.ttsGreen, 'stt': AppColors.sttPurple, 'voice_clone': AppColors.cloneOrange};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(titles[service] ?? 'Lịch sử',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: history.when(
        data: (items) => items.isEmpty
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                itemBuilder: (_, i) => _buildItem(items[i], colors[service] ?? AppColors.primary),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e', style: GoogleFonts.inter(color: AppColors.error))),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('Chưa có lịch sử', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item, Color accentColor) {
    final createdAt = DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();
    final dateStr = '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
    final credits = item['credits_used'] ?? 0;

    String subtitle;
    if (service == 'tts') {
      final text = (item['text_input'] as String?) ?? '';
      subtitle = text.length > 60 ? '${text.substring(0, 60)}...' : text;
    } else if (service == 'stt') {
      final text = (item['transcribed_text'] as String?) ?? '';
      subtitle = text.length > 60 ? '${text.substring(0, 60)}...' : text;
    } else {
      subtitle = item['name'] ?? 'Voice Clone';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                service == 'tts' ? Icons.record_voice_over : service == 'stt' ? Icons.mic : Icons.graphic_eq,
                color: accentColor, size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.coinGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('-$credits xu',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.coinGold)),
            ),
          ],
        ),
      ),
    );
  }
}
