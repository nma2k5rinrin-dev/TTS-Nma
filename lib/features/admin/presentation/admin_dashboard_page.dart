import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../credits/presentation/credits_page.dart';

// Admin tab
final adminTabProvider = NotifierProvider<AdminTabNotifier, int>(AdminTabNotifier.new);
class AdminTabNotifier extends Notifier<int> { @override int build() => 0; void set(int v) => state = v; }

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(adminTabProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          if (isWide) _buildSidebar(ref, tab),
          // Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isWide, ref, tab),
                Expanded(child: _buildContent(tab)),
              ],
            ),
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(
        backgroundColor: AppColors.surface,
        child: _buildSidebarContent(ref, tab),
      ),
    );
  }

  Widget _buildSidebar(WidgetRef ref, int tab) {
    return Container(
      width: 250,
      color: AppColors.surface,
      child: _buildSidebarContent(ref, tab),
    );
  }

  Widget _buildSidebarContent(WidgetRef ref, int tab) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Admin Panel', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _sideItem(ref, 0, Icons.dashboard, 'Tổng quan', tab == 0),
        _sideItem(ref, 1, Icons.api, 'Cài đặt API', tab == 1),
        _sideItem(ref, 2, Icons.people, 'Quản lý User', tab == 2),
        _sideItem(ref, 3, Icons.card_giftcard, 'Gói & Giá', tab == 3),
        _sideItem(ref, 4, Icons.receipt_long, 'Giao dịch', tab == 4),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.arrow_back, size: 16),
            label: Text('Về trang chủ', style: GoogleFonts.inter(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.surfaceBorder),
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sideItem(WidgetRef ref, int index, IconData icon, String label, bool active) {
    return InkWell(
      onTap: () => ref.read(adminTabProvider.notifier).set(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: active ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.primary : AppColors.textSecondary,
            )),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(BuildContext context, bool isWide, WidgetRef ref, int tab) {
    final titles = ['Tổng quan', 'Cài đặt API', 'Quản lý User', 'Gói & Giá', 'Giao dịch'];
    return AppBar(
      backgroundColor: AppColors.surface,
      leading: isWide ? null : IconButton(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      title: Text(titles[tab], style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary), onPressed: () {}),
        const SizedBox(width: 8),
        CircleAvatar(radius: 16, backgroundColor: AppColors.error, child: Text('SA', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildContent(int tab) {
    switch (tab) {
      case 0: return const _OverviewTab();
      case 1: return const _ApiSettingsTab();
      case 2: return const _UserManagementTab();
      case 3: return const _PackagesTab();
      case 4: return const _TransactionsTab();
      default: return const SizedBox.shrink();
    }
  }
}

// ===================== TAB 0: OVERVIEW =====================
class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards
          Wrap(
            spacing: 16, runSpacing: 16,
            children: [
              _statCard('Tổng Users', '0', Icons.people, AppColors.primary, isWide),
              _statCard('Doanh thu', '0 VNĐ', Icons.trending_up, AppColors.ttsGreen, isWide),
              _statCard('Lượt TTS', '0', Icons.record_voice_over, AppColors.cloneOrange, isWide),
              _statCard('Lượt STT', '0', Icons.mic, AppColors.sttPurple, isWide),
            ],
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hoạt động gần đây', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Center(child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    const Icon(Icons.inbox, color: AppColors.textMuted, size: 40),
                    const SizedBox(height: 8),
                    Text('Chưa có hoạt động', style: GoogleFonts.inter(color: AppColors.textMuted)),
                  ]),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isWide) {
    return SizedBox(
      width: isWide ? 200 : double.infinity,
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderColor: color.withValues(alpha: 0.3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ===================== TAB 1: API SETTINGS =====================
class _ApiSettingsTab extends StatelessWidget {
  const _ApiSettingsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _apiSection('🗣️ Text-to-Speech', 'tts', [
            _apiField('Provider', 'ElevenLabs', Icons.cloud),
            _apiField('API Key', '••••••••••••', Icons.key),
            _apiField('Base URL', 'https://api.elevenlabs.io', Icons.link),
          ]),
          const SizedBox(height: 20),
          _apiSection('🎭 Voice Clone', 'voice_clone', [
            _apiField('Provider', 'ElevenLabs', Icons.cloud),
            _apiField('API Key', '••••••••••••', Icons.key),
          ]),
          const SizedBox(height: 20),
          _apiSection('🎤 Speech-to-Text', 'stt', [
            _apiField('Provider', 'OpenAI Whisper', Icons.cloud),
            _apiField('API Key', '••••••••••••', Icons.key),
            _apiField('Base URL', 'https://api.openai.com', Icons.link),
          ]),
        ],
      ),
    );
  }

  Widget _apiSection(String title, String service, List<Widget> fields) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.ttsGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('Active', style: GoogleFonts.inter(fontSize: 11, color: AppColors.ttsGreen, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...fields,
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
              child: Text('Lưu cấu hình', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _apiField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          hintText: value,
          prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surfaceLight,
        ),
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      ),
    );
  }
}

// ===================== TAB 2: USER MANAGEMENT =====================
class _UserManagementTab extends StatelessWidget {
  const _UserManagementTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Search bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm user theo email hoặc tên...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                    filled: true, fillColor: AppColors.surfaceLight,
                  ),
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text('Lọc', style: GoogleFonts.inter(fontSize: 13)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceCard, foregroundColor: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // User table
          GlassCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.surfaceBorder))),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('User', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                      Expanded(flex: 2, child: Text('Xu', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                      Expanded(flex: 2, child: Text('Role', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                      Expanded(flex: 2, child: Text('Trạng thái', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                      const SizedBox(width: 80, child: Text('')),
                    ],
                  ),
                ),
                // Empty state
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    const Icon(Icons.people_outline, color: AppColors.textMuted, size: 40),
                    const SizedBox(height: 8),
                    Text('Chưa có user nào', style: GoogleFonts.inter(color: AppColors.textMuted)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== TAB 3: PACKAGES =====================
class _PackagesTab extends StatelessWidget {
  const _PackagesTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quản lý gói nạp', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: Text('Thêm gói', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...CreditsPage.packages.asMap().entries.map((e) => _pkgRow(e.key, e.value)),
          const SizedBox(height: 32),
          Text('Cấu hình giá dịch vụ', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          GlassCard(child: Column(
            children: [
              _pricingRow('TTS Cơ bản', 'per_100_chars', '1'),
              _pricingRow('TTS Premium', 'per_100_chars', '3'),
              _pricingRow('Voice Clone (tạo)', 'per_clone', '5000'),
              _pricingRow('Voice Clone (dùng)', 'per_100_chars', '5'),
              _pricingRow('Speech-to-Text', 'per_minute', '50'),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text('Lưu giá', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              )),
            ],
          )),
        ],
      ),
    );
  }

  Widget _pkgRow(int i, Map<String, Object> pkg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(pkg['name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
            Expanded(child: Text('${pkg['credits']} xu', style: GoogleFonts.inter(color: AppColors.coinGold, fontWeight: FontWeight.w600))),
            Expanded(child: Text('${pkg['price']} VNĐ', style: GoogleFonts.inter(color: AppColors.textSecondary))),
            if ((pkg['bonus'] as int) > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.ttsGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: Text('+${pkg['bonus']}%', style: GoogleFonts.inter(fontSize: 11, color: AppColors.ttsGreen, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 12),
            IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.textMuted), onPressed: () {}),
            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _pricingRow(String label, String unit, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary))),
          Expanded(flex: 1, child: Text(unit, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
          SizedBox(
            width: 100,
            child: TextField(
              decoration: InputDecoration(hintText: value, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.coinGold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Text('xu', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ===================== TAB 4: TRANSACTIONS =====================
class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: 'Tìm giao dịch...', prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted)),
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: 'all',
                dropdownColor: AppColors.surfaceCard,
                items: [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả', style: GoogleFonts.inter(color: AppColors.textPrimary))),
                  DropdownMenuItem(value: 'topup', child: Text('Nạp xu', style: GoogleFonts.inter(color: AppColors.textPrimary))),
                  DropdownMenuItem(value: 'usage', child: Text('Sử dụng', style: GoogleFonts.inter(color: AppColors.textPrimary))),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(40),
            child: Column(children: [
              const Icon(Icons.receipt_long, color: AppColors.textMuted, size: 48),
              const SizedBox(height: 12),
              Text('Chưa có giao dịch', style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ]),
          ),
        ],
      ),
    );
  }
}
