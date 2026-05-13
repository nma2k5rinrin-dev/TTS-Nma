import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio/captured_audio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/edge_function_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/audio_input_panel.dart';
import '../../../core/widgets/audio_player_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/logic/auth_provider.dart';

final clonedVoicesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final rows = await SupabaseService.client
          .from('voice_clones')
          .select(
            'id,name,status,clone_voice_id,provider,sample_audio_url,created_at',
          )
          .order('created_at', ascending: false);

      return (rows as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    });

class VoiceClonePage extends ConsumerStatefulWidget {
  const VoiceClonePage({super.key});

  @override
  ConsumerState<VoiceClonePage> createState() => _VoiceClonePageState();
}

class _VoiceClonePageState extends ConsumerState<VoiceClonePage> {
  bool _isCreating = false;
  bool _isGenerating = false;
  String? _generatedAudioUrl;
  String? _generatedTitle;
  int? _generatedCredits;

  bool get _isBusy => _isCreating || _isGenerating;

  @override
  Widget build(BuildContext context) {
    final clonedVoices = ref.watch(clonedVoicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nhân bản giọng nói',
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _isBusy ? null : () => _showCreateCloneDialog(context),
              icon: const Icon(Icons.mic, size: 18),
              label: Text(
                'Thêm giọng mới',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cloneOrange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.cloneOrange.withValues(
                  alpha: 0.35,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: clonedVoices.when(
                    data: (voices) => Column(
                      children: [
                        if (voices.isEmpty)
                          _buildEmptyState(context)
                        else
                          _buildVoiceList(voices),
                        if (_generatedAudioUrl != null) ...[
                          const SizedBox(height: 18),
                          AudioPlayerCard(
                            audioUrl: _generatedAudioUrl,
                            title: _generatedTitle ?? 'Audio giọng clone',
                            accentColor: AppColors.cloneOrange,
                            creditsUsed: _generatedCredits,
                            onClose: () {
                              setState(() {
                                _generatedAudioUrl = null;
                                _generatedTitle = null;
                                _generatedCredits = null;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(
                        color: AppColors.cloneOrange,
                      ),
                    ),
                    error: (error, _) => _buildErrorState(error),
                  ),
                ),
              ),
            ),
          ),
          if (_isBusy)
            LoadingOverlay(
              message: _isCreating
                  ? 'Đang tạo voice clone...'
                  : 'Đang tạo audio thử...',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 28),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceLight,
              border: Border.all(color: AppColors.surfaceBorder, width: 2),
            ),
            child: const Icon(
              Icons.graphic_eq,
              color: AppColors.cloneOrange,
              size: 44,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có giọng clone',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo một mẫu giọng từ file hoặc ghi âm trực tiếp để test Fish Audio.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _isBusy ? null : () => _showCreateCloneDialog(context),
            icon: const Icon(Icons.add),
            label: Text(
              'Tạo giọng ngay',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cloneOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceList(List<Map<String, dynamic>> voices) {
    return Column(children: voices.map(_voiceItem).toList());
  }

  Widget _voiceItem(Map<String, dynamic> voice) {
    final name = voice['name']?.toString() ?? 'Voice clone';
    final status = voice['status']?.toString() ?? 'processing';
    final voiceId = voice['clone_voice_id']?.toString();
    final provider = voice['provider']?.toString() ?? 'fish_audio';
    final canGenerate =
        voiceId != null && voiceId.isNotEmpty && status != 'failed';

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
              child: const Icon(
                Icons.graphic_eq,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_statusText(status)} • $provider',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (voiceId != null && voiceId.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      voiceId,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: canGenerate && !_isBusy
                  ? () => _showGenerateDialog(voice)
                  : null,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: Text(
                'Tạo thử',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cloneOrange,
                side: BorderSide(
                  color: AppColors.cloneOrange.withValues(alpha: 0.55),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 36),
          const SizedBox(height: 12),
          Text(
            'Không tải được danh sách giọng clone',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error.toString(),
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => ref.invalidate(clonedVoicesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateCloneDialog(BuildContext context) async {
    final draft = await showDialog<_CloneDraft>(
      context: context,
      builder: (_) => const _CreateCloneDialog(),
    );
    if (draft == null) return;

    setState(() => _isCreating = true);
    try {
      final result = await EdgeFunctionService().createVoiceClone(
        name: draft.name,
        audioBytes: draft.audio.bytes,
        fileName: draft.audio.fileName,
      );

      ref.invalidate(clonedVoicesProvider);

      if (!context.mounted) return;
      AppToast.success(
        context,
        '${result['name']} đã được tạo. Trừ ${result['credits_used']} xu, còn ${result['balance']} xu.',
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
      AppToast.error(context, 'Lỗi tạo voice clone: $error');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _showGenerateDialog(Map<String, dynamic> voice) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _GenerateCloneDialog(
        voiceName: voice['name']?.toString() ?? 'Voice clone',
      ),
    );
    if (text == null || text.trim().isEmpty) return;

    final voiceId = voice['clone_voice_id']?.toString();
    if (voiceId == null || voiceId.isEmpty) return;

    setState(() => _isGenerating = true);
    try {
      final result = await EdgeFunctionService().generateClonedSpeech(
        voiceId: voiceId,
        text: text.trim(),
      );

      setState(() {
        _generatedAudioUrl = result['audio_url']?.toString();
        _generatedTitle = 'Audio clone: ${voice['name'] ?? 'Voice clone'}';
        _generatedCredits = result['credits_used'] as int?;
      });

      if (!mounted) return;
      AppToast.success(
        context,
        'Tạo audio clone xong. Trừ ${result['credits_used']} xu, còn ${result['balance']} xu.',
      );
    } on EdgeFunctionException catch (error) {
      if (!mounted) return;
      if (error.isInsufficientCredits) {
        AppToast.warning(context, error.displayMessage);
      } else {
        AppToast.error(context, error.displayMessage);
      }
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, 'Lỗi tạo audio clone: $error');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  String _statusText(String status) {
    return switch (status) {
      'ready' => 'Sẵn sàng',
      'failed' => 'Thất bại',
      _ => 'Đang xử lý',
    };
  }
}

class _CreateCloneDialog extends StatefulWidget {
  const _CreateCloneDialog();

  @override
  State<_CreateCloneDialog> createState() => _CreateCloneDialogState();
}

class _CreateCloneDialogState extends State<_CreateCloneDialog> {
  final TextEditingController _nameController = TextEditingController();
  CapturedAudio? _audio;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _nameController.text.trim().isNotEmpty && _audio != null;

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Tạo giọng mới',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Tên giọng nói',
                  hintText: 'VD: Giọng của tôi',
                  labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cloneOrange),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AudioInputPanel(
                title: 'Audio mẫu cho voice clone',
                subtitle:
                    'Nên dùng giọng sạch, một người nói, tối thiểu 10 giây • tối đa ${AppConfig.maxCloneSampleSeconds} giây',
                pickLabel: 'Chọn file',
                recordLabel: 'Ghi âm',
                accentColor: AppColors.cloneOrange,
                maxSeconds: AppConfig.maxCloneSampleSeconds,
                onChanged: (audio) => setState(() => _audio = audio),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Hủy',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: canSubmit
              ? () {
                  Navigator.pop(
                    context,
                    _CloneDraft(
                      name: _nameController.text.trim(),
                      audio: _audio!,
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cloneOrange,
            disabledBackgroundColor: AppColors.cloneOrange.withValues(
              alpha: 0.35,
            ),
          ),
          child: Text(
            'Tạo giọng',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _GenerateCloneDialog extends StatefulWidget {
  final String voiceName;

  const _GenerateCloneDialog({required this.voiceName});

  @override
  State<_GenerateCloneDialog> createState() => _GenerateCloneDialogState();
}

class _GenerateCloneDialogState extends State<_GenerateCloneDialog> {
  final TextEditingController _textController = TextEditingController(
    text: 'Xin chào, đây là bản test giọng nói đã clone.',
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _textController.text.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Tạo audio thử',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.voiceName,
              style: GoogleFonts.inter(
                color: AppColors.cloneOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              onChanged: (_) => setState(() {}),
              maxLines: 5,
              maxLength: AppConfig.maxTtsChars,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Nhập câu muốn giọng clone đọc...',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cloneOrange),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Hủy',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: canSubmit
              ? () => Navigator.pop(context, _textController.text)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cloneOrange,
            disabledBackgroundColor: AppColors.cloneOrange.withValues(
              alpha: 0.35,
            ),
          ),
          child: Text(
            'Tạo audio',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _CloneDraft {
  final String name;
  final CapturedAudio audio;

  const _CloneDraft({required this.name, required this.audio});
}
