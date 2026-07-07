import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/widgets/premium_filter_chip.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/utils/pointer_lock.dart';
import '../../core/state/unzolo_state.dart';
import '../../core/responsive_utils.dart';

class SelectTripPage extends ConsumerStatefulWidget {
  const SelectTripPage({super.key});

  @override
  ConsumerState<SelectTripPage> createState() => _SelectTripPageState();
}

class _SelectTripPageState extends ConsumerState<SelectTripPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedCategory = 'All Expeditions';
  String _searchQuery = '';
  bool _isSearchFocused = false;

  // Sorting state
  String _sortBy = 'title'; // 'title', 'price', 'date'
  bool _sortAscending = true;

  void _updateState(VoidCallback fn) {
    if (!mounted) return;
    lockCanvasPointers();
    setState(() {
      fn();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unlockCanvasPointers();
    });
  }

  final List<String> _categories = [
    'All Expeditions',
    'Camps',
    'Packages',
    'Trekking',
    'Photography',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _updateState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'All Expeditions':
        return LucideIcons.compass;
      case 'Camps':
        return LucideIcons.tent;
      case 'Packages':
        return LucideIcons.briefcase;
      case 'Trekking':
        return LucideIcons.mountain;
      case 'Photography':
        return LucideIcons.camera;
      default:
        return LucideIcons.compass;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredTripsList(List<Map<String, dynamic>> tripsList) {
    var list = tripsList.where((trip) {
      final title = (trip['title'] as String).toLowerCase();
      final loc = (trip['location'] as String).toLowerCase();
      final cat = trip['category'] as String;

      final matchesQuery = title.contains(_searchQuery) || loc.contains(_searchQuery);
      final matchesCategory = _selectedCategory == 'All Expeditions' || cat == _selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();

    // Sorting logic
    list.sort((a, b) {
      int comparison = 0;
      if (_sortBy == 'price') {
        comparison = (a['price'] as int).compareTo(b['price'] as int);
      } else if (_sortBy == 'title') {
        comparison = (a['title'] as String).compareTo(b['title'] as String);
      } else {
        // Sort by Date (camps have startDates, packages do not, packages go to end)
        final aDate = DateTime.tryParse(a['startDate'] ?? '') ?? DateTime(2099);
        final bDate = DateTime.tryParse(b['startDate'] ?? '') ?? DateTime(2099);
        comparison = aDate.compareTo(bDate);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return list;
  }

  void _showDeletedTripsDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final deleted = ref.watch(deletedTripsProvider).value ?? [];
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
                        'Deleted Trips Ledger',
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
                  if (deleted.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No deleted trips found.',
                          style: TextStyle(color: AppColors.outline, fontFamily: 'Manrope'),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: deleted.length,
                        itemBuilder: (context, index) {
                          final trip = deleted[index];
                          return Card(
                            color: AppColors.surfaceContainerLowest,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.outlineVariant),
                            ),
                            child: ListTile(
                              title: Text(
                                trip['title'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Manrope'),
                              ),
                              subtitle: Text(
                                '${trip['location']} • ₹${trip['price']}',
                                style: const TextStyle(fontSize: 12, fontFamily: 'Manrope'),
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () async {
                                  await ref.read(deletedTripsProvider.notifier).restoreTrip(trip['id']);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${trip['title']} restored successfully!'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                                icon: const Icon(LucideIcons.rotateCcw, size: 14, color: Colors.white),
                                label: const Text('Restore', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);
    final tripsList = tripsAsync.value ?? [];
    final trips = _filteredTripsList(tripsList);

    return SkeletonLoader(
      isLoading: tripsAsync.isLoading,
      skeleton: const TripsSkeleton(),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: context.vPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Title & Subtitle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trips',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: AppColors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Curated expeditions for the bold and the inspired.',
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                // FAB for adding trip
                FloatingActionButton.small(
                  heroTag: null,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.createTrip),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(LucideIcons.plus),
                ),
              ],
            ),
            const SizedBox(height: 24),
  
            // Search Bar
            AnimatedScale(
              scale: _isSearchFocused ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSearchFocused ? AppColors.primary : AppColors.outlineVariant,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Search destinations, peaks, or expeditions',
                    border: InputBorder.none,
                    icon: Icon(LucideIcons.search, color: AppColors.outline),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
  
            // Category Chips
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isActive = cat == _selectedCategory;
                  return PremiumFilterChip(
                    label: cat,
                    isActive: isActive,
                    icon: _getCategoryIcon(cat),
                    onTap: () {
                      _updateState(() {
                        _selectedCategory = cat;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Sorting & Deleted Trips Drawer Row
            Row(
              children: [
                const Icon(LucideIcons.sliders, size: 16, color: AppColors.outline),
                const SizedBox(width: 8),
                const Text(
                  'Sort By:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.outline,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Manrope'),
                  items: const [
                    DropdownMenuItem(value: 'title', child: Text('Title')),
                    DropdownMenuItem(value: 'price', child: Text('Price')),
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _updateState(() {
                        _sortBy = val;
                      });
                    }
                  },
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    _sortAscending ? LucideIcons.arrowUpNarrowWide : LucideIcons.arrowDownWideNarrow,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    _updateState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showDeletedTripsDrawer,
                  icon: const Icon(LucideIcons.archive, size: 16, color: AppColors.outline),
                  label: const Text(
                    'Archive',
                    style: TextStyle(fontSize: 12, color: AppColors.outline, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.outlineVariant),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vertically Stacked Trip Cards
            if (trips.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.map, size: 56, color: AppColors.outlineVariant),
                      const SizedBox(height: 16),
                      const Text(
                        'No trips found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add your first expedition using the + button above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: trips.map((trip) => _buildTripCard(trip)).toList(),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    return GestureDetector(
      onTap: () {
        ref.read(bookingsTripFilterProvider.notifier).set(trip['id'] as String);
        Navigator.pushNamed(context, AppRoutes.manageBookings);
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
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
              Expanded(
                child: Text(
                  trip['title'],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.onSurface,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹${trip['price']}',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, color: AppColors.outline, size: 14),
              const SizedBox(width: 6),
              Text(
                trip['location'],
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            trip['description'],
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Difficulty Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.activity, size: 12, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      trip['duration'],
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trip['statusBg'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trip['status'],
                  style: TextStyle(
                    color: trip['statusText'],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.createBooking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Booking',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Theme(
                data: Theme.of(context).copyWith(
                  cardColor: AppColors.surfaceContainerLowest,
                ),
                child: PopupMenuButton<String>(
                  onSelected: (value) async {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    if (value == 'edit') {
                      final updatedTrip = await Navigator.pushNamed(
                        context,
                        AppRoutes.editTrip,
                        arguments: trip,
                      );
                      if (updatedTrip != null && updatedTrip is Map<String, dynamic>) {
                        await ref.read(tripsProvider.notifier).updateTrip(updatedTrip);
                      }
                    } else if (value == 'delete') {
                      await ref.read(tripsProvider.notifier).deleteTrip(trip['id']);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${trip['title']} moved to Deleted Trips Drawer'),
                          backgroundColor: AppColors.error,
                          action: SnackBarAction(
                            label: 'UNDO',
                            textColor: Colors.white,
                            onPressed: () async {
                              final deleted = ref.read(deletedTripsProvider).value ?? [];
                              if (deleted.isNotEmpty) {
                                await ref.read(deletedTripsProvider.notifier).restoreTrip(deleted.last['id']);
                              }
                            },
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(LucideIcons.edit2, size: 16, color: AppColors.onSurfaceVariant),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(fontFamily: 'Manrope')),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.settings, size: 20, color: AppColors.primary),
                  ),
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
