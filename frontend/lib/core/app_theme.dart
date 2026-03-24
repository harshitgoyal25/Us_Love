import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Palette (Velvet Hearts - The Digital Hearth) ──────────────────────────
  static const Color bg1 = Color(0xFF161213);               // Deep nocturnal base
  static const Color bg2 = Color(0xFF1F1A1B);               // surface_container_low
  static const Color bg3 = Color(0xFF2D292A);               // surface_container_high
  
  static const Color rose = Color(0xFFFFB3B5);              // primary (neon romantic pink)
  static const Color roseDark = Color(0xFFFF5167);          // primary_container
  static const Color gold = Color(0xFFFFD166);              // contrasting gold/yellow
  
  static const Color textPrimary = Color(0xFFEAE0E1);       // on_surface (creamy white)
  static const Color textSecondary = Color(0xFFE6BCBD);     // on_surface_variant
  static const Color shadowAmbient = Color(0x0DEAE0E1);     // 5% ambient glow using on_surface

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bg1, bg2],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rose, roseDark],
  );

  // ── Typography (Editorial Romance) ─────────────────────────────────────────
  static TextStyle display(double size) => GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.02 * size, // Tight letter spacing for authoritative feel
      );

  static TextStyle body(double size, {Color? color}) => GoogleFonts.inter(
        fontSize: size,
        color: color ?? textSecondary,
        fontWeight: FontWeight.w400,
      );

  static TextStyle label(double size) => GoogleFonts.inter(
        fontSize: size,
        color: textPrimary,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      );

  // ── Velvet Form & Glassmorphism ────────────────────────────────────────────

  // Replaces the physical raised container with intentional asymmetrical ambient floating depth
  static BoxDecoration velvetCard({double radius = 24}) => BoxDecoration(
        color: bg3,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: shadowAmbient,
            blurRadius: 40,
            offset: Offset(0, 0), // Ambient 0px offset
          ),
        ],
      );

  static BoxDecoration velvetCardPressed({double radius = 24}) => BoxDecoration(
        color: bg2,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [],
      );

  // Glassmorphic overlay cards (The "Glass & Gradient" Rule)
  static BoxDecoration glassCard({double radius = 24}) => BoxDecoration(
        color: const Color(0xFF383335).withOpacity(0.5), // surface_variant @ 50%
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF5D3F40).withOpacity(0.15), width: 1), // Ghost border fallback
        boxShadow: const [
          BoxShadow(
            color: shadowAmbient,
            blurRadius: 32,
            offset: Offset(0, 0),
          ),
        ],
      );

  // ── Input decoration ───────────────────────────────────────────────────────
  static InputDecoration inputDeco(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: textSecondary.withOpacity(0.6), fontSize: 14),
        prefixIcon: Icon(icon, color: textSecondary, size: 18),
        filled: true,
        fillColor: bg3, // surface_container_highest
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // "No-line" rule
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: rose, width: 2), // Active tint on bottom
        ),
      );

  // ── Buttons (The Pulsing Heart) ─────────────────────────────────────────────
  static Widget roseButton({
    required String label,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool outlined = false,
  }) {
    return _GlowButton(
      label: label,
      onTap: onTap,
      isLoading: isLoading,
      outlined: outlined,
    );
  }
}

// Velvet hearts primary action button with deep glow instead of hard shadow
class _GlowButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool outlined;

  const _GlowButton({
    required this.label,
    required this.onTap,
    required this.isLoading,
    required this.outlined,
  });

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && !widget.isLoading) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null && !widget.isLoading) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 56, // Slightly taller for premium feel
        decoration: BoxDecoration(
          gradient: widget.outlined ? null : AppTheme.primaryGradient,
          color: widget.outlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(100), // Fully rounded for buttons
          border: widget.outlined 
              ? Border.all(color: AppTheme.rose.withOpacity(0.5), width: 1.5) 
              : null,
          boxShadow: _isPressed || widget.onTap == null || widget.outlined
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.rose.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8), // Soft vertical glow
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: widget.outlined ? AppTheme.rose : AppTheme.bg1,
                    strokeWidth: 2,
                  )
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.outlined ? AppTheme.rose : AppTheme.bg1, // High contrast
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

