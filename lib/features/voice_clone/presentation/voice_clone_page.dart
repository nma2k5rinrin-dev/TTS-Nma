import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';

// Demo cloned voices
final clonedVoicesProvider = NotifierProvider<ClonedVoicesNotifier, List<Map<String, dynamic>>>(ClonedVoicesNotifier.new);

class ClonedVoicesNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];
  void set(List<Map<String, dynamic>> v) => state = v;
}

class VoiceClonePage extends ConsumerWidget {
  const VoiceClonePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clonedVoices = ref.watch(clonedVoicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Nhân bản giọng nói',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateCloneDialog(context, ref),
              icon: const Icon(Icons.mic, size: 18),
              label: Text('Thêm giọng mới',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cloneOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: clonedVoices.isEmpty ? _buildEmptyState(context, ref) : _buildVoiceList(ref),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceLight,
              border: Border.all(color: AppColors.surfaceBorder, width: 2),
            ),
            child: const Center(child: Text('👻', style: TextStyle(fontSize: 48))),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có dữ liệu',
            style: GoogleFonts.inter(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Sếp chưa clone giọng nào cả, tạo thử một cái đi sếp!',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => _showCreateCloneDialog(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Tạo Giọng Ngay',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceList(WidgetRef ref) {
    final voices = ref.watch(clonedVoicesProvider);
    return Column(
      children: voices.map((v) => _voiceItem(ref, v)).toList(),
    );
  }

  Widget _voiceItem(WidgetRef ref, Map<String, dynamic> voice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.cloneGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.graphic_eq, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(voice['name'] ?? '',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(voice['status'] == 'ready' ? '✅ Sẵn sàng' : '⏳ Đang xử lý',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow, color: AppColors.primary),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              onPressed: () {
                final list = [...ref.read(clonedVoicesProvider)];
                list.remove(voice);
                ref.read(clonedVoicesProvider.notifier).set(list);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCloneDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tạo giọng mới',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Tên giọng nói',
                hintText: 'VD: Giọng của tôi',
              ),
            ),
            const SizedBox(height: 20),
            // Upload area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cloneOrange.withValues(alpha: 0.3), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, color: AppColors.cloneOrange, size: 36),
                  const SizedBox(height: 8),
                  Text('Tải lên file ghi âm',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('WAV, MP3 (tối đa 60s)',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Or record
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.mic, size: 18, color: AppColors.cloneOrange),
              label: Text('Hoặc ghi âm trực tiếp',
                  style: GoogleFonts.inter(color: AppColors.cloneOrange)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.cloneOrange.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final list = [...ref.read(clonedVoicesProvider)];
                list.add({'name': nameController.text, 'status': 'processing'});
                ref.read(clonedVoicesProvider.notifier).set(list);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cloneOrange),
            child: Text('Tạo giọng', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
