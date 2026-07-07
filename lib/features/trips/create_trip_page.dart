import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/state/unzolo_state.dart';
import '../../core/responsive_utils.dart';

class CreateTripPage extends ConsumerStatefulWidget {
  const CreateTripPage({super.key});

  @override
  ConsumerState<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends ConsumerState<CreateTripPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Shared Controllers
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _advanceController = TextEditingController();
  final _descController = TextEditingController();

  // Camp Specific
  DateTime? _startDate;
  DateTime? _endDate;

  // Package Specific
  final _groupSizeController = TextEditingController();
  String _selectedCategory = 'Honeymoon';
  final List<String> _categories = ['Honeymoon', 'Budget Friendly', 'Luxury', 'Adventure', 'Family'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _advanceController.dispose();
    _descController.dispose();
    _groupSizeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Auto adjust end date if it is before start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitTrip() async {
    if (_formKey.currentState!.validate()) {
      final isCamp = _tabController.index == 0;

      if (isCamp) {
        if (_startDate == null || _endDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please specify both Start Date and End Date for Camps.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        if (_endDate!.isBefore(_startDate!) || _endDate!.isAtSameMomentAs(_startDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End Date must be after Start Date.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }

      final double price = double.tryParse(_priceController.text) ?? 0.0;
      final double advance = double.tryParse(_advanceController.text) ?? 0.0;

      if (advance > price) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Advance amount cannot exceed the base price.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Generate trip payload
      final String id = 'trip-${DateTime.now().millisecondsSinceEpoch}';
      final String categoryStr = isCamp ? 'Camps' : 'Packages';
      final String formattedDates = isCamp 
          ? '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
          : 'Customizable Dates';

      final Map<String, dynamic> newTrip = {
        'id': id,
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'price': price.toInt(),
        'description': _descController.text.trim().isEmpty 
            ? 'Explore premium mountain vistas and personalized guiding services.' 
            : _descController.text.trim(),
        'duration': isCamp ? 'Fixed Date' : 'Customizable',
        'status': 'Available',
        'statusBg': const Color(0xFFE2F3E2),
        'statusText': const Color(0xFF1E7E34),
        'imageUrl': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=600&auto=format&fit=crop',
        'category': categoryStr,
        'advanceAmount': advance.toInt(),
      };

      if (isCamp) {
        newTrip['startDate'] = DateFormat('yyyy-MM-dd').format(_startDate!);
        newTrip['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
        newTrip['dates'] = formattedDates;
      } else {
        newTrip['groupSize'] = int.tryParse(_groupSizeController.text) ?? 2;
        newTrip['packageCategory'] = _selectedCategory;
      }

      // Save to Riverpod state
      await ref.read(tripsProvider.notifier).addTrip(newTrip);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$categoryStr Created successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Create New Trip',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Manrope'),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Tab Selector
              Container(
                color: AppColors.surfaceContainerLowest,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.outline,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Manrope'),
                  tabs: const [
                    Tab(icon: Icon(LucideIcons.calendarDays), text: 'Camps (Fixed Dates)'),
                    Tab(icon: Icon(LucideIcons.snowflake), text: 'Packages (Flexible)'),
                  ],
                ),
              ),

              // Form fields scroll view
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: context.vPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Trip Title
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
                        decoration: InputDecoration(
                          labelText: 'Trip Expedition Title',
                          hintText: 'e.g. Everest Luxury Trek',
                          prefixIcon: const Icon(LucideIcons.mountain, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter trip title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Location
                      TextFormField(
                        controller: _locationController,
                        style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
                        decoration: InputDecoration(
                          labelText: 'Destination / Location',
                          hintText: 'e.g. Nepal, Himalayas',
                          prefixIcon: const Icon(LucideIcons.mapPin, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Price Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
                              decoration: InputDecoration(
                                labelText: 'Price per Traveler (₹)',
                                prefixIcon: const Icon(LucideIcons.dollarSign, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || double.tryParse(value) == null) {
                                  return 'Enter valid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _advanceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
                              decoration: InputDecoration(
                                labelText: 'Min Advance Deposit (₹)',
                                prefixIcon: const Icon(LucideIcons.shieldCheck, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || double.tryParse(value) == null) {
                                  return 'Enter valid deposit';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tab Specific widgets
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          final isCamp = _tabController.index == 0;
                          return isCamp 
                              ? _buildCampFields(context) 
                              : _buildPackageFields();
                        },
                      ),
                      const SizedBox(height: 24),

                      // Description
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
                        decoration: InputDecoration(
                          labelText: 'Trip Summary / Description',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _submitTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Create Trip Expedition',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampFields(BuildContext context) {
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
          const Text(
            'Camp Schedule Parameters',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Manrope'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Date', style: TextStyle(color: AppColors.outline, fontSize: 11)),
                        const SizedBox(height: 6),
                        Text(
                          _startDate == null 
                              ? 'Select Date' 
                              : DateFormat('yyyy-MM-dd').format(_startDate!),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Date', style: TextStyle(color: AppColors.outline, fontSize: 11)),
                        const SizedBox(height: 6),
                        Text(
                          _endDate == null 
                              ? 'Select Date' 
                              : DateFormat('yyyy-MM-dd').format(_endDate!),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageFields() {
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
          const Text(
            'Customizable Package Customization',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Manrope'),
          ),
          const SizedBox(height: 16),
          // Category Selection
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            style: const TextStyle(fontSize: 14, color: AppColors.onSurface, fontFamily: 'Manrope'),
            decoration: InputDecoration(
              labelText: 'Package Type Category',
              prefixIcon: const Icon(LucideIcons.tag, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _categories.map((String cat) {
              return DropdownMenuItem<String>(
                value: cat,
                child: Text(cat),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedCategory = val;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Group Size
          TextFormField(
            controller: _groupSizeController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
            decoration: InputDecoration(
              labelText: 'Min Group Size to secure rate',
              hintText: 'e.g. 2',
              prefixIcon: const Icon(LucideIcons.users, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || int.tryParse(value) == null) {
                return 'Please enter target group size';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
