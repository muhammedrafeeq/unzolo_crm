import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/state/unzolo_state.dart';
import '../../core/responsive_utils.dart';

class TripBookingsPage extends ConsumerWidget {
  const TripBookingsPage({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed': return const Color(0xFF1E7E34);
      case 'Pending': return const Color(0xFFF59E0B);
      case 'Completed': return const Color(0xFF3B82F6);
      case 'Cancelled': return const Color(0xFFEF4444);
      default: return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};
    final bookingsAsync = ref.watch(bookingsProvider);
    final allBookings = bookingsAsync.value ?? [];
    final tripBookings = allBookings.where((b) => b['tripId'] == trip['id']).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Unzolo',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.tripExpenseLedger,
                          arguments: trip,
                        ),
                        icon: const Icon(LucideIcons.coins, size: 16, color: Colors.white),
                        label: const Text('Expenses', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.bell, color: AppColors.primary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: context.vPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip['title'] ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 14, color: AppColors.outline),
                      const SizedBox(width: 4),
                      Text(trip['location'] ?? '', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₹${trip['price']}',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'BOOKINGS (${tripBookings.length})',
              style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono'),
            ),
            const SizedBox(height: 12),
            if (tripBookings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.calendar, size: 48, color: AppColors.outlineVariant),
                      const SizedBox(height: 16),
                      const Text('No bookings for this trip yet.', style: TextStyle(color: AppColors.outline, fontSize: 15)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.createBooking),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        child: const Text('Create Booking'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tripBookings.length,
                itemBuilder: (context, index) {
                  final b = tripBookings[index];
                  final color = _statusColor(b['status'] ?? '');
                  return Card(
                    color: AppColors.surfaceContainerLowest,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.bookingDetails, arguments: b),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${b['membersCount'] ?? 1} members • ${b['dates'] ?? ''}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                b['status'] ?? '',
                                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
