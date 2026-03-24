import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../core/app_error.dart';

class PremiumErrorDialog extends StatefulWidget {
  final AppError error;
  final VoidCallback onDismiss;

  const PremiumErrorDialog({
    super.key,
    required this.error,
    required this.onDismiss,
  });

  @override
  State<PremiumErrorDialog> createState() => _PremiumErrorDialogState();
}

class _PremiumErrorDialogState extends State<PremiumErrorDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blur background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scale,
              child: FadeTransition(
                opacity: _opacity,
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.bg2.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppTheme.rose.withOpacity(0.1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                      BoxShadow(
                        color: AppTheme.rose.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIcon(),
                      const SizedBox(height: 24),
                      Text(
                        widget.error.title,
                        style: AppTheme.display(24).copyWith(
                          color: AppTheme.rose,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.error.message,
                        style: AppTheme.body(15, color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.error.technicalDetails != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.error.technicalDetails.toString(),
                            style: GoogleFonts.firaCode(
                              fontSize: 10,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      AppTheme.roseButton(
                        label: widget.error.onRetry != null ? 'Try Again' : 'Dismiss',
                        onTap: () {
                          if (widget.error.onRetry != null) {
                            widget.error.onRetry!();
                          }
                          widget.onDismiss();
                        },
                      ),
                      if (widget.error.onRetry != null) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: widget.onDismiss,
                          child: Text(
                            'Dismiss',
                            style: AppTheme.body(14, color: AppTheme.textSecondary.withOpacity(0.6)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    switch (widget.error.type) {
      case AppErrorType.network:
        iconData = Icons.wifi_off_rounded;
        break;
      case AppErrorType.server:
        iconData = Icons.dns_rounded;
        break;
      case AppErrorType.auth:
        iconData = Icons.lock_outline_rounded;
        break;
      case AppErrorType.timeout:
        iconData = Icons.timer_off_outlined;
        break;
      case AppErrorType.socket:
        iconData = Icons.sync_problem_rounded;
        break;
      case AppErrorType.unknown:
        iconData = Icons.error_outline_rounded;
        break;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.rose.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          iconData,
          color: AppTheme.rose,
          size: 40,
        ),
      ),
    );
  }
}
