import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
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
      if (mounted) setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _dialPhone(String contact) async {
    final uri = Uri(scheme: 'tel', path: contact);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot dial $contact'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerFormSheet(
        onSave: (data) async {
          await ref.read(customersProvider.notifier).addCustomer(data);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer profile created!')),
          );
        },
      ),
    );
  }

  void _showEditSheet(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerFormSheet(
        existing: customer,
        onSave: (data) async {
          await ref.read(customersProvider.notifier).updateCustomer(data);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer updated!')),
          );
        },
        onDelete: () async {
          await ref.read(customersProvider.notifier).deleteCustomer(customer['id'] as String);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer deleted.')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final customers = customersAsync.value ?? [];

    final filtered = customers.where((c) {
      final name = c['name'].toString().toLowerCase();
      final place = (c['place'] ?? '').toString().toLowerCase();
      final contact = (c['contact'] ?? '').toString().toLowerCase();
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
                    Text('Customers', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.onSurface)),
                    const SizedBox(height: 6),
                    const Text('Track travel frequencies, cancel histories, and profiles.', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
                FloatingActionButton.small(
                  heroTag: null,
                  onPressed: _showAddSheet,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(LucideIcons.userPlus),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.users, size: 56, color: AppColors.outlineVariant),
                      const SizedBox(height: 16),
                      const Text('No customers yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      const Text('Add your first customer using the + button above.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.outline)),
                    ],
                  ),
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
                  final initial = cust['name'].toString().isNotEmpty ? cust['name'].toString()[0].toUpperCase() : '?';

                  return GestureDetector(
                    onTap: () => _showEditSheet(cust),
                    child: Card(
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
                              child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cust['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Age: ${cust['age']} • ${cust['gender']} • ${cust['place'] ?? 'Unknown'}',
                                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _badge(LucideIcons.compass, '$travelCount Trips', AppColors.primary),
                                      if (cancelCount > 0) ...[
                                        const SizedBox(width: 8),
                                        _badge(LucideIcons.shieldAlert, '$cancelCount Cancelled', AppColors.error),
                                      ],
                                    ],
                                  ),
                                  if (cust['lastDestination'] != null) ...[
                                    const Divider(height: 20),
                                    Text(
                                      'Last: ${cust['lastDestination']} (${cust['lastDate'] ?? ''})',
                                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.outline),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(LucideIcons.phoneCall, color: Color(0xFF1E7E34)),
                              onPressed: () => _dialPhone(cust['contact'] ?? ''),
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

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono')),
        ],
      ),
    );
  }
}

class _CustomerFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final Future<void> Function()? onDelete;

  const _CustomerFormSheet({this.existing, required this.onSave, this.onDelete});

  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _placeCtrl;
  late String _gender;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?['name'] ?? '');
    _ageCtrl = TextEditingController(text: e?['age']?.toString() ?? '');
    _contactCtrl = TextEditingController(text: e?['contact'] ?? '');
    _placeCtrl = TextEditingController(text: e?['place'] ?? '');
    _gender = e?['gender'] ?? 'Male';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _contactCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  void _confirmDelete() {
    Navigator.pop(context);
    widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 44,
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
                  width: 48, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Customer' : 'Add Customer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                  ),
                  Row(
                    children: [
                      if (isEdit)
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, color: AppColors.error, size: 20),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Customer?'),
                                content: Text('Remove ${widget.existing!['name']} from your database?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () { Navigator.pop(context); _confirmDelete(); },
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age'),
                      validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) { if (v != null) setState(() => _gender = v); },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _placeCtrl,
                decoration: const InputDecoration(labelText: 'Place'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final data = {
                      if (widget.existing != null) 'id': widget.existing!['id'],
                      if (widget.existing == null) 'id': 'cust-${DateTime.now().millisecondsSinceEpoch}',
                      'name': _nameCtrl.text.trim(),
                      'age': int.parse(_ageCtrl.text),
                      'gender': _gender,
                      'contact': _contactCtrl.text.trim(),
                      'place': _placeCtrl.text.trim().isEmpty ? 'Not Stated' : _placeCtrl.text.trim(),
                      'travelCount': widget.existing?['travelCount'] ?? 0,
                      'cancellationsCount': widget.existing?['cancellationsCount'] ?? 0,
                    };
                    widget.onSave(data);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(isEdit ? 'Save Changes' : 'Add Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
