import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/responsive_utils.dart';

class EditTripPage extends StatefulWidget {
  const EditTripPage({super.key});

  @override
  State<EditTripPage> createState() => _EditTripPageState();
}

class _EditTripPageState extends State<EditTripPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _descriptionController;
  
  String _selectedDifficulty = 'MODERATE';
  String _selectedStatus = 'Available';
  
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _locationController = TextEditingController();
    _priceController = TextEditingController();
    _durationController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _titleController.text = args['title'] as String? ?? '';
        _locationController.text = args['location'] as String? ?? '';
        final priceVal = args['price'];
        _priceController.text = priceVal != null ? priceVal.toString().replaceAll(',', '') : '';
        _durationController.text = args['duration'] as String? ?? '';
        _descriptionController.text = args['description'] as String? ?? '';
        
        final diff = (args['duration'] as String? ?? '').toUpperCase();
        if (diff.contains('EASY')) {
          _selectedDifficulty = 'EASY';
        } else if (diff.contains('HARD')) {
          _selectedDifficulty = 'HARD';
        } else {
          _selectedDifficulty = 'MODERATE';
        }
        
        _selectedStatus = args['status'] as String? ?? 'Available';
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTrip() {
    if (_formKey.currentState!.validate()) {
      // Format price with comma if it's numeric
      String priceText = _priceController.text.trim();
      final numVal = double.tryParse(priceText);
      if (numVal != null) {
        // Simple comma formatter (e.g. 1000 -> 1,000)
        final parts = priceText.split('.');
        final digits = parts[0];
        final formatted = RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))')
            .allMatches(digits)
            .fold(digits, (prev, match) => prev.replaceRange(match.start, match.end, '${match.group(0)},'));
        priceText = parts.length > 1 ? '$formatted.${parts[1]}' : formatted;
      }

      // Calculate status colors
      Color statusBg;
      Color statusText;
      switch (_selectedStatus) {
        case 'Available':
          statusBg = const Color(0xFFD4EDDA);
          statusText = const Color(0xFF155724);
          break;
        case 'High Demand':
          statusBg = const Color(0xFFFFF3CD);
          statusText = const Color(0xFF856404);
          break;
        case 'Waitlist':
          statusBg = const Color(0xFFF8D7DA);
          statusText = const Color(0xFF721C24);
          break;
        default:
          statusBg = const Color(0xFFE2E3E5);
          statusText = const Color(0xFF383D41);
      }

      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final updatedTrip = {
        'id': args?['id'],
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'price': double.tryParse(priceText.replaceAll(',', '')) ?? 0.0,
        'duration': _durationController.text.trim(),
        'difficulty': _selectedDifficulty,
        'description': _descriptionController.text.trim(),
        'status': _selectedStatus,
        'statusBg': statusBg,
        'statusText': statusText,
      };

      Navigator.pop(context, updatedTrip);
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        color: AppColors.outline,
        fontFamily: 'Manrope',
        fontSize: 14,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.outline, size: 20),
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        color: AppColors.onSurface,
        fontSize: 16,
        fontFamily: 'JetBrains Mono',
      ),
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Trip Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: context.vPad),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Expedition Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Change parameters of this trek/tour for all active CRM users.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 28),

                // Trip Title
                TextFormField(
                  controller: _titleController,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
                  decoration: _buildInputDecoration(
                    labelText: 'Trip Title',
                    prefixIcon: LucideIcons.mountain,
                  ),
                  style: const TextStyle(fontFamily: 'Manrope', fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Location
                TextFormField(
                  controller: _locationController,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a location' : null,
                  decoration: _buildInputDecoration(
                    labelText: 'Location',
                    prefixIcon: LucideIcons.mapPin,
                  ),
                  style: const TextStyle(fontFamily: 'Manrope', fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Row for Price & Duration
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a price' : null,
                        decoration: _buildInputDecoration(
                          labelText: 'Price',
                          prefixIcon: LucideIcons.dollarSign,
                        ),
                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter duration' : null,
                        decoration: _buildInputDecoration(
                          labelText: 'Duration',
                          prefixIcon: LucideIcons.clock,
                        ),
                        style: const TextStyle(fontFamily: 'Manrope', fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Difficulty Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedDifficulty,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDifficulty = val;
                      });
                    }
                  },
                  decoration: _buildInputDecoration(
                    labelText: 'Difficulty Level',
                    prefixIcon: LucideIcons.activity,
                  ),
                  items: ['EASY', 'MODERATE', 'HARD'].map((diff) {
                    return DropdownMenuItem<String>(
                      value: diff,
                      child: Text(diff, style: const TextStyle(fontFamily: 'Manrope', fontSize: 16)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Status Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    }
                  },
                  decoration: _buildInputDecoration(
                    labelText: 'Trip Status',
                    prefixIcon: LucideIcons.tag,
                  ),
                  items: ['Available', 'High Demand', 'Waitlist'].map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status, style: const TextStyle(fontFamily: 'Manrope', fontSize: 16)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: null,
                  minLines: 4,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a description' : null,
                  decoration: _buildInputDecoration(
                    labelText: 'Description',
                    prefixIcon: LucideIcons.fileText,
                  ),
                  style: const TextStyle(fontFamily: 'Manrope', fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 36),

                // Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.outline,
                          side: const BorderSide(color: AppColors.outlineVariant),
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Manrope'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Manrope'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
