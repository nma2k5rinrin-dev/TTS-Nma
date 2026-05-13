import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';

// Providers
final selectedPackageProvider = NotifierProvider<SelectedPackageNotifier, int?>(
  SelectedPackageNotifier.new,
);

class SelectedPackageNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void set(int? v) => state = v;
}

class CreditsPage extends ConsumerWidget {
  const CreditsPage({super.key});

  static const packages = [
    {'name': 'Starter', 'price': 20000, 'credits': 20000, 'bonus': 0},
    {'name': 'Basic', 'price': 50000, 'credits': 55000, 'bonus': 10},
    {'name': 'Standard', 'price': 100000, 'credits': 115000, 'bonus': 15},
    {'name': 'Premium', 'price': 200000, 'credits': 240000, 'bonus': 20},
    {'name': 'Pro', 'price': 500000, 'credits': 625000, 'bonus': 25},
    {'name': 'Enterprise', 'price': 1000000, 'credits': 1300000, 'bonus': 30},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPackageProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nạp Xu',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () => _showHistory(context),
            icon: const Icon(
              Icons.history,
              size: 18,
              color: AppColors.textSecondary,
            ),
            label: Text(
              'Lịch sử',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 24),
                  Text(
                    'Chọn gói nạp',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPackageGrid(ref, selected, isWide),
                  const SizedBox(height: 24),
                  _buildPricingInfo(),
                  const SizedBox(height: 24),
                  _buildPayButton(context, ref, selected),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.coinGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.monetization_on,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Số dư hiện tại',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '0 xu',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.coinGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageGrid(WidgetRef ref, int? selected, bool isWide) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isWide ? 1.3 : 1.1,
      ),
      itemCount: packages.length,
      itemBuilder: (_, i) => _packageCard(ref, i, selected == i),
    );
  }

  Widget _packageCard(WidgetRef ref, int index, bool isSelected) {
    final pkg = packages[index];
    final bonus = pkg['bonus'] as int;
    final isPro = index >= 4;

    return GestureDetector(
      onTap: () => ref.read(selectedPackageProvider.notifier).set(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (bonus > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPro
                      ? AppColors.coinGold.withValues(alpha: 0.2)
                      : AppColors.ttsGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+$bonus%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPro ? AppColors.coinGold : AppColors.ttsGreen,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              pkg['name'] as String,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatNumber(pkg['credits'] as int)} xu',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.coinGold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatNumber(pkg['price'] as int)} VNĐ',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingInfo() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💰 Bảng giá dịch vụ',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _priceRow('🗣️ TTS Cơ bản', '1 xu / 100 ký tự'),
          _priceRow('⭐ TTS Premium', '3 xu / 100 ký tự'),
          _priceRow('🎭 Tạo Voice Clone', '5,000 xu / lần'),
          _priceRow('🎭 Dùng Voice Clone', '5 xu / 100 ký tự'),
          _priceRow('🎤 Voice to Text', '50 xu / phút'),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            price,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(BuildContext context, WidgetRef ref, int? selected) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: selected == null
            ? null
            : () => _showPaymentMethods(context, selected),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coinGold,
          disabledBackgroundColor: AppColors.coinGold.withValues(alpha: 0.3),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          selected != null
              ? 'NẠP ${_formatNumber(packages[selected]['credits'] as int)} XU'
              : 'CHỌN GÓI ĐỂ NẠP',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showPaymentMethods(BuildContext context, int pkgIndex) {
    final pkg = packages[pkgIndex];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chọn phương thức thanh toán',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${pkg['name']} — ${_formatNumber(pkg['price'] as int)} VNĐ',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _payMethod(ctx, '🏦', 'Chuyển khoản ngân hàng', 'Bank Transfer'),
            const SizedBox(height: 10),
            _payMethod(ctx, '💜', 'Ví MoMo', 'MoMo'),
            const SizedBox(height: 10),
            _payMethod(ctx, '💙', 'ZaloPay', 'ZaloPay'),
            const SizedBox(height: 10),
            _payMethod(ctx, '🔴', 'VNPay', 'VNPay'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _payMethod(
    BuildContext ctx,
    String icon,
    String label,
    String method,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        AppToast.info(ctx, 'Thanh toán $method sẽ được tích hợp!');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Lịch sử giao dịch',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: AppColors.textMuted,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có giao dịch',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(0)}M';
    if (n >= 1000)
      return '${n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    return n.toString();
  }
}
