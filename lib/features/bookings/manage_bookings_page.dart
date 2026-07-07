import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/widgets/premium_filter_chip.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/state/unzolo_state.dart';

class ManageBookingsPage extends ConsumerStatefulWidget {
  const ManageBookingsPage({super.key});

  @override
  ConsumerState<ManageBookingsPage> createState() => _ManageBookingsPageState();
}

class _ManageBookingsPageState extends ConsumerState<ManageBookingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedTripId = 'all';
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _getCollectedAmount(Map<String, dynamic> booking) {
    if (booking['transactions'] == null) return 0.0;
    double sum = 0.0;
    for (var tx in booking['transactions']) {
      sum += (tx['amount'] as num).toDouble();
    }
    return sum;
  }

  double _getTotalAmount(Map<String, dynamic> booking) {
    final amtStr = (booking['amount'] as String).replaceAll('₹', '').replaceAll(',', '');
    return double.tryParse(amtStr) ?? 1000.0;
  }

  void _showDeactivatedBookingsDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final deactivated = ref.watch(deactivatedBookingsProvider).value ?? [];
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Deactivated Bookings Log',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: AppColors.primary, 
                          fontFamily: 'Manrope',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (deactivated.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No deactivated bookings found.',
                          style: TextStyle(color: AppColors.outline, fontFamily: 'Manrope'),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: deactivated.length,
                        itemBuilder: (context, index) {
                          final booking = deactivated[index];
                          return Card(
                            color: AppColors.surfaceContainerLowest,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.outlineVariant),
                            ),
                            child: ListTile(
                              title: Text(
                                booking['title'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Manrope'),
                              ),
                              subtitle: Text(
                                'ID: ${booking['id']} • Amount: ${booking['amount']}',
                                style: const TextStyle(fontSize: 12, fontFamily: 'Manrope'),
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () async {
                                  await ref.read(deactivatedBookingsProvider.notifier).recoverBooking(booking['id']);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Booking ${booking['id']} restored successfully!'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                                icon: const Icon(LucideIcons.rotateCcw, size: 14, color: Colors.white),
                                label: const Text('Recover', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(80, 32),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _exportPassengerManifest(List<Map<String, dynamic>> bookings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Passenger Manifest PDF', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Compiling active traveler registers, contact cards, and medical logs for selected expeditions...',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Active Expeditions:', style: TextStyle(fontSize: 12)),
                        Text('${bookings.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Manifest Count:', style: TextStyle(fontSize: 12)),
                        Text(
                          '${bookings.fold<int>(0, (sum, b) => sum + (b['membersCount'] as int? ?? 1))}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passenger Manifest PDF exported & saved to Downloads!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: const Icon(LucideIcons.fileSpreadsheet, size: 16, color: Colors.white),
              label: const Text('Save PDF Document'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final bookingsList = bookingsAsync.value ?? [];
    final trips = ref.watch(tripsProvider).value ?? [];

    // Calculate Stats
    double totalCollected = 0.0;
    double pendingBalances = 0.0;
    int confirmedSlots = 0;
    int advancePaidCount = 0;
    int fullyPaidCount = 0;

    for (var b in bookingsList) {
      final double total = _getTotalAmount(b);
      final double paid = _getCollectedAmount(b);
      totalCollected += paid;
      pendingBalances += (total - paid);

      if (b['status'] == 'Confirmed' || b['status'] == 'Completed') {
        confirmedSlots += (b['membersCount'] as int? ?? 0);
      }

      if (paid >= total) {
        fullyPaidCount++;
      } else if (paid > 0) {
        advancePaidCount++;
      }
    }

    // Filtered bookings
    final filteredBookings = bookingsList.where((b) {
      final matchesQuery = b['title'].toString().toLowerCase().contains(_searchQuery) ||
          b['id'].toString().toLowerCase().contains(_searchQuery);

      final matchesStatus = _selectedStatus == 'All' ||
          b['status'].toString().toLowerCase() == _selectedStatus.toLowerCase();

      final matchesTrip = _selectedTripId == 'all' ||
          b['tripId'].toString() == _selectedTripId;

      return matchesQuery && matchesStatus && matchesTrip;
    }).toList();

    return SkeletonLoader(
      isLoading: bookingsAsync.isLoading,
      skeleton: const BookingsSkeleton(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title block
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Registry',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Monitor traveler transactions and ledger balances.',
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.fileText, color: AppColors.primary),
                  onPressed: () => _exportPassengerManifest(filteredBookings),
                  tooltip: 'Export Passenger Manifest',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Trip filter options
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              padding: const EdgeInsets.all(4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTripOption('all', 'All'),
                    ...trips.map((t) => _buildTripOption(t['id'] as String, t['title'] as String)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Grid Card
            _buildStatsCard(confirmedSlots, advancePaidCount, fullyPaidCount, totalCollected, pendingBalances),
            const SizedBox(height: 24),

            // Search & Filter Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search booking ledger by ID or peak',
                  border: InputBorder.none,
                  icon: Icon(LucideIcons.search, color: AppColors.outline),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Status Filter Chips + Archive Row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', 'Confirmed', 'Pending', 'Completed', 'Partially Cancelled', 'Cancelled'].map((status) {
                        final isActive = _selectedStatus == status;
                        return PremiumFilterChip(
                          label: status,
                          isActive: isActive,
                          onTap: () {
                            setState(() {
                              _selectedStatus = status;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.archive, color: AppColors.outline),
                  onPressed: _showDeactivatedBookingsDrawer,
                  tooltip: 'Deactivated Bookings Archive',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // List of Bookings
            if (filteredBookings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text('No bookings match the active filter criteria.', style: TextStyle(color: AppColors.outline)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredBookings.length,
                itemBuilder: (context, index) {
                  final booking = filteredBookings[index];
                  return _buildBookingCard(booking);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripOption(String id, String label) {
    final isActive = _selectedTripId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedTripId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'Manrope',
            color: isActive ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(int slots, int advCount, int fullCount, double collected, double pending) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EXPEDITIONS METRICS OVERVIEW', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono')),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricSub('Slots Confirmed', '$slots'),
              _buildMetricSub('Advance Paid', '$advCount'),
              _buildMetricSub('Settled Booking', '$fullCount'),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Funds Collected', style: TextStyle(color: AppColors.outline, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('₹${collected.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E7E34), fontFamily: 'JetBrains Mono')),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Outstanding Balance', style: TextStyle(color: AppColors.outline, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('₹${pending.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error, fontFamily: 'JetBrains Mono')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSub(String title, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.outline)),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] as String? ?? 'Pending';
    final isConfirmed = status == 'Confirmed' || status == 'Completed';
    final isCancelled = status == 'Cancelled' || status == 'Partially Cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.bookingDetails, arguments: booking['id']),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking['id'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono', color: AppColors.primary, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? AppColors.error.withValues(alpha: 0.1)
                          : isConfirmed
                              ? const Color(0xFFE2F3E2)
                              : const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isCancelled
                            ? AppColors.error
                            : isConfirmed
                                ? const Color(0xFF1E7E34)
                                : const Color(0xFF856404),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                booking['title'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
              ),
              const SizedBox(height: 4),
              Text(
                'Schedule: ${booking['dates']} • Travelers: ${booking['membersCount']}',
                style: const TextStyle(color: AppColors.outline, fontSize: 12),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Cost', style: TextStyle(color: AppColors.outline, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(booking['amount'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'JetBrains Mono')),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'details') {
                        Navigator.pushNamed(context, AppRoutes.bookingDetails, arguments: booking['id']);
                      } else if (val == 'deactivate') {
                        await ref.read(bookingsProvider.notifier).deactivateBooking(booking['id']);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Booking ${booking['id']} deactivated & archived.'),
                            backgroundColor: AppColors.error,
                            action: SnackBarAction(
                              label: 'UNDO',
                              textColor: Colors.white,
                              onPressed: () async {
                                final deactivated = ref.read(deactivatedBookingsProvider).value ?? [];
                                if (deactivated.isNotEmpty) {
                                  await ref.read(deactivatedBookingsProvider.notifier).recoverBooking(deactivated.last['id']);
                                }
                              },
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'details', child: Text('Open File Ledger')),
                      const PopupMenuItem(value: 'deactivate', child: Text('Cancel & Deactivate')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Mock Skeleton class for loading state
class BookingsSkeleton extends StatelessWidget {
  const BookingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        children: [
          Divider(),
        ],
      ),
    );
  }
}
