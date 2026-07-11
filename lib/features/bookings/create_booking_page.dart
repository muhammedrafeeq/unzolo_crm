import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/state/unzolo_state.dart';
import '../../core/responsive_utils.dart';

class CreateBookingPage extends ConsumerStatefulWidget {
  const CreateBookingPage({super.key});

  @override
  ConsumerState<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends ConsumerState<CreateBookingPage> {
  int _attendeeCount = 1;
  String _selectedExperience = 'Novice';
  final TextEditingController _dietaryController = TextEditingController();

  // Dynamically generated form fields state
  final List<TextEditingController> _nameControllers = [TextEditingController()];
  final List<TextEditingController> _ageControllers = [TextEditingController()];
  final List<String> _genders = ['Male'];
  final List<TextEditingController> _extraControllers = [TextEditingController(), TextEditingController()]; // Email + Phone for primary

  bool _initializedArgs = false;
  Map<String, dynamic>? _selectedTrip;

  // Concessions & Opt-outs
  bool _optOutTransport = false;
  bool _optOutStay = false;

  @override
  void initState() {
    super.initState();
    _updateAttendeeCount(1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        if (args['trip'] != null) {
          _selectedTrip = args['trip'] as Map<String, dynamic>;
        }
        if (args['name'] != null && _nameControllers.isNotEmpty) {
          _nameControllers[0].text = args['name'] as String;
        }
        if (args['email'] != null && _extraControllers.isNotEmpty) {
          _extraControllers[0].text = args['email'] as String;
        }
        if (args['phone'] != null && _extraControllers.length > 1) {
          _extraControllers[1].text = args['phone'] as String;
        }
      }
      _initializedArgs = true;
    }
  }

