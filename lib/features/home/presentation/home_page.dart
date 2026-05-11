import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/data/models/user_profile.dart';
import '../../auth/logic/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: _buildAppBar(context, ref, profileAsync),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero header
            _buildHero(context, profileAsync),
            const SizedBox(height: 8),
            // 3 Feature columns
            _buildFeatureColumns(context, size),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, WidgetRef ref, AsyncValue<UserProfile?> profileAsync) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.record_voice_over, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text('TTS Nma',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
      actions: [
        // Language
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('VI', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Dark mode icon
        IconButton(
          icon: const Icon(Icons.dark_mode, color: AppColors.textSecondary, size: 20),
          onPressed: () {},
        ),
        // Credits badge
        profileAsync.when(
          data: (p) => p != null
              ? GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/credits'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CreditBadge(credits: p.credits, compact: true),
                  ),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        // Google / User button
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: profileAsync.when(
            data: (p) => p != null
                ? PopupMenuButton<String>(
                    offset: const Offset(0, 48),
                    icon: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (p.displayName ?? p.email)[0].toUpperCase(),
                        style: GoogleFonts.inter(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    onSelected: (v) async {
                      if (v == 'logout') {
                        await ref.read(userProfileProvider.notifier).signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                        }
                        return;
                      }
                      if (!context.mounted) return;
                      if (v == 'credits') Navigator.pushNamed(context, '/credits');
                      if (v == 'history') Navigator.pushNamed(context, '/history', arguments: 'tts');
                      if (v == 'admin') Navigator.pushNamed(context, '/admin');
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'credits',
                          child: Row(children: [
                            const Icon(Icons.monetization_on, size: 18, color: AppColors.coinGold),
                            const SizedBox(width: 8),
                            Text('Nạp xu', style: GoogleFonts.inter(fontSize: 14))
                          ])),
                      PopupMenuItem(
                          value: 'history',
                          child: Row(children: [
                            const Icon(Icons.history, size: 18),
                            const SizedBox(width: 8),
                            Text('Lịch sử', style: GoogleFonts.inter(fontSize: 14))
                          ])),
                      PopupMenuItem(
                          value: 'admin',
                          child: Row(children: [
                            const Icon(Icons.admin_panel_settings, size: 18),
                            const SizedBox(width: 8),
                            Text('Admin Panel', style: GoogleFonts.inter(fontSize: 14))
                          ])),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                          value: 'logout',
                          child: Row(children: [
                            const Icon(Icons.logout, size: 18, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text('Đăng xuất',
                                style: GoogleFonts.inter(fontSize: 14, color: AppColors.error))
                          ])),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    icon: const Text('🔵', style: TextStyle(fontSize: 14)),
                    label: Text('Đăng nhập',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ttsGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, AsyncValue<UserProfile?> profileAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface, AppColors.background],
        ),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.primary, AppColors.sttPurple, AppColors.cloneOrange],
            ).createShader(bounds),
            child: Text(
              'Chuyển Đổi Giọng Nói & Văn Bản Với AI',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Text-to-Speech • Voice Clone • Speech-to-Text',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureColumns(BuildContext context, Size size) {
    final isDesktop = size.width > 1000;
    final isTablet = size.width > 650;

    final cards = [
      _FeatureData(
        title: 'Văn bản sang\nÂm thanh',
        subtitle: 'Chuyển text thành giọng nói tự nhiên',
        icon: Icons.record_voice_over,
        gradient: AppColors.ttsGradient,
        accentColor: AppColors.ttsGreen,
        route: '/tts',
        tag: 'TTS',
      ),
      _FeatureData(
        title: 'Nhân bản\nGiọng nói',
        subtitle: 'Clone giọng nói bất kỳ với AI',
        icon: Icons.graphic_eq,
        gradient: AppColors.cloneGradient,
        accentColor: AppColors.cloneOrange,
        route: '/voice-clone',
        tag: 'CLONE',
      ),
      _FeatureData(
        title: 'Giọng nói sang\nVăn bản',
        subtitle: 'Chuyển audio thành text chính xác',
        icon: Icons.mic,
        gradient: AppColors.sttGradient,
        accentColor: AppColors.sttPurple,
        route: '/stt',
        tag: 'STT',
      ),
    ];

    if (isTablet) {
      // 3 columns side-by-side
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildFeatureColumn(context, c),
                    ),
                  ))
              .toList(),
        ),
      );
    } else {
      // Stack vertically on mobile
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: cards
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFeatureColumn(context, c),
                  ))
              .toList(),
        ),
      );
    }
  }

  Widget _buildFeatureColumn(BuildContext context, _FeatureData data) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, data.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceBorder, width: 1),
          ),
          child: Column(
            children: [
              // Top gradient header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: data.gradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(data.icon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      data.title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Bottom info
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      data.subtitle,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: data.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: data.accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sử dụng ngay',
                            style: GoogleFonts.inter(
                              color: data.accentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward, color: data.accentColor, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color accentColor;
  final String route;
  final String tag;

  const _FeatureData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.route,
    required this.tag,
  });
}
