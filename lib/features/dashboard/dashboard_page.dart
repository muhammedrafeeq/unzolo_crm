import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/state/unzolo_state.dart';
import '../../core/widgets/skeleton_loader.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final tripsAsync = ref.watch(tripsProvider);
    final bookingsAsync = ref.watch(bookingsProvider);

    final trips = tripsAsync.value ?? [];
    final bookings = bookingsAsync.value ?? [];
    final isLoading = tripsAsync.isLoading || bookingsAsync.isLoading;

    final activeBookings = bookings.where((b) => b['isActive'] == true).toList();
    final recentBookings = bookings.take(3).toList();

    final userName = auth.name ?? 'Agent';

    return SkeletonLoader(
      isLoading: isLoading,
      skeleton: const DashboardSkeleton(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            Text(
              'Good Morning, $userName',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your next mountain adventure is waiting. Here is your expedition status.',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16),
            ),
            const SizedBox(height: 28),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'TOTAL TRIPS',
                    value: '${trips.length}',
                    icon: LucideIcons.mountain,
                    iconBgColor: AppColors.primaryContainer,
                    iconColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'BOOKINGS',
                    value: '${activeBookings.length}',
                    icon: LucideIcons.ticket,
                    iconBgColor: AppColors.secondaryContainer,
                    iconColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Action Cards in grid
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    label: 'Bookings',
                    icon: LucideIcons.calendar,
                    isPrimary: true,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.manageBookings),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    context,
                    label: 'Trips',
                    icon: LucideIcons.map,
                    isPrimary: true,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.selectTrip),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    context,
                    label: 'Create Trip',
                    icon: LucideIcons.plus,
                    isPrimary: true,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.createTrip),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Recent Bookings Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Bookings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.manageBookings),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (recentBookings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    'No bookings yet.',
                    style: TextStyle(color: AppColors.outline),
                  ),
                ),
              )
            else
              ...recentBookings.map((booking) => _buildRecentBookingCard(context, booking)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'JetBrains Mono',
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    bool isPrimary = false,
    bool isSecondary = false,
    required VoidCallback onTap,
  }) {
    Color bgColor = AppColors.surfaceContainerLowest;
    Color textColor = AppColors.onSurfaceVariant;
    Border? border = Border.all(color: AppColors.outlineVariant);
    Color iconColor = AppColors.onSurfaceVariant;

    if (isPrimary) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
      border = null;
      iconColor = Colors.white;
    } else if (isSecondary) {
      bgColor = AppColors.surfaceContainerLowest;
      textColor = AppColors.primary;
      border = Border.all(color: AppColors.primary, width: 1.5);
      iconColor = AppColors.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: border,
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookingCard(BuildContext context, Map<String, dynamic> booking) {
    final status = (booking['status'] as String?) ?? 'Pending';
    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'Confirmed':
        statusColor = AppColors.primary;
        statusBg = AppColors.primaryContainer.withValues(alpha: 0.12);
        break;
      case 'Pending':
        statusColor = AppColors.secondary;
        statusBg = AppColors.secondaryContainer.withValues(alpha: 0.12);
        break;
      case 'Completed':
        statusColor = AppColors.tertiaryContainer;
        statusBg = AppColors.tertiaryContainer.withValues(alpha: 0.12);
        break;
      default:
        statusColor = AppColors.outline;
        statusBg = AppColors.surfaceContainerHigh;
    }

    final imageUrl = booking['imageUrl'] as String?;
    final amount = booking['amount'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.bookingDetails, arguments: booking),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['title'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Manrope',
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking['dates'] as String? ?? '',
                        style: const TextStyle(fontSize: 11, color: AppColors.outline, fontFamily: 'Manrope'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      amount,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface, fontFamily: 'JetBrains Mono'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: AppColors.surfaceContainerLow,
      child: const Icon(LucideIcons.mountain, color: AppColors.outline, size: 24),
    );
  }
}
