import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/widgets/premium_filter_chip.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/state/unzolo_state.dart';

class ManageEnquiriesPage extends ConsumerStatefulWidget {
  const ManageEnquiriesPage({super.key});

  @override
  ConsumerState<ManageEnquiriesPage> createState() => _ManageEnquiriesPageState();
}

class _ManageEnquiriesPageState extends ConsumerState<ManageEnquiriesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
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

  final List<String> _statusChips = [
    'All',
    'Hot',
    'Warm',
    'Cold',
    'Converted',
    'Cancelled',
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hot':
        return Colors.redAccent;
      case 'Warm':
        return Colors.orangeAccent;
      case 'Cold':
        return Colors.blueAccent;
      case 'Converted':
        return const Color(0xFF1E7E34);
      case 'Cancelled':
        return AppColors.outline;
      default:
        return AppColors.outline;
    }
  }

  void _convertToBooking(Map<String, dynamic> enquiry) {
    // Attempt to match with existing trips in provider
    final trips = ref.read(tripsProvider).value ?? [];
    Map<String, dynamic>? prefillTrip;
    if (trips.isNotEmpty) {
      prefillTrip = trips.firstWhere(
        (t) => t['title'].toString().toLowerCase().contains(enquiry['trip'].toString().toLowerCase()),
        orElse: () => trips.first,
      );
    }

    Navigator.pushNamed(
      context,
      AppRoutes.createBooking,
      arguments: {
        'name': enquiry['name'],
        'email': enquiry['email'],
        'phone': enquiry['phone'],
        'trip': prefillTrip,
      },
    ).then((result) async {
      if (result == true) {
        await ref.read(enquiriesProvider.notifier).updateEnquiryStatus(enquiry['id'], 'Converted');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lead for ${enquiry['name']} converted to a booking successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    });
  }

  void _showAddLeadBottomSheet() {
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _AddLeadBottomSheet(
            onConfirm: (Map<String, dynamic> newEnq) async {
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(enquiriesProvider.notifier).addEnquiry(newEnq);
              messenger.showSnackBar(
                const SnackBar(content: Text('Lead recorded in Enquiry Board!')),
              );
            },
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final enquiriesAsync = ref.watch(enquiriesProvider);
    final enquiries = enquiriesAsync.value ?? [];

    // Follow-up Calendar Alert logic (today's follow-up reminders)
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final followUpLeads = enquiries.where((e) => e['followUpDate'] == todayStr && e['status'] != 'Converted').toList();

    // Filtered Board Leads
    final filtered = enquiries.where((e) {
      final matchesQuery = e['name'].toString().toLowerCase().contains(_searchQuery) ||
          e['trip'].toString().toLowerCase().contains(_searchQuery);

      final matchesStatus = _selectedStatus == 'All' ||
          e['status'].toString().toLowerCase() == _selectedStatus.toLowerCase();

      return matchesQuery && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Enquiry Board',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Manrope'),
        ),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SkeletonLoader(
          isLoading: enquiriesAsync.isLoading,
          skeleton: const EnquiriesSkeleton(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lead Board',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.onSurface),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Filter leads by temperature tags & initiate bookings.',
                          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                    FloatingActionButton.small(
                      heroTag: null,
                      onPressed: _showAddLeadBottomSheet,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      child: const Icon(LucideIcons.plus),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Follow-up Calendar/Reminders section
                if (followUpLeads.isNotEmpty) ...[
                  _buildFollowUpAlertWidget(followUpLeads),
                  const SizedBox(height: 24),
                ],

                // Search Bar
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
                      hintText: 'Search by customer name or travel interest...',
                      border: InputBorder.none,
                      icon: Icon(LucideIcons.search, color: AppColors.outline),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Temperature Chips Selector
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusChips.length,
                    itemBuilder: (context, index) {
                      final status = _statusChips[index];
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
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Leads Cards List
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: Center(
                      child: Text('No leads found in this channel.', style: TextStyle(color: AppColors.outline)),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final enq = filtered[index];
                      return _buildEnquiryCard(enq);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowUpAlertWidget(List<Map<String, dynamic>> leads) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.25),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.calendarDays, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Text(
                "Today's Follow-up reminders".toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 11, fontFamily: 'JetBrains Mono'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leads.length,
            itemBuilder: (context, index) {
              final lead = leads[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('• ${lead['name']} (${lead['trip']})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(lead['status']).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        lead['status'],
                        style: TextStyle(color: _getStatusColor(lead['status']), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnquiryCard(Map<String, dynamic> enq) {
    final status = enq['status'] as String;
    final isConverted = status == 'Converted';
    final isCancelled = status == 'Cancelled';

    return Card(
      color: AppColors.surfaceContainerLowest,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: enq['avatarColor'] ?? AppColors.primaryContainer,
                      radius: 12,
                      child: Text(
                        enq['name'].toString().substring(0, 1),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      enq['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Space Grotesk'),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Trip Interest: ${enq['trip']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              enq['message'],
              style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact: ${enq['phone']}', style: const TextStyle(fontSize: 11, color: AppColors.outline)),
                    if (enq['followUpDate'] != null) ...[
                      const SizedBox(height: 2),
                      Text('Follow-up: ${enq['followUpDate']}', style: const TextStyle(fontSize: 11, color: AppColors.outline, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
                if (!isConverted && !isCancelled)
                  ElevatedButton.icon(
                    onPressed: () => _convertToBooking(enq),
                    icon: const Icon(LucideIcons.arrowRight, size: 14, color: Colors.white),
                    label: const Text('Convert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(90, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddLeadBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic> newEnq) onConfirm;

  const _AddLeadBottomSheet({required this.onConfirm});

  @override
  State<_AddLeadBottomSheet> createState() => _AddLeadBottomSheetState();
}

class _AddLeadBottomSheetState extends State<_AddLeadBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _tripController = TextEditingController();
  final _msgController = TextEditingController();
  DateTime? _followUp;
  String _priority = 'Medium';
  String _status = 'Warm';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _tripController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _selectFollowUp(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _followUp = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Capture Lead Enquiry',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Space Grotesk',
                        ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Lead Full Name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Contact Phone Number'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tripController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Trip Expedition Interest'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _msgController,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(labelText: 'Notes / Query details'),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _status,
                style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
                decoration: const InputDecoration(labelText: 'Lead Temperature Priority'),
                items: const [
                  DropdownMenuItem(value: 'Hot', child: Text('Hot Temperature')),
                  DropdownMenuItem(value: 'Warm', child: Text('Warm Temperature')),
                  DropdownMenuItem(value: 'Cold', child: Text('Cold Temperature')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _status = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () => _selectFollowUp(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(LucideIcons.calendarDays, size: 18, color: AppColors.primary),
                      Text(
                        _followUp == null ? 'Set Follow-up Date Reminder' : DateFormat('yyyy-MM-dd').format(_followUp!),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newEnq = {
                          'id': 'enq-${DateTime.now().millisecondsSinceEpoch}',
                          'name': _nameController.text.trim(),
                          'email': _emailController.text.trim().isEmpty ? 'no-email@example.com' : _emailController.text.trim(),
                          'phone': _phoneController.text.trim(),
                          'trip': _tripController.text.trim(),
                          'message': _msgController.text.trim().isEmpty ? 'General inquiry about trek itineraries.' : _msgController.text.trim(),
                          'status': _status,
                          'date': DateFormat('MMM dd, yyyy').format(DateTime.now()),
                          'avatarColor': Colors.deepPurpleAccent,
                          'followUpDate': _followUp == null ? null : DateFormat('yyyy-MM-dd').format(_followUp!),
                          'priority': _priority,
                        };
                        widget.onConfirm(newEnq);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 48),
                    ),
                    child: const Text('Record Lead'),
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

class EnquiriesSkeleton extends StatelessWidget {
  const EnquiriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Divider());
  }
}
