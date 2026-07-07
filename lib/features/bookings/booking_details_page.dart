import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/state/unzolo_state.dart';

class BookingDetailsPage extends ConsumerStatefulWidget {
  const BookingDetailsPage({super.key});

  @override
  ConsumerState<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends ConsumerState<BookingDetailsPage> {
  bool _copied = false;
  String? _bookingId;
  Map<String, dynamic>? _fallbackBooking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      if (args is String) {
        _bookingId = args;
      } else if (args is Map<String, dynamic>) {
        _fallbackBooking = args;
        _bookingId = args['id'] as String?;
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      setState(() {
        _copied = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _copied = false;
          });
        }
      });
    });
  }

  double _getCollectedAmount(Map<String, dynamic> booking) {
    if (booking['transactions'] == null) return 0.0;
    double sum = 0.0;
    for (var tx in booking['transactions']) {
      final isRefund = (tx['type'] as String?)?.toLowerCase() == 'refund';
      if (!isRefund) sum += (tx['amount'] as num).toDouble();
    }
    return sum;
  }

  double _getRefundedAmount(Map<String, dynamic> booking) {
    if (booking['transactions'] == null) return 0.0;
    double sum = 0.0;
    for (var tx in booking['transactions']) {
      final isRefund = (tx['type'] as String?)?.toLowerCase() == 'refund';
      if (isRefund) sum += (tx['amount'] as num).toDouble();
    }
    return sum;
  }

  double _getTotalAmount(Map<String, dynamic> booking) {
    final amtStr = (booking['amount'] as String).replaceAll('₹', '').replaceAll(',', '');
    return double.tryParse(amtStr) ?? 1000.0;
  }

  void _showAddPaymentDrawer(Map<String, dynamic> booking) {
    final total = _getTotalAmount(booking);
    final paid = _getCollectedAmount(booking);
    final remaining = total - paid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AddPaymentDrawerContent(
          remainingAmount: remaining,
          onConfirm: (double amount, String method, String type, String? screenshot) async {
            final List<dynamic> updatedTxs = List.from(booking['transactions'] ?? []);
            updatedTxs.add({
              'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
              'amount': amount,
              'method': method,
              'type': type,
              'screenshot': screenshot,
            });

            final updatedCollected = paid + amount;
            final isFullyPaid = updatedCollected >= total;

            final updatedBooking = {
              ...booking,
              'transactions': updatedTxs,
              'collected': updatedCollected,
              'totalCollected': updatedCollected,
              'status': isFullyPaid ? 'Confirmed' : 'Pending',
            };

            await ref.read(bookingsProvider.notifier).updateBooking(updatedBooking);

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Recorded payment of ₹${amount.toInt()} successfully!'),
                backgroundColor: AppColors.primary,
              ),
            );
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showCancellationDrawer(Map<String, dynamic> booking) {
    final members = (booking['members'] as List? ?? [])
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final double total = _getTotalAmount(booking);
    final double paid = _getCollectedAmount(booking);
    final int totalCount = members.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CancellationDrawerContent(
        members: members,
        totalAmount: total,
        paidAmount: paid,
        onConfirm: (
          List<int> cancelledIndexes,
          double refundAmount,
          String method,
          String reason,
          String? screenshot,
        ) async {
          final List<dynamic> updatedTxs = List.from(booking['transactions'] ?? []);
          updatedTxs.add({
            'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'amount': refundAmount,
            'method': method,
            'type': 'Refund',
            'screenshot': screenshot,
            'note': 'Cancellation: $reason',
          });

          final int remaining = totalCount - cancelledIndexes.length;
          final bool fullCancellation = remaining <= 0;

          // Remove cancelled members
          final updatedMembers = [
            for (int i = 0; i < members.length; i++)
              if (!cancelledIndexes.contains(i)) members[i],
          ];

          final double perPerson = totalCount > 0 ? total / totalCount : 0;
          final double newTotal = fullCancellation ? 0 : perPerson * remaining;

          final updatedBooking = {
            ...booking,
            'transactions': updatedTxs,
            'members': updatedMembers,
            'membersCount': remaining,
            'amount': fullCancellation ? '₹0' : '₹${newTotal.toInt()}',
            'status': fullCancellation ? 'Cancelled' : 'Partially Cancelled',
          };

          await ref.read(bookingsProvider.notifier).updateBooking(updatedBooking);

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(fullCancellation
                  ? 'Booking fully cancelled. Refund of ₹${refundAmount.toInt()} recorded.'
                  : '${cancelledIndexes.length} traveler(s) cancelled. Refund of ₹${refundAmount.toInt()} recorded.'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showWhatsAppCommunicatorDrawer(Map<String, dynamic> booking) {
    final primaryName = booking['members'] != null && (booking['members'] as List).isNotEmpty
        ? booking['members'][0]['name'] as String
        : 'Traveler';
    final primaryPhone = booking['members'] != null && (booking['members'] as List).isNotEmpty
        ? booking['members'][0]['phone'] as String
        : '';
    final total = _getTotalAmount(booking);
    final paid = _getCollectedAmount(booking);
    final remaining = total - paid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _WhatsAppDrawerContent(
          bookingId: booking['id'],
          tripTitle: booking['title'],
          travelerName: primaryName,
          travelerPhone: primaryPhone,
          paid: paid,
          remaining: remaining,
        );
      },
    );
  }

  void _showEditTravelersDrawer(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _EditTravelersDrawerContent(
          booking: booking,
          onUpdateMembers: (List<Map<String, dynamic>> updatedMembers) async {
            // Recalculate price if traveler count changes
            final int originalCount = (booking['members'] as List).length;
            final int newCount = updatedMembers.length;

            String newAmountStr = booking['amount'];
            if (newCount != originalCount && newCount > 0) {
              final double singlePrice = _getTotalAmount(booking) / originalCount;
              final double newPrice = singlePrice * newCount;
              newAmountStr = '₹${newPrice.toInt()}';
            }

            final updatedBooking = {
              ...booking,
              'membersCount': newCount,
              'members': updatedMembers,
              'amount': newAmountStr,
            };

            await ref.read(bookingsProvider.notifier).updateBooking(updatedBooking);

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Travelers list updated successfully!'),
                backgroundColor: AppColors.primary,
              ),
            );
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(bookingsProvider).value ?? [];
    final activeBooking = bookings.firstWhere(
      (b) => b['id'] == _bookingId,
      orElse: () => _fallbackBooking ?? bookings.first,
    );

    final double total = _getTotalAmount(activeBooking);
    final double paid = _getCollectedAmount(activeBooking);
    final double remaining = total - paid;
    final members = activeBooking['members'] as List? ?? [];
    final transactions = activeBooking['transactions'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Booking Ledger File',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Manrope'),
        ),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.messageSquare, color: AppColors.primary),
            onPressed: () => _showWhatsAppCommunicatorDrawer(activeBooking),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Booking summary header card
              _buildHeaderSummaryCard(activeBooking, paid, total),
              const SizedBox(height: 24),

              // Ledger overview card
              _buildLedgerOverviewCard(activeBooking, total, paid, remaining),
              const SizedBox(height: 24),

              // Members card
              _buildMembersCard(members, activeBooking),
              const SizedBox(height: 24),

              // Transaction logs timeline
              _buildTransactionsCard(transactions),
              const SizedBox(height: 32),

              // Actions buttons
              ElevatedButton.icon(
                onPressed: () => _showAddPaymentDrawer(activeBooking),
                icon: const Icon(LucideIcons.plusCircle, size: 20, color: Colors.white),
                label: const Text('Add Secondary Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showEditTravelersDrawer(activeBooking),
                icon: const Icon(LucideIcons.users, size: 20, color: AppColors.primary),
                label: const Text('Manage & Edit Travelers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showCancellationDrawer(activeBooking),
                icon: const Icon(LucideIcons.xCircle, size: 20, color: AppColors.error),
                label: const Text('Cancel & Refund', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSummaryCard(Map<String, dynamic> booking, double paid, double total) {
    final status = booking['status'] as String? ?? 'Pending';
    final isConfirmed = status == 'Confirmed' || status == 'Completed';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BOOKING ID', style: TextStyle(color: AppColors.outline, fontSize: 10, fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        booking['id'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(_copied ? LucideIcons.check : LucideIcons.copy, size: 16, color: _copied ? AppColors.primary : AppColors.outline),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () => _copyToClipboard(booking['id']),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isConfirmed 
                      ? const Color(0xFFE2F3E2) 
                      : const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isConfirmed 
                        ? const Color(0xFF1E7E34) 
                        : const Color(0xFF856404),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            booking['title'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Space Grotesk'),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 14, color: AppColors.outline),
              const SizedBox(width: 6),
              Text(
                booking['dates'] ?? 'Custom Schedule',
                style: const TextStyle(color: AppColors.outline, fontSize: 12, fontFamily: 'Manrope'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerOverviewCard(Map<String, dynamic> booking, double total, double paid, double remaining) {
    final double refunded = _getRefundedAmount(booking);
    final double concession = (booking['concessionAmount'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FINANCIAL LEDGER OVERVIEW',
            style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono'),
          ),
          const SizedBox(height: 20),
          _ledgerRow('Total Package Price', '₹${total.toInt()}', valueColor: AppColors.onSurface),
          const SizedBox(height: 10),
          _ledgerRow('Paid So Far', '₹${paid.toInt()}', valueColor: AppColors.primary),
          if (concession > 0) ...[
            const SizedBox(height: 10),
            _ledgerRow('Concession Applied', '− ₹${concession.toInt()}', valueColor: const Color(0xFF1E7E34)),
          ],
          if (refunded > 0) ...[
            const SizedBox(height: 10),
            _ledgerRow('Refunded Amount', '− ₹${refunded.toInt()}', valueColor: AppColors.error),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Remaining Balance Due', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(
                '₹${remaining.toInt()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: remaining > 0 ? AppColors.error : const Color(0xFF1E7E34),
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ledgerRow(String label, String value, {required Color valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.outline, fontSize: 13)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor, fontFamily: 'JetBrains Mono')),
      ],
    );
  }

  Widget _buildMembersCard(List<dynamic> members, Map<String, dynamic> booking) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TRAVELER REGISTRY',
                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono'),
              ),
              Text(
                '${members.length} Registered',
                style: const TextStyle(color: AppColors.outline, fontSize: 11, fontFamily: 'JetBrains Mono'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final member = members[index];
              return Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    radius: 18,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'JetBrains Mono'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['name'] ?? 'Attendee Name',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Age: ${member['age']} • Gender: ${member['gender']} • ${member['phone'] ?? ''}',
                          style: const TextStyle(color: AppColors.outline, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsCard(List<dynamic> transactions) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRANSACTION AUDIT LOG',
            style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono'),
          ),
          const SizedBox(height: 20),
          if (transactions.isEmpty)
            const Center(child: Text('No transactions recorded yet.', style: TextStyle(color: AppColors.outline)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.checkCircle, color: Color(0xFF1E7E34), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${tx['type']} via ${tx['method']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '₹${(tx['amount'] as num).toInt()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'JetBrains Mono'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Recorded on ${tx['date']}',
                            style: const TextStyle(color: AppColors.outline, fontSize: 11),
                          ),
                          if (tx['screenshot'] != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(LucideIcons.image, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  tx['screenshot'],
                                  style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AddPaymentDrawerContent extends StatefulWidget {
  final double remainingAmount;
  final Function(double amountPaid, String method, String type, String? screenshot) onConfirm;

  const _AddPaymentDrawerContent({
    required this.remainingAmount,
    required this.onConfirm,
  });

  @override
  State<_AddPaymentDrawerContent> createState() => _AddPaymentDrawerContentState();
}

class _AddPaymentDrawerContentState extends State<_AddPaymentDrawerContent> {
  final _amountController = TextEditingController();
  String _paymentMethod = 'GPay';
  String _paymentType = 'Final Payment';
  String? _screenshotName;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.remainingAmount.toInt().toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Record Secondary Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Manrope'),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _paymentType,
            style: const TextStyle(fontSize: 14, color: AppColors.onSurface, fontFamily: 'Manrope'),
            decoration: const InputDecoration(
              labelText: 'Transaction Ledger Category',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Final Payment', child: Text('Final Payment Settlement')),
              DropdownMenuItem(value: 'Partial Payment', child: Text('Installment / Partial Payment')),
              DropdownMenuItem(value: 'Add-on Charge', child: Text('Add-on / Extra Charges')),
              DropdownMenuItem(value: 'Refund', child: Text('Refund')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _paymentType = val;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _paymentMethod,
            style: const TextStyle(fontSize: 14, color: AppColors.onSurface, fontFamily: 'Manrope'),
            decoration: const InputDecoration(
              labelText: 'Payment Channel Channel',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'GPay', child: Text('Google Pay (GPay)')),
              DropdownMenuItem(value: 'PhonePe', child: Text('PhonePe')),
              DropdownMenuItem(value: 'UPI', child: Text('UPI Transfer')),
              DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Wire Transfer')),
              DropdownMenuItem(value: 'Cash', child: Text('Cash Handover')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _paymentMethod = val;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16, fontFamily: 'JetBrains Mono'),
            decoration: const InputDecoration(
              labelText: 'Amount Received (₹)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: () {
              setState(() {
                _screenshotName = 'receipt_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.png';
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surfaceContainerLow,
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.camera, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _screenshotName ?? 'Upload Image Screenshot',
                      style: TextStyle(
                        fontSize: 13,
                        color: _screenshotName == null ? AppColors.outline : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_screenshotName != null)
                    const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              final double amt = double.tryParse(_amountController.text) ?? 0.0;
              if (amt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid amount.')));
                return;
              }
              widget.onConfirm(amt, _paymentMethod, _paymentType, _screenshotName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppDrawerContent extends StatelessWidget {
  final String bookingId;
  final String tripTitle;
  final String travelerName;
  final String travelerPhone;
  final double paid;
  final double remaining;

  const _WhatsAppDrawerContent({
    required this.bookingId,
    required this.tripTitle,
    required this.travelerName,
    required this.travelerPhone,
    required this.paid,
    required this.remaining,
  });

  void _triggerTemplateShare(BuildContext context, String text) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Template Copied! Triggering WhatsApp API to $travelerPhone...'),
          backgroundColor: AppColors.primary,
        ),
      );
      navigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final confirmationText = 'Hi $travelerName,\nYour booking for "$tripTitle" has been Confirmed!\nBooking ID: $bookingId\nCollected Paid: ₹${paid.toInt()}\nPending Balance Due: ₹${remaining.toInt()}.\nThank you for choosing Unzolo CRM!';
    final reminderText = 'Hi $travelerName,\nThis is a payment due reminder for "$tripTitle".\nBooking ID: $bookingId\nPending Balance Due: ₹${remaining.toInt()}.\nPlease settle this as soon as possible to secure your slot.\nBest,\nUnzolo CRM';
    final cancellationText = 'Hi $travelerName,\nYour booking ($bookingId) for "$tripTitle" has been Cancelled.\nRefunds (if applicable) will be processed in 5-7 business days.\nRegards,\nUnzolo CRM';

    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'WhatsApp Communicator Templates',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Manrope'),
              ),
              IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Recipients Phone Number:', style: TextStyle(color: AppColors.outline, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(travelerPhone.isEmpty ? 'Not Provided' : travelerPhone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 20),

          // Template 1: Confirmation
          _buildTemplateCard(context, 'Booking Confirmation', confirmationText),
          const SizedBox(height: 16),

          // Template 2: Balance Due Reminder
          _buildTemplateCard(context, 'Payment Balance Reminder', reminderText),
          const SizedBox(height: 16),

          // Template 3: Cancellation Notice
          _buildTemplateCard(context, 'Booking Cancellation Notice', cancellationText),
          const SizedBox(height: 24),
        ],
      ),
    ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, String title, String body) {
    return Card(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
              child: Text(body, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, height: 1.4)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _triggerTemplateShare(context, body),
              icon: const Icon(LucideIcons.messageSquare, size: 14, color: Colors.white),
              label: const Text('Send to WhatsApp / Copy', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditTravelersDrawerContent extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Function(List<Map<String, dynamic>> updatedMembers) onUpdateMembers;

  const _EditTravelersDrawerContent({
    required this.booking,
    required this.onUpdateMembers,
  });

  @override
  State<_EditTravelersDrawerContent> createState() => _EditTravelersDrawerContentState();
}

class _EditTravelersDrawerContentState extends State<_EditTravelersDrawerContent> {
  late List<Map<String, dynamic>> _members;

  @override
  void initState() {
    super.initState();
    final original = widget.booking['members'] as List? ?? [];
    _members = original.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  void _removeMember(int index) {
    if (_members.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot cancel the primary lead traveler from a booking file. Deactivate the booking instead.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Traveler', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to cancel ${_members[index]['name']} from this booking? This will adjust pricing accordingly.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No, Back'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _members.removeAt(index);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: const Text('Cancel Traveler'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Travelers Registry',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Manrope'),
              ),
              IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return Card(
                  color: AppColors.surfaceContainerLowest,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: Colors.white,
                          child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                initialValue: member['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                decoration: const InputDecoration(labelText: 'Name', border: InputBorder.none),
                                onChanged: (val) {
                                  _members[index]['name'] = val;
                                },
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: member['age'],
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(labelText: 'Age', border: InputBorder.none),
                                      onChanged: (val) {
                                        _members[index]['age'] = val;
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: member['gender'],
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(labelText: 'Gender', border: InputBorder.none),
                                      onChanged: (val) {
                                        _members[index]['gender'] = val;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.userMinus, color: AppColors.error),
                          onPressed: () => _removeMember(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () => widget.onUpdateMembers(_members),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save & Apply Adjustments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Cancellation & Refund Drawer ───────────────────────────────────────────

class _CancellationDrawerContent extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final double totalAmount;
  final double paidAmount;
  final Function(
    List<int> cancelledIndexes,
    double refundAmount,
    String method,
    String reason,
    String? screenshot,
  ) onConfirm;

  const _CancellationDrawerContent({
    required this.members,
    required this.totalAmount,
    required this.paidAmount,
    required this.onConfirm,
  });

  @override
  State<_CancellationDrawerContent> createState() => _CancellationDrawerContentState();
}

class _CancellationDrawerContentState extends State<_CancellationDrawerContent> {
  final Set<int> _selected = {};
  late TextEditingController _refundController;
  String _method = 'GPay';
  String _reason = 'Changed Plans';
  String? _screenshot;

  static const _reasons = [
    'Changed Plans',
    'Medical Emergency',
    'Work Commitment',
    'Price Concern',
    'Weather / Force Majeure',
    'Other',
  ];

  static const _methods = ['GPay', 'PhonePe', 'UPI', 'Bank Transfer', 'Cash'];

  @override
  void initState() {
    super.initState();
    _refundController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _refundController.dispose();
    super.dispose();
  }

  void _recalcRefund() {
    if (widget.members.isEmpty) return;
    final perPerson = widget.paidAmount / widget.members.length;
    final suggested = (perPerson * _selected.length).toInt();
    _refundController.text = suggested.toString();
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selected.length == widget.members.length;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 50,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cancel & Refund',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.error, fontFamily: 'Manrope'),
                ),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Select travelers to cancel, then confirm the refund details.',
              style: TextStyle(fontSize: 12, color: AppColors.outline),
            ),
            const SizedBox(height: 20),

            // Member checkboxes
            const Text('SELECT TRAVELERS TO CANCEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontFamily: 'JetBrains Mono')),
            const SizedBox(height: 8),
            ...List.generate(widget.members.length, (i) {
              final m = widget.members[i];
              final checked = _selected.contains(i);
              return CheckboxListTile(
                value: checked,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.error,
                title: Text(m['name'] ?? 'Traveler ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('Age: ${m['age']} • ${m['gender']}', style: const TextStyle(fontSize: 11, color: AppColors.outline)),
                onChanged: (_) {
                  setState(() {
                    if (checked) {
                      _selected.remove(i);
                    } else {
                      _selected.add(i);
                    }
                    _recalcRefund();
                  });
                },
              );
            }),
            TextButton(
              onPressed: () {
                setState(() {
                  if (allSelected) {
                    _selected.clear();
                  } else {
                    _selected.addAll(List.generate(widget.members.length, (i) => i));
                  }
                  _recalcRefund();
                });
              },
              child: Text(allSelected ? 'Deselect All' : 'Select All', style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ),
            const SizedBox(height: 16),

            // Reason
            DropdownButtonFormField<String>(
              value: _reason,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface, fontFamily: 'Manrope'),
              decoration: const InputDecoration(labelText: 'Cancellation Reason', border: OutlineInputBorder()),
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) { if (v != null) setState(() => _reason = v); },
            ),
            const SizedBox(height: 16),

            // Refund amount
            TextFormField(
              controller: _refundController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, fontFamily: 'JetBrains Mono'),
              decoration: const InputDecoration(
                labelText: 'Refund Amount (₹)',
                border: OutlineInputBorder(),
                helperText: 'Auto-calculated based on selected travelers. You can override.',
              ),
            ),
            const SizedBox(height: 16),

            // Refund payment method
            DropdownButtonFormField<String>(
              value: _method,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface, fontFamily: 'Manrope'),
              decoration: const InputDecoration(labelText: 'Refund via', border: OutlineInputBorder()),
              items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) { if (v != null) setState(() => _method = v); },
            ),
            const SizedBox(height: 16),

            // Screenshot (optional)
            InkWell(
              onTap: () => setState(() {
                _screenshot = 'refund_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.png';
              }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.surfaceContainerLow,
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.camera, color: AppColors.outline, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _screenshot ?? 'Attach Refund Screenshot (optional)',
                        style: TextStyle(fontSize: 13, color: _screenshot == null ? AppColors.outline : AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (_screenshot != null)
                      const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confirm button
            ElevatedButton.icon(
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      final double refund = double.tryParse(_refundController.text) ?? 0;
                      widget.onConfirm(_selected.toList(), refund, _method, _reason, _screenshot);
                    },
              icon: const Icon(LucideIcons.xCircle, size: 18, color: Colors.white),
              label: Text(
                _selected.isEmpty ? 'Select at least one traveler' : 'Confirm Cancellation & Refund',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.outlineVariant,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