  @override
  void dispose() {
    _dietaryController.dispose();
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    for (var controller in _ageControllers) {
      controller.dispose();
    }
    for (var controller in _extraControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateAttendeeCount(int count) {
    if (count < 1) return;
    setState(() {
      _attendeeCount = count;

      // Sync name controllers
      while (_nameControllers.length < _attendeeCount) {
        _nameControllers.add(TextEditingController());
      }
      while (_nameControllers.length > _attendeeCount) {
        _nameControllers.last.dispose();
        _nameControllers.removeLast();
      }

      // Sync age controllers
      while (_ageControllers.length < _attendeeCount) {
        _ageControllers.add(TextEditingController());
      }
      while (_ageControllers.length > _attendeeCount) {
        _ageControllers.last.dispose();
        _ageControllers.removeLast();
      }

      // Sync gender values
      while (_genders.length < _attendeeCount) {
        _genders.add('Male');
      }
      while (_genders.length > _attendeeCount) {
        _genders.removeLast();
      }

      // Sync extra controllers (email/phone/passport)
      int requiredExtraSize = _attendeeCount == 1 ? 2 : (_attendeeCount * 2 - 1);
      while (_extraControllers.length < requiredExtraSize) {
        _extraControllers.add(TextEditingController());
      }
      while (_extraControllers.length > requiredExtraSize) {
        _extraControllers.last.dispose();
        _extraControllers.removeLast();
      }
    });
  }

  // Pricing calculations helper
  double get _basePricePerPerson {
    if (_selectedTrip != null) {
      return (_selectedTrip!['price'] as num).toDouble();
    }
    return 1000.0; // fallback
  }

  double get _advancePerPerson {
    if (_selectedTrip != null) {
      return (_selectedTrip!['advanceAmount'] as num).toDouble();
    }
    return 200.0; // fallback
  }

  double get _concessionsPerPerson {
    double total = 0.0;
    if (_optOutTransport) total += 50.0;
    if (_optOutStay) total += 150.0;
    return total;
  }

  double get _calculatedTotal {
    double base = _basePricePerPerson - _concessionsPerPerson;
    double rawTotal = base * _attendeeCount;

    // Group size discount (10% off for 4+ attendees)
    if (_attendeeCount >= 4) {
      rawTotal = rawTotal * 0.9;
    }
    return rawTotal;
  }

  double get _calculatedMinAdvance {
    return _advancePerPerson * _attendeeCount;
  }

  void _showPaymentDrawer() {
    // Basic form validation first
    for (int i = 0; i < _attendeeCount; i++) {
      if (_nameControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in the name for Attendee ${i + 1}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final double totalAmount = _calculatedTotal;
    final double minAdvance = _calculatedMinAdvance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _PaymentDrawer(
          totalAmount: totalAmount,
          minAdvance: minAdvance,
          onConfirm: (double amountPaid, String method, String type, String? screenshot) {
            _completeBooking(amountPaid, method, type, screenshot);
          },
        );
      },
    );
  }

  Future<void> _completeBooking(double amountPaid, String method, String type, String? screenshot) async {
    final tripsList = ref.read(tripsProvider).value ?? [];
    final trip = _selectedTrip ?? (tripsList.isNotEmpty ? tripsList.first : null);
    if (trip == null) return;
    final String bookingId = '#SP-${DateTime.now().millisecondsSinceEpoch}-UN';

    // Build members list
    final List<Map<String, String>> members = [];
    for (int i = 0; i < _attendeeCount; i++) {
      String contact = '';
      if (i == 0) {
        contact = _extraControllers[1].text.trim();
      } else {
        contact = _extraControllers[i + 1].text.trim(); // Passport / contact
      }

      members.add({
        'name': _nameControllers[i].text.trim(),
        'age': _ageControllers[i].text.trim(),
        'gender': _genders[i],
        'place': i == 0 ? 'Primary' : 'Secondary Member',
        'phone': contact,
      });
    }

    final Map<String, dynamic> newBooking = {
      'id': bookingId,
      'tripId': trip['id'],
      'title': trip['title'],
      'dates': trip['dates'] ?? 'Custom Dates',
      'status': amountPaid >= totalAmount ? 'Confirmed' : 'Pending',
      'imageUrl': trip['imageUrl'] ?? 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
      'amount': '₹${totalAmount.toInt()}',
      'collected': amountPaid,
      'totalCollected': amountPaid,
      'membersCount': _attendeeCount,
      'members': members,
      'transactions': [
        {
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'amount': amountPaid,
          'method': method,
          'type': type,
          'screenshot': screenshot,
        }
      ],
      'dietaryRequirements': _dietaryController.text.trim(),
      'experienceLevel': _selectedExperience,
      'optOutTransport': _optOutTransport,
      'optOutStay': _optOutStay,
    };

    // Save in provider
    await ref.read(bookingsProvider.notifier).addBooking(newBooking);

    // Save lead custom traveler to customer provider database if new
    ref.read(customersProvider.notifier).addCustomer({
      'name': _nameControllers[0].text.trim(),
      'age': int.tryParse(_ageControllers[0].text) ?? 25,
      'gender': _genders[0],
      'place': 'Database Auto-filled',
      'contact': _extraControllers[1].text.trim(),
      'travelCount': 1,
      'cancellationsCount': 0,
      'lastDestination': trip['title'],
      'lastDate': DateFormat('MMM yyyy').format(DateTime.now()),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking $bookingId created successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );

    // Navigate back to Dashboard or select trip
    Navigator.pop(context); // close drawer
    Navigator.pop(context, true); // close wizard page
  }

  double get totalAmount => _calculatedTotal;

  @override
  Widget build(BuildContext context) {
    final tripsList = ref.watch(tripsProvider).value ?? [];
    final trip = _selectedTrip ?? (tripsList.isNotEmpty ? tripsList.first : null);

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Unzolo',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'JD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: trip == null 
            ? const Center(child: Text('No Trips Available.'))
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: context.vPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking ${trip['title']}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Destination: ${trip['location']} • Base Rate: ₹${trip['price']}',
                      style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Total Attendees Counter
                    _buildAttendeesCounterCard(),
                    const SizedBox(height: 24),

                    // Dynamic Attendee Forms List
                    for (int i = 0; i < _attendeeCount; i++) ...[
                      _buildAttendeeFormCard(i),
                      const SizedBox(height: 24),
                    ],

                    // Concessions & Opt-outs Card
                    _buildConcessionsCard(),
                    const SizedBox(height: 24),

                    // Dietary or Medical Requirements Card
                    _buildDietaryRequirementsCard(),
                    const SizedBox(height: 24),

                    // Experience Level Card
                    _buildExperienceLevelCard(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildSummaryFooterBar(),
    );
  }

  Widget _buildAttendeesCounterCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Attendees',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Groups of 4+ get a 10% discount.',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _updateAttendeeCount(_attendeeCount - 1),
                  icon: const Icon(LucideIcons.minus, size: 20, color: AppColors.onSurfaceVariant),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(44, 44),
                  ),
                ),
                Text(
                  '$_attendeeCount',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                  ),
                ),
                IconButton(
                  onPressed: () => _updateAttendeeCount(_attendeeCount + 1),
                  icon: const Icon(LucideIcons.plus, size: 20, color: AppColors.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(44, 44),
                    shadowColor: Colors.black.withValues(alpha: 0.05),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeFormCard(int index) {
    final isLead = index == 0;
    final customers = ref.watch(customersProvider).value ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLead ? 'Attendee 1 (Lead)' : 'Attendee ${index + 1}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                ),
              ),
              if (isLead)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRIMARY CONTACT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: () {
                    _updateAttendeeCount(_attendeeCount - 1);
                  },
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Autocomplete or Full Name Input
          _buildInputLabel('Full Name'),
          if (isLead)
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Map<String, dynamic>>.empty();
                }
                return customers.where((cust) {
                  return cust['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              displayStringForOption: (option) => option['name'] as String,
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                // Keep controllers in sync
                if (textEditingController.text != _nameControllers[0].text) {
                  textEditingController.text = _nameControllers[0].text;
                }
                textEditingController.addListener(() {
                  _nameControllers[0].text = textEditingController.text;
                });
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
                    decoration: const InputDecoration(
                      hintText: 'Search or enter lead traveler',
                      hintStyle: TextStyle(color: AppColors.outline, fontSize: 13),
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                      prefixIcon: Icon(LucideIcons.search, size: 18, color: AppColors.outline),
                    ),
                  ),
                );
              },
              onSelected: (Map<String, dynamic> selection) {
                setState(() {
                  _nameControllers[0].text = selection['name'] as String;
                  _ageControllers[0].text = selection['age']?.toString() ?? '';
                  _genders[0] = selection['gender'] as String? ?? 'Male';
                  _extraControllers[1].text = selection['contact'] as String? ?? '';
                });
              },
            )
          else
            _buildTextField(_nameControllers[index], 'e.g. John Doe'),
          const SizedBox(height: 16),

