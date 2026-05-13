import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/models/user_profile.dart';
import '../../auth/logic/auth_provider.dart';

final accountTransactionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return [];

      final rows = await SupabaseService.client
          .from('credit_transactions')
          .select('type,amount,balance_after,service,description,created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(200);

      return List<Map<String, dynamic>>.from(rows as List);
    });

class AccountDashboardPage extends ConsumerStatefulWidget {
  const AccountDashboardPage({super.key});

  @override
  ConsumerState<AccountDashboardPage> createState() =>
      _AccountDashboardPageState();
}

class _AccountDashboardPageState extends ConsumerState<AccountDashboardPage> {
  final _displayNameController = TextEditingController();
  bool _isSaving = false;
  String? _loadedProfileId;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final transactionsAsync = ref.watch(accountTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tài khoản',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () {
              ref.invalidate(accountTransactionsProvider);
              ref.read(userProfileProvider.notifier).refreshProfile();
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Chưa đăng nhập'));
          }

          if (_loadedProfileId != profile.id) {
            _loadedProfileId = profile.id;
            _displayNameController.text = profile.displayName ?? '';
          }

          return transactionsAsync.when(
            data: (transactions) =>
                _buildContent(context, profile, transactions),
            loading: () => _buildContent(context, profile, const []),
            error: (error, _) => _buildContent(
              context,
              profile,
              const [],
              transactionError: error.toString(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Lỗi tải tài khoản: $error',
            style: GoogleFonts.inter(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserProfile profile,
    List<Map<String, dynamic>> transactions, {
    String? transactionError,
  }) {
    final totalAdded = transactions
        .where((row) => ((row['amount'] as num?)?.toInt() ?? 0) > 0)
        .fold<int>(
          0,
          (sum, row) => sum + ((row['amount'] as num?)?.toInt() ?? 0),
        );
    final totalUsed = transactions
        .where((row) => ((row['amount'] as num?)?.toInt() ?? 0) < 0)
        .fold<int>(
          0,
          (sum, row) => sum + ((row['amount'] as num?)?.toInt() ?? 0).abs(),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(profile),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  final cards = [
                    _statCard(
                      'Số dư',
                      '${_formatNumber(profile.credits)} xu',
                      Icons.monetization_on,
                      AppColors.coinGold,
                    ),
                    _statCard(
                      'Đã cộng',
                      '${_formatNumber(totalAdded)} xu',
                      Icons.add_circle,
                      AppColors.ttsGreen,
                    ),
                    _statCard(
                      'Đã dùng',
                      '${_formatNumber(totalUsed)} xu',
                      Icons.trending_down,
                      AppColors.cloneOrange,
                    ),
                  ];

                  return isWide
                      ? Row(
                          children: cards
                              .map(
                                (card) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: card,
                                  ),
                                ),
                              )
                              .toList(),
                        )
                      : Column(
                          children: cards
                              .map(
                                (card) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: card,
                                ),
                              )
                              .toList(),
                        );
                },
              ),
              const SizedBox(height: 16),
              _buildProfileForm(profile),
              const SizedBox(height: 16),
              _buildTransactions(
                transactions.take(30).toList(),
                transactionError,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserProfile profile) {
    final nameSeed = (profile.displayName ?? profile.email).trim();
    final initial = nameSeed.isEmpty ? '?' : nameSeed[0].toUpperCase();

    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName ?? 'User',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: profile.isSuperAdmin
                  ? AppColors.primary.withValues(alpha: 0.16)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: profile.isSuperAdmin
                    ? AppColors.primary.withValues(alpha: 0.36)
                    : AppColors.surfaceBorder,
              ),
            ),
            child: Text(
              profile.isSuperAdmin ? 'SADMIN' : 'USER',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: profile.isSuperAdmin
                    ? AppColors.primaryLight
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: color.withValues(alpha: 0.28),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(UserProfile profile) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin cá nhân',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _displayNameController,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Tên hiển thị',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: profile.email,
            enabled: false,
            style: GoogleFonts.inter(color: AppColors.textSecondary),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/credits'),
                icon: const Icon(Icons.add_card, size: 18),
                label: const Text('Nạp xu'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/history', arguments: 'tts'),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Lịch sử TTS'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveProfile(profile.id),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 18),
                label: const Text('Lưu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactions(
    List<Map<String, dynamic>> transactions,
    String? transactionError,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Giao dịch gần đây',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${transactions.length} mục',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (transactionError != null) ...[
            const SizedBox(height: 12),
            Text(
              transactionError,
              style: GoogleFonts.inter(color: AppColors.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Chưa có giao dịch',
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...transactions.map(_transactionRow),
        ],
      ),
    );
  }

  Widget _transactionRow(Map<String, dynamic> row) {
    final amount = ((row['amount'] as num?)?.toInt() ?? 0);
    final positive = amount >= 0;
    final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
    final date = createdAt == null
        ? ''
        : DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.add_circle : Icons.remove_circle,
            color: positive ? AppColors.ttsGreen : AppColors.cloneOrange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['description']?.toString() ??
                      row['type']?.toString() ??
                      '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : '-'}${_formatNumber(amount.abs())} xu',
            style: GoogleFonts.inter(
              color: positive ? AppColors.ttsGreen : AppColors.cloneOrange,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile(String profileId) async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      AppToast.warning(context, 'Tên hiển thị không được để trống');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AuthRepository().updateProfile(profileId, {
        'display_name': displayName,
      });
      await ref.read(userProfileProvider.notifier).refreshProfile();
      if (mounted) AppToast.success(context, 'Đã cập nhật tài khoản');
    } catch (error) {
      if (mounted) AppToast.error(context, 'Không lưu được: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatNumber(int value) {
    return NumberFormat.decimalPattern('vi_VN').format(value);
  }
}
