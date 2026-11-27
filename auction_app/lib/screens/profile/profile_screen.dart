import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final String username;
  final String email;
  final String fullName;

  final VoidCallback? onLogout;
  final VoidCallback? onMyListings;
  final VoidCallback? onMyBids;

  const ProfileScreen({
    super.key,
    this.username = 'User',
    this.email = 'user@example.com',
    this.fullName = 'Auction User',
    this.onLogout,
    this.onMyListings,
    this.onMyBids,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),

            const SizedBox(height: 24),

            _buildAccountSection(context),

            const SizedBox(height: 24),

            _buildActivitySection(context),

            const SizedBox(height: 24),

            _buildSettingsSection(context),

            const SizedBox(height: 24),

            _buildSupportSection(context),

            const SizedBox(height: 24),

            _buildLogoutButton(context),

            const SizedBox(height: 20),

            Center(
              child: Text(
                'Auction App • Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // PROFILE HEADER
  // --------------------------------------------------

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: AppTheme.navy.withValues(alpha: 0.1),
            child: Text(
              _getInitials(),
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '@$username',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            email,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user,
                  color: Colors.green,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Account Active',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfileDialog(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.navy,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                side: const BorderSide(
                  color: AppTheme.navy,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    final name = fullName.trim();

    if (name.isEmpty) {
      return 'U';
    }

    final parts = name.split(' ');

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return name.substring(0, 1).toUpperCase();
  }

  // --------------------------------------------------
  // ACCOUNT SECTION
  // --------------------------------------------------

  Widget _buildAccountSection(BuildContext context) {
    return _buildSection(
      title: 'Account',
      children: [
        _buildMenuItem(
          icon: Icons.person_outline,
          title: 'Personal Information',
          subtitle: 'Manage your account details',
          onTap: () => _showEditProfileDialog(context),
        ),

        _buildMenuItem(
          icon: Icons.security_outlined,
          title: 'Security',
          subtitle: 'Password and account security',
          onTap: () {
            _showMessage(
              context,
              'Security settings will be connected next.',
            );
          },
        ),
      ],
    );
  }

  // --------------------------------------------------
  // ACTIVITY SECTION
  // --------------------------------------------------

  Widget _buildActivitySection(BuildContext context) {
    return _buildSection(
      title: 'My Activity',
      children: [
        _buildMenuItem(
          icon: Icons.inventory_2_outlined,
          title: 'My Listings',
          subtitle: 'Manage your auction listings',
          onTap: onMyListings ?? () {
            _showMessage(
              context,
              'My Listings navigation is not connected yet.',
            );
          },
        ),

        _buildMenuItem(
          icon: Icons.gavel,
          title: 'My Bids',
          subtitle: 'View your bidding history',
          onTap: onMyBids ?? () {
            _showMessage(
              context,
              'My Bids navigation is not connected yet.',
            );
          },
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SETTINGS
  // --------------------------------------------------

  Widget _buildSettingsSection(BuildContext context) {
    return _buildSection(
      title: 'Preferences',
      children: [
        _buildMenuItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Auction updates and reminders',
          onTap: () {
            _showMessage(
              context,
              'Notification settings will be added later.',
            );
          },
        ),

        _buildMenuItem(
          icon: Icons.language,
          title: 'Language',
          subtitle: 'English',
          onTap: () {
            _showMessage(
              context,
              'Language selection will be added later.',
            );
          },
        ),

        _buildMenuItem(
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: 'Theme preferences',
          onTap: () {
            _showMessage(
              context,
              'Theme settings will be added later.',
            );
          },
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SUPPORT
  // --------------------------------------------------

  Widget _buildSupportSection(BuildContext context) {
    return _buildSection(
      title: 'Support',
      children: [
        _buildMenuItem(
          icon: Icons.help_outline,
          title: 'Help Center',
          subtitle: 'Frequently asked questions',
          onTap: () {
            _showSupportDialog(context);
          },
        ),

        _buildMenuItem(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'About our auction platform',
          onTap: () {
            _showAboutDialog(context);
          },
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SECTION CONTAINER
  // --------------------------------------------------

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: 12,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // MENU ITEM
  // --------------------------------------------------

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.navy,
                  size: 21,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // EDIT PROFILE DIALOG
  // --------------------------------------------------

  void _showEditProfileDialog(BuildContext context) {
    // This is currently a UI placeholder.
    // The backend update endpoint will be connected later.

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: const Text(
            'Profile editing will be connected to your backend '
            'in the next development step.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // SUPPORT DIALOG
  // --------------------------------------------------

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Text(
            'Need assistance using the auction platform? '
            'Support functionality will be connected here.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // ABOUT DIALOG
  // --------------------------------------------------

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auction App',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              SizedBox(height: 10),

              Text(
                'A platform for discovering, bidding on, '
                'and managing auction listings.',
              ),

              SizedBox(height: 12),

              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(
          Icons.logout,
          color: Colors.red,
        ),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          side: BorderSide(
            color: Colors.red.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                if (onLogout != null) {
                  onLogout!();
                } else {
                  _showMessage(
                    context,
                    'Logout action is not connected yet.',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // MESSAGE
  // --------------------------------------------------

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