          // Age & Gender
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Age'),
                    _buildTextField(_ageControllers[index], 'Years', keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Gender'),
                    _buildGenderDropdown(index),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lead fields vs Secondary fields
          if (isLead) ...[
            _buildInputLabel('Email Address'),
            _buildTextField(_extraControllers[0], 'john@example.com', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildInputLabel('Primary Phone Contact'),
            _buildTextField(_extraControllers[1], '+1 (555) 000-0000', keyboardType: TextInputType.phone),
          ] else ...[
            _buildInputLabel('Passport Number / ID'),
            _buildTextField(_extraControllers[index + 1], 'Enter ID number'),
          ],
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.outline,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.outline, fontSize: 13, fontFamily: 'Manrope'),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _genders[index],
          isExpanded: true,
          style: const TextStyle(color: AppColors.onSurface, fontSize: 14, fontFamily: 'Manrope'),
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _genders[index] = val;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildConcessionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.scissors, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pricing Concessions & Opt-outs'.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Adjust base booking rates by opting out of global logistical components.',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Transport Opt-Out
          SwitchListTile(
            title: const Text('Omit Transport Service', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: const Text('Deducts ₹50 per traveler', style: TextStyle(fontSize: 12)),
            value: _optOutTransport,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _optOutTransport = val;
              });
            },
          ),
          const Divider(),
          // Stay Opt-Out
          SwitchListTile(
            title: const Text('Omit Base Lodging/Stay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: const Text('Deducts ₹150 per traveler', style: TextStyle(fontSize: 12)),
            value: _optOutStay,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _optOutStay = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryRequirementsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.briefcase, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Dietary or Medical Requirements'.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: TextField(
              controller: _dietaryController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
              decoration: const InputDecoration(
                hintText: 'Please list any allergies, chronic conditions, or specific dietary needs (Vegan, Gluten-Free, etc.)',
                hintStyle: TextStyle(color: AppColors.outline, fontSize: 13, fontFamily: 'Manrope'),
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceLevelCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.dumbbell, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Experience Level'.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'How would you rate your team\'s hiking experience?',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildExperienceOption('Novice'),
          const SizedBox(height: 12),
          _buildExperienceOption('Intermediate'),
          const SizedBox(height: 12),
          _buildExperienceOption('Pro Mountaineer'),
        ],
      ),
    );
  }

  Widget _buildExperienceOption(String level) {
    final isSelected = _selectedExperience == level;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedExperience = level;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                  width: 2.0,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              level,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryFooterBar() {
    final double total = _calculatedTotal;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: const Border(top: BorderSide(color: AppColors.surfaceContainer)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL CALCULATED', style: TextStyle(color: AppColors.outline, fontSize: 10, fontFamily: 'JetBrains Mono')),
                    const SizedBox(height: 4),
                    Text(
                      '₹${total.toInt()}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'JetBrains Mono'),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _showPaymentDrawer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Record Payment',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(LucideIcons.chevronRight, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentDrawer extends StatefulWidget {
  final double totalAmount;
  final double minAdvance;
  final Function(double amountPaid, String method, String type, String? screenshot) onConfirm;

  const _PaymentDrawer({
    required this.totalAmount,
    required this.minAdvance,
    required this.onConfirm,
  });

  @override
  State<_PaymentDrawer> createState() => _PaymentDrawerState();
}

class _PaymentDrawerState extends State<_PaymentDrawer> {
  final _amountController = TextEditingController();
  String _paymentMethod = 'UPI';
  String _paymentType = 'Advance'; // 'Advance' or 'Full Payment'
  String? _screenshotName;

  @override
  void initState() {
    super.initState();
    // Default pre-fill depending on type selected
    _updateAmountField();
  }

  void _updateAmountField() {
    if (_paymentType == 'Advance') {
      _amountController.text = widget.minAdvance.toInt().toString();
    } else {
      _amountController.text = widget.totalAmount.toInt().toString();
    }
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
                'Record Payment Drawer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Manrope'),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Type Toggle
          const Text('Payment Stage Type', style: TextStyle(color: AppColors.outline, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Advance Deposit'),
                  selected: _paymentType == 'Advance',
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _paymentType = 'Advance';
                        _updateAmountField();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Full Settlement'),
                  selected: _paymentType == 'Full Payment',
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _paymentType = 'Full Payment';
                        _updateAmountField();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Method Dropdown
          const Text('Payment Method Channel', style: TextStyle(color: AppColors.outline, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            style: const TextStyle(fontSize: 14, color: AppColors.onSurface, fontFamily: 'Manrope'),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            items: const [
              DropdownMenuItem(value: 'UPI', child: Text('UPI')),
              DropdownMenuItem(value: 'Card', child: Text('Debit/Credit Card')),
              DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
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

          // Amount input field
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Amount Paid (₹)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Receipt upload trigger
          InkWell(
            onTap: () {
              setState(() {
                _screenshotName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.png';
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
                      _screenshotName ?? 'Upload Receipt Image Screenshot',
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

          // Confirm button
          ElevatedButton(
            onPressed: () {
              final double amt = double.tryParse(_amountController.text) ?? 0.0;
              if (amt <= 0.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid payment amount.')),
                );
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
            child: const Text(
              'Confirm & Finalize Booking',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
