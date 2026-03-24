import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/auth_provider.dart';
import '../core/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool _obscurePass = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: FloatingHeartsBackground(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Brand ──
                    BrandHeader(tagline: 'Begin your love story 💕'),
                    const SizedBox(height: 44),

                    // ── Card ──
                    VelvetCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create Account', style: AppTheme.display(26)),
                          const SizedBox(height: 4),
                          Text(
                            'Join and play with your partner',
                            style: AppTheme.body(13),
                          ),
                          const SizedBox(height: 32),

                          // Name
                          FieldLabel('Your Name'),
                          TextField(
                            controller: nameCtrl,
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: AppTheme.inputDeco(
                              'e.g. Harsh',
                              Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email
                          FieldLabel('Email'),
                          TextField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: AppTheme.inputDeco(
                              'you@example.com',
                              Icons.email_outlined,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password
                          FieldLabel('Password'),
                          TextField(
                            controller: passCtrl,
                            obscureText: _obscurePass,
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: AppTheme.inputDeco(
                              '••••••••',
                              Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: GestureDetector(
                                onTap: () =>
                                    setState(() => _obscurePass = !_obscurePass),
                                child: Icon(
                                  _obscurePass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color:
                                      AppTheme.textSecondary.withOpacity(0.7),
                                  size: 18,
                                ),
                              ),
                            ),
                          ),

                          // Error
                          if (auth.error != null) ...[
                            const SizedBox(height: 12),
                            ErrorRow(auth.error!),
                          ],
                          const SizedBox(height: 28),

                          AppTheme.roseButton(
                            label: 'Create Account',
                            isLoading: auth.isLoading,
                            onTap: () async {
                              final ok = await auth.register(
                                nameCtrl.text.trim(),
                                emailCtrl.text.trim(),
                                passCtrl.text,
                              );
                              if (ok && context.mounted) {
                                final returnTo = GoRouterState.of(context)
                                    .uri
                                    .queryParameters['returnTo'];
                                if (returnTo != null) {
                                  context.go(returnTo);
                                } else {
                                  context.go('/home');
                                }
                              }
                            },
                          ),

                          const SizedBox(height: 20),
                          Center(
                            child: GestureDetector(
                              onTap: () => context.go('/login'),
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: AppTheme.body(13),
                                  children: [
                                    TextSpan(
                                      text: 'Sign in',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppTheme.rose,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
