import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/state/unzolo_state.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/responsive_utils.dart';

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final trips = tripsAsync.value ?? [];
    final bookings = ref.watch(bookingsProvider).value ?? [];
    final expenses = expensesAsync.value ?? [];
    final isLoading = tripsAsync.isLoading || expensesAsync.isLoading;

    return SkeletonLoader(
      isLoading: isLoading,
      skeleton: const ExpensesSkeleton(),
      child: SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: context.vPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              Text(
                'Expeditions Ledgers',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select an active or completed trip expedition below to inspect and manage operating expense ledgers.',
                style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 24),

              if (trips.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: Text('No trip expeditions available in system ledger.', style: TextStyle(color: AppColors.outline)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    final String tripId = trip['id'];

                    // Calculate status indicator (upcoming vs completed)
                    bool isCompleted = false;
                    if (trip['endDate'] != null) {
                      final end = DateTime.tryParse(trip['endDate']);
                      if (end != null && end.isBefore(DateTime.now())) {
                        isCompleted = true;
                      }
                    }

                    // Calculate metrics
                    final tripBookings = bookings.where((b) => b['tripId'] == tripId).toList();
                    double totalRevenues = 0.0;
                    for (var b in tripBookings) {
                      if (b['transactions'] != null) {
                        for (var tx in b['transactions']) {
                          totalRevenues += (tx['amount'] as num).toDouble();
                        }
                      }
                    }

                    final tripExpenses = expenses.where((e) => e['tripId'] == tripId).toList();
                    final double totalExpenses = tripExpenses.fold<double>(0.0, (sum, e) => sum + (e['amount'] as num).toDouble());

                    return Card(
                      color: AppColors.surfaceContainerLowest,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.tripExpenseLedger,
                            arguments: trip,
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCompleted 
                                          ? AppColors.surfaceContainer
                                          : const Color(0xFFE2F3E2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isCompleted ? 'COMPLETED' : 'UPCOMING / ACTIVE',
                                      style: TextStyle(
                                        color: isCompleted 
                                            ? AppColors.outline
                                            : const Color(0xFF1E7E34),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                    ),
                                  ),
                                  Text(
                                    trip['category'] ?? 'Camp',
                                    style: const TextStyle(color: AppColors.outline, fontSize: 11, fontFamily: 'JetBrains Mono'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                trip['title'],
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(LucideIcons.mapPin, size: 14, color: AppColors.outline),
                                  const SizedBox(width: 6),
                                  Text(trip['location'], style: const TextStyle(color: AppColors.outline, fontSize: 12)),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Recorded Revenue', style: TextStyle(color: AppColors.outline, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${totalRevenues.toInt()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E7E34), fontFamily: 'JetBrains Mono'),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Accrued Expenses', style: TextStyle(color: AppColors.outline, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${totalExpenses.toInt()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.error, fontFamily: 'JetBrains Mono'),
                                      ),
                                    ],
                                  ),
                                ],
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
