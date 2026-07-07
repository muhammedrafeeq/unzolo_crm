import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';

import '../../core/widgets/skeleton_loader.dart';
import '../../core/responsive_utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      isLoading: _isLoading,
      skeleton: const ProfileSkeleton(),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: context.vPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Hero Banner Card
            _buildProfileHeroCard(context),
            const SizedBox(height: 24),
  
            // Bento Stats Grid (Peaks scaled, distance, saved)
            _buildBentoStatsGrid(context),
            const SizedBox(height: 32),
  
            // Settings Categories List
            Text(
              'Expedition Hub'.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.05,
                  ),
            ),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildSettingsOption(
                icon: LucideIcons.calendar,
                title: 'My Bookings',
                subtitle: 'View and track your expedition history',
                onTap: () => Navigator.pushNamed(context, AppRoutes.manageBookings),
              ),
              _buildSettingsOption(
                icon: LucideIcons.messageSquare,
                title: 'Manage Enquiries',
                subtitle: 'Review customer inquiries and convert to bookings',
                onTap: () => Navigator.pushNamed(context, AppRoutes.enquiries),
              ),
              _buildSettingsOption(
                icon: LucideIcons.checkSquare,
                title: 'Gear Checklist',
                subtitle: 'Make sure you have all required mountain gear',
                onTap: () {},
              ),
              _buildSettingsOption(
                icon: LucideIcons.wind,
                title: 'Weather & Safety Alerts',
                subtitle: 'Live expedition weather updates',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 28),
  
            Text(
              'Account Settings'.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.05,
                  ),
            ),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildSettingsOption(
                icon: LucideIcons.user,
                title: 'Personal Information',
                subtitle: 'Update your profile and email details',
                onTap: () {},
              ),
              _buildSettingsOption(
                icon: LucideIcons.phoneCall,
                title: 'Emergency Contacts',
                subtitle: 'Configure emergency notification settings',
                onTap: () {},
              ),
              _buildSettingsOption(
                icon: LucideIcons.logOut,
                title: 'Log Out',
                isError: true,
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Edit Avatar Stack
          Stack(
            children: [
              Container(
                width: context.rAvatar(90),
                height: context.rAvatar(90),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCeMYIWy9aFlr4UmTFih39PaySc11Z6OIwCmxOxNt4bnC-GY2SB3OHzmdt3GjBIHOjSymPmefKyoXdCIQTRm259a0DgVaT2gCbU3nE0amT2Bm-XwPxy4hYEOT43UizPHdqLgsxq2vHm5fXZdrps9AOO1mk-_XPwYiX_yXlDnOa2mHoVqc8ww95HVl6HkKD9J0ClVxLkKGNFei08Xi5H5kOPR2fhJUsxU7b7iJHO9zFzYZBXAEQ2O2Xy-5VLz8ACi-VBtSpkzIhroYyb',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.edit2, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Alex Rivera',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Space Grotesk',
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Elite Explorer • Joined Mar 2023',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '"Conquering heights, discovering horizons."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.onSurfaceVariant,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoStatsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildBentoStatItem(
            context,
            icon: LucideIcons.mountain,
            value: '12',
            label: 'Peaks Scaled',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBentoStatItem(
            context,
            icon: LucideIcons.footprints,
            value: '240 km',
            label: 'Distance',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBentoStatItem(
            context,
            icon: LucideIcons.bookmark,
            value: '5',
            label: 'Saved Trips',
          ),
        ),
      ],
    );
  }

  Widget _buildBentoStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrains Mono',
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.outline,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> options) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            options[i],
            if (i < options.length - 1)
              const Divider(color: AppColors.surfaceContainer, height: 1, indent: 56),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isError = false,
    required VoidCallback onTap,
  }) {
    final color = isError ? AppColors.error : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isError ? AppColors.error : AppColors.onSurface,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.outline,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
