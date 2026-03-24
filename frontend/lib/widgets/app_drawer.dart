import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/auth_provider.dart';
import '../core/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Drawer(
      backgroundColor: Colors.transparent,
      width: 280,
      child: Stack(
        children: [
          // Glass Blur Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bg1.withOpacity(0.7),
                border: Border(
                  right: BorderSide(
                    color: AppTheme.rose.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context, auth),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: Colors.white10),
                ),
                
                const SizedBox(height: 12),

                // Navigation Items
                _DrawerItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    context.go('/home');
                  },
                ),
                _DrawerItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: () {
                    // Placeholder for profile
                  },
                ),
                _DrawerItem(
                  icon: Icons.favorite_border_rounded,
                  label: 'Our Memories',
                  onTap: () {
                    // Placeholder for future feature
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    // Placeholder for settings
                  },
                ),

                const Spacer(),

                // Sign Out
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: Colors.white10),
                ),
                const SizedBox(height: 8),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  color: AppTheme.rose,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.bg3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('Sign Out?', style: AppTheme.display(20)),
                        content: Text(
                          'Are you sure you want to sign out?',
                          style: AppTheme.body(14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Cancel', style: AppTheme.body(14)),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx); // Close dialog
                              Navigator.pop(context); // Close drawer
                              await auth.logout();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                            child: Text(
                              'Sign Out',
                              style: AppTheme.body(14, color: AppTheme.rose),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.rose.withOpacity(0.3), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.bg3,
              child: Text(
                (auth.name != null && auth.name!.isNotEmpty)
                    ? auth.name![0].toUpperCase()
                    : 'U',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.rose,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.name ?? 'New User',
                  style: AppTheme.label(16).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  auth.email ?? '',
                  style: AppTheme.body(12, color: AppTheme.textSecondary.withOpacity(0.6)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: Colors.white.withOpacity(0.03),
        leading: Icon(
          icon,
          color: color ?? AppTheme.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: AppTheme.body(14, color: color ?? AppTheme.textPrimary),
        ),
      ),
    );
  }
}
