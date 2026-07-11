import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/state/unzolo_state.dart';
import '../../core/responsive_utils.dart';

class TripExpenseLedgerPage extends ConsumerStatefulWidget {
  const TripExpenseLedgerPage({super.key});

  @override
  ConsumerState<TripExpenseLedgerPage> createState() => _TripExpenseLedgerPageState();
}

class _TripExpenseLedgerPageState extends ConsumerState<TripExpenseLedgerPage> {
  Map<String, dynamic>? _tripArg;
  bool _initialized = false;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Accommodation',
    'Transport',
    'Food',
    'Guide Fees',
    'Permits',
    'Other',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _tripArg = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _initialized = true;
    }
  }

  void _showAddExpenseBottomSheet(String tripId) {
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _AddExpenseBottomSheet(
            tripId: tripId,
            categories: _categories.where((c) => c != 'All').toList(),
            onConfirm: (Map<String, dynamic> newExpense) async {
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(expensesProvider.notifier).addExpense(newExpense);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Expense added successfully to ledger!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          );
        },
      );
    });
  }

  double _getCollectedAmount(Map<String, dynamic> booking) {
    if (booking['transactions'] == null) return 0.0;
    double sum = 0.0;
    for (var tx in booking['transactions']) {
      sum += (tx['amount'] as num).toDouble();
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final trip = _tripArg;
    if (trip == null) {
      return const Scaffold(body: Center(child: Text('Invalid Trip parameters')));
    }

    final String tripId = trip['id'];
    final bookings = ref.watch(bookingsProvider).value ?? [];
    final expenses = ref.watch(expensesProvider).value ?? [];

    // Calculate Total Revenues
    final tripBookings = bookings.where((b) => b['tripId'] == tripId).toList();
    double totalRevenues = 0.0;
    for (var b in tripBookings) {
      totalRevenues += _getCollectedAmount(b);
    }

    // Filtered Expenses
    final tripExpenses = expenses.where((e) => e['tripId'] == tripId).toList();
    final double totalExpenses = tripExpenses.fold<double>(0.0, (sum, e) => sum + (e['amount'] as num).toDouble());

    final filteredExpenses = tripExpenses.where((e) {
      return _selectedCategory == 'All' || e['category'] == _selectedCategory;
    }).toList();

    // Profitability metrics
    final double grossProfit = totalRevenues - totalExpenses;
    final double profitMargin = totalRevenues > 0 ? (grossProfit / totalRevenues) * 100 : 0.0;
    final bool isProfitable = grossProfit >= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          trip['title'],
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Manrope', fontSize: 16),
        ),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: context.vPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Financial Profitability Widget
              _buildProfitabilityWidget(totalRevenues, totalExpenses, grossProfit, profitMargin, isProfitable),
              const SizedBox(height: 24),

              // Category Filter Row
              const Text(
                'EXPENSE LEDGER DETAILS',
                style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isActive = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isActive,
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: TextStyle(
                          color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Expense List
              if (filteredExpenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text('No expenses recorded for this category.', style: TextStyle(color: AppColors.outline, fontSize: 13)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final exp = filteredExpenses[index];
                    return _buildExpenseCard(exp);
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showAddExpenseBottomSheet(tripId),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildProfitabilityWidget(double revenues, double expenses, double profit, double margin, bool isProfitable) {
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
                'Financial Profitability Ledger',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Manrope'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isProfitable ? const Color(0xFFE2F3E2) : const Color(0xFFF8D7DA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${margin.toInt()}% Margin',
                  style: TextStyle(
                    color: isProfitable ? const Color(0xFF1E7E34) : const Color(0xFF721C24),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Revenue', style: TextStyle(color: AppColors.outline, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('₹${revenues.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'JetBrains Mono')),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Total Expenses', style: TextStyle(color: AppColors.outline, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('₹${expenses.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'JetBrains Mono', color: AppColors.error)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Gross Profit', style: TextStyle(color: AppColors.outline, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    '₹${profit.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 18, 
                      fontFamily: 'JetBrains Mono', 
                      color: isProfitable ? const Color(0xFF1E7E34) : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  exp['category'].toString().toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'JetBrains Mono'),
                ),
              ),
              Text(
                '₹${(exp['amount'] as num).toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'JetBrains Mono', color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            exp['description'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.user, size: 12, color: AppColors.outline),
              const SizedBox(width: 4),
              Text(
                'Paid by: ${exp['payer']} • ${exp['date']}',
                style: const TextStyle(color: AppColors.outline, fontSize: 11),
              ),
            ],
          ),
          if (exp['notes'] != null && exp['notes'].toString().isNotEmpty) ...[
            const Divider(height: 20),
            Text(
              'Notes: ${exp['notes']}',
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}class _AddExpenseBottomSheet extends StatefulWidget {
  final String tripId;
  final List<String> categories;
  final Function(Map<String, dynamic> newExpense) onConfirm;

  const _AddExpenseBottomSheet({
    required this.tripId,
    required this.categories,
    required this.onConfirm,
  });

  @override
  State<_AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<_AddExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  late String _selectedCategory;
  String _payer = 'Alex';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categories.isNotEmpty ? widget.categories.first : 'All';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 50,
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
                    'Record Expense Ledger',
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
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: const TextStyle(fontSize: 14, color: AppColors.onSurface, fontFamily: 'Manrope'),
                decoration: const InputDecoration(labelText: 'Expense Category'),
                items: widget.categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount Paid (₹)', prefixIcon: Icon(LucideIcons.dollarSign, size: 20)),
                validator: (val) {
                  if (val == null || double.tryParse(val) == null) return 'Enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description / Payee'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter description';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _payer,
                style: const TextStyle(fontSize: 14, color: AppColors.onSurface, fontFamily: 'Manrope'),
                decoration: const InputDecoration(labelText: 'Disbursed By Payer'),
                items: const [
                  DropdownMenuItem(value: 'Alex', child: Text('Alex (Lead Guide)')),
                  DropdownMenuItem(value: 'Partner B', child: Text('Partner Co-Host')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _payer = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Extra Notes / Receipt Info'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final double amt = double.parse(_amountController.text);
                        final newExpense = {
                          'id': 'exp-${DateTime.now().millisecondsSinceEpoch}',
                          'tripId': widget.tripId,
                          'category': _selectedCategory,
                          'amount': amt,
                          'description': _descController.text.trim(),
                          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          'payer': _payer,
                          'notes': _notesController.text.trim(),
                        };
                        widget.onConfirm(newExpense);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 44),
                    ),
                    child: const Text('Add Expense'),
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
