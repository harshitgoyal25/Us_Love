import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/auth_provider.dart';
import '../core/api_client.dart';
import '../models/room_model.dart';
import '../core/app_theme.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  final String? initialCode;
  const HomeScreen({super.key, this.initialCode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  final codeCtrl = TextEditingController();
  bool isLoading = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();

    if (widget.initialCode != null) {
      codeCtrl.text = widget.initialCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        joinRoom();
      });
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> createRoom() async {
    setState(() => isLoading = true);
    try {
      final userId = await _api.getUserId();
      final data = await _api.createRoom(userId!);
      final room = RoomModel.fromMap(data);
      if (context.mounted) context.go('/lobby', extra: room);
    } catch (e) {
      setState(() => isLoading = false);
      if (context.mounted) {
        _showError('Failed to create room. Try again.');
      }
    }
  }

  Future<void> joinRoom() async {
    if (codeCtrl.text.trim().isEmpty) return;
    setState(() => isLoading = true);
    try {
      final userId = await _api.getUserId();
      final data = await _api.joinRoom(
        codeCtrl.text.toUpperCase().trim(),
        userId!,
      );
      final room = RoomModel.fromMap(data);
      if (context.mounted) context.go('/lobby', extra: room);
    } catch (e) {
      setState(() => isLoading = false);
      if (context.mounted) {
        _showError('Room not found. Check the code.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.bg3,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.rose, size: 16),
            const SizedBox(width: 10),
            Text(
              msg,
              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppTheme.rose),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: FloatingHeartsBackground(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Brand ──
                    BrandHeader(
                      tagline: auth.name != null
                          ? 'Welcome back, ${auth.name} 💕'
                          : 'Play together. Love together.',
                    ),
                    const SizedBox(height: 48),

                    // ── Main card ──
                    Container(
                      width: 480,
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: AppTheme.bg3,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.rose.withOpacity(0.06),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.rose.withOpacity(0.04),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: AppTheme.shadowAmbient,
                            blurRadius: 40,
                            offset: Offset.zero,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Create section ──
                          _SectionHeader(
                            icon: Icons.add_circle_outline_rounded,
                            title: 'Create a Room',
                            subtitle: 'Share the code with your partner',
                          ),
                          const SizedBox(height: 16),
                          AppTheme.roseButton(
                            label: '+ Create Room',
                            isLoading: isLoading,
                            onTap: isLoading ? null : createRoom,
                          ),

                          const SizedBox(height: 36),

                          // ── Divider ──
                          _OrDivider(),

                          const SizedBox(height: 36),

                          // ── Join section ──
                          _SectionHeader(
                            icon: Icons.login_rounded,
                            title: 'Join a Room',
                            subtitle: 'Enter the code your partner sent you',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: codeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: 10,
                            ),
                            decoration: AppTheme.inputDeco(
                              'ABCD12',
                              Icons.vpn_key_rounded,
                            ).copyWith(
                              hintStyle: GoogleFonts.spaceGrotesk(
                                color: AppTheme.textSecondary.withOpacity(0.4),
                                fontSize: 26,
                                letterSpacing: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppTheme.roseButton(
                            label: 'Join Room →',
                            isLoading: false,
                            onTap: isLoading ? null : joinRoom,
                            outlined: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppTheme.bg2),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary.withOpacity(0.4),
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: AppTheme.bg2),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.label(15)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTheme.body(12)),
          ],
        ),
      ],
    );
  }
}
