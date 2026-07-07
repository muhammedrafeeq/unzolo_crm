import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/state/unzolo_state.dart';
import '../../core/widgets/skeleton_loader.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final _searchController = TextEditingController();
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

  void _triggerPhoneDialer(String contact) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening telephone dialer for $contact...'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(label: 'Call', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }

  void _showAddCustomerDialog() {
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return _AddCustomerDialog(
            onConfirm: (Map<String, dynamic> newCust) async {
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(customersProvider.notifier).addCustomer(newCust);
              messenger.showSnackBar(
                const SnackBar(content: Text('Customer profile created successfully!')),
              );
            },
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final customers = customersAsync.value ?? [];

    final filtered = customers.where((cust) {
      final name = cust['name'].toString().toLowerCase();
      final place = (cust['place'] ?? '').toString().toLowerCase();
      final contact = (cust['contact'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || place.contains(_searchQuery) || contact.contains(_searchQuery);
    }).toList();

    return SkeletonLoader(
      isLoading: customersAsync.isLoading,
      skeleton: const CustomersSkeleton(),
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
                        'Unified Database',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Track travel frequencies, cancel histories, and profiles.',
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                  FloatingActionButton.small(
                    heroTag: null,
                    onPressed: _showAddCustomerDialog,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    child: const Icon(LucideIcons.userPlus),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Input Box
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
                    hintText: 'Search by traveler name, location, or contact info',
                    border: InputBorder.none,
                    icon: Icon(LucideIcons.search, color: AppColors.outline),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.0),
                  child: Center(
                    child: Text('No traveler matches found.', style: TextStyle(color: AppColors.outline)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final cust = filtered[index];
                    final int travelCount = cust['travelCount'] as int? ?? 0;
                    final int cancelCount = cust['cancellationsCount'] as int? ?? 0;

                    return Card(
                      color: AppColors.surfaceContainerLowest,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryContainer,
                              radius: 22,
                              child: Text(
                                cust['name'].toString().substring(0, 1),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cust['name'],
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Age: ${cust['age']} • Gender: ${cust['gender']} • Place: ${cust['place'] ?? 'Default'}',
                                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(LucideIcons.compass, size: 10, color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$travelCount Trips Completed',
                                              style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (cancelCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(LucideIcons.shieldAlert, size: 10, color: AppColors.error),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$cancelCount Cancellation Flagged',
                                                style: const TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (cust['lastDestination'] != null) ...[
                                    const Divider(height: 20),
                                    Text(
                                      'Last Destination: ${cust['lastDestination']} (${cust['lastDate'] ?? ''})',
                                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.outline),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(LucideIcons.phoneCall, color: Color(0xFF1E7E34)),
                              onPressed: () => _triggerPhoneDialer(cust['contact'] ?? '+1 (555) 000-0000'),
                            ),
                          ],
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

class _AddCustomerDialog extends StatefulWidget {
  final Function(Map<String, dynamic> newCust) onConfirm;

  const _AddCustomerDialog({required this.onConfirm});

  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _placeController = TextEditingController();
  String _gender = 'Male';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Customer Record', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
                      decoration: const InputDecoration(labelText: 'Age'),
                      validator: (val) => val == null || int.tryParse(val) == null ? 'Invalid age' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      style: const TextStyle(fontSize: 14, color: AppColors.onSurface, fontFamily: 'Manrope'),
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _gender = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
                decoration: const InputDecoration(labelText: 'Phone Contact Number'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _placeController,
                style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
                decoration: const InputDecoration(labelText: 'Traveler Place of Origin (e.g. Rome)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newCust = {
                'name': _nameController.text.trim(),
                'age': int.parse(_ageController.text),
                'gender': _gender,
                'contact': _contactController.text.trim(),
                'place': _placeController.text.trim().isEmpty ? 'Not Stated' : _placeController.text.trim(),
                'travelCount': 0,
                'cancellationsCount': 0,
              };
              widget.onConfirm(newCust);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 44),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