class _HeartData {
  final double left;
  final double size;
  final int delay;
  final int duration;

  _HeartData({
    required this.left,
    required this.size,
    required this.delay,
    required this.duration,
  });
}

// ── Floating hearts background (Velvet Ambient Glow) ──────────────────────────
class FloatingHeartsBackground extends StatefulWidget {
  final Widget child;
  const FloatingHeartsBackground({super.key, required this.child});

  @override
  State<FloatingHeartsBackground> createState() =>
      _FloatingHeartsBackgroundState();
}

class _FloatingHeartsBackgroundState extends State<FloatingHeartsBackground>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  final List<_HeartData> _hearts = [
    _HeartData(left: 0.05, size: 24, delay: 0, duration: 16),
    _HeartData(left: 0.15, size: 34, delay: 1200, duration: 20),
    _HeartData(left: 0.28, size: 18, delay: 300, duration: 18),
    _HeartData(left: 0.42, size: 40, delay: 800, duration: 22),
    _HeartData(left: 0.55, size: 28, delay: 2000, duration: 19),
    _HeartData(left: 0.68, size: 32, delay: 500, duration: 15),
    _HeartData(left: 0.78, size: 22, delay: 1500, duration: 21),
    _HeartData(left: 0.90, size: 36, delay: 700, duration: 17),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = _hearts.map((h) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: h.duration * 1000),
      );
      Future.delayed(Duration(milliseconds: h.delay), () {
        if (mounted) c.repeat();
      });
      return c;
    }).toList();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(color: AppTheme.bg1),
        ),
        ...List.generate(_hearts.length, (i) {
          final h = _hearts[i];
          return AnimatedBuilder(
            animation: _controllers[i],
            builder: (ctx, _) {
              final t = _controllers[i].value;
              final opacity = t < 0.15
                  ? t / 0.15
                  : t > 0.85
                      ? (1 - t) / 0.15
                      : 1.0;
              return Positioned(
                left: MediaQuery.of(context).size.width * h.left,
                bottom: MediaQuery.of(context).size.height * t - h.size,
                child: Opacity(
                  opacity: (opacity * 0.15).clamp(0, 1), // Very subtle background glow
                  child: ImageFilterBlur(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.rose.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        '♥',
                        style: TextStyle(
                          fontSize: h.size,
                          color: AppTheme.rose.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
        widget.child,
      ],
    );
  }
}

// Utility for heavy blur wrapping
class ImageFilterBlur extends StatelessWidget {
  final Widget child;
  const ImageFilterBlur({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Soft bokeh effect backing hearts
      child: child,
    );
  }
}

// ── Shared UI Primitives ───────────────────────────────────────────────────────

/// App brand header: heart ♥ + gradient title + tagline
class BrandHeader extends StatelessWidget {
  final String tagline;
  const BrandHeader({super.key, required this.tagline});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('♥', style: const TextStyle(fontSize: 56, color: AppTheme.rose)),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.rose, AppTheme.roseDark],
          ).createShader(bounds),
          child: Text(
            'US.LOVE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(tagline, style: AppTheme.body(13)),
      ],
    );
  }
}

/// Velvet glassmorphism card (max 460px centred)
class VelvetCard extends StatelessWidget {
  final Widget child;
  const VelvetCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 460,
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
      child: child,
    );
  }
}

/// Small uppercase field label
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary.withOpacity(0.75),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Inline error row
class ErrorRow extends StatelessWidget {
  final String message;
  const ErrorRow(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.roseDark.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.roseDark.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.rose, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTheme.body(12, color: AppTheme.rose),
            ),
          ),
        ],
      ),
    );
  }
}
