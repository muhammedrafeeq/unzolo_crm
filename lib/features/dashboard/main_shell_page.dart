import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/offline_banner.dart';
import '../trips/select_trip_page.dart';
import '../bookings/manage_bookings_page.dart';
import '../enquiries/manage_enquiries_page.dart';
import '../expenses/expenses_page.dart';
import '../customers/customers_page.dart';
import 'dashboard_page.dart';

class MainShellPage extends StatefulWidget {
  final int initialIndex;
  const MainShellPage({super.key, this.initialIndex = 0});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late int _currentIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didUpdateWidget(MainShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex && widget.initialIndex != _currentIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
      _pageController.jumpToPage(_currentIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // Dynamic appBar layout depending on index
    final bool centerTitle = _currentIndex == 2; // Centered only for bookings
    final bool showHamburger = _currentIndex == 2 || _currentIndex == 3;

    return PreferredSize(
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
                if (centerTitle) ...[
                  // Bookings centered layout: Hamburger left, Title center, Profile right
                  IconButton(
                    icon: const Icon(LucideIcons.menu, color: AppColors.primary),
                    onPressed: () {},
                  ),
                  Text(
                    'Unzolo',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  _buildProfileAvatar(),
                ] else ...[
                  // Standard layout: Icon/Avatar left, Title next to it, Action right
                  Row(
                    children: [
                      showHamburger
                          ? IconButton(
                              icon: const Icon(LucideIcons.menu, color: AppColors.primary),
                              onPressed: () {},
                            )
                          : _buildProfileAvatar(),
                      const SizedBox(width: 12),
                      Text(
                        'Unzolo',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.bell, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryFixed, width: 2),
        image: const DecorationImage(
          image: NetworkImage(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCeMYIWy9aFlr4UmTFih39PaySc11Z6OIwCmxOxNt4bnC-GY2SB3OHzmdt3GjBIHOjSymPmefKyoXdCIQTRm259a0DgVaT2gCbU3nE0amT2Bm-XwPxy4hYEOT43UizPHdqLgsxq2vHm5fXZdrps9AOO1mk-_XPwYiX_yXlDnOa2mHoVqc8ww95HVl6HkKD9J0ClVxLkKGNFei08Xi5H5kOPR2fhJUsxU7b7iJHO9zFzYZBXAEQ2O2Xy-5VLz8ACi-VBtSpkzIhroYyb',
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 4, 24, 12),
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: LucideIcons.compass,
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => _onTabSelected(0),
              ),
              _buildBottomNavItem(
                icon: LucideIcons.map,
                label: 'Trips',
                isActive: _currentIndex == 1,
                onTap: () => _onTabSelected(1),
              ),
              _buildBottomNavItem(
                icon: LucideIcons.calendar,
                label: 'Bookings',
                isActive: _currentIndex == 2,
                onTap: () => _onTabSelected(2),
              ),
              _buildBottomNavItem(
                icon: LucideIcons.messageSquare,
                label: 'Enquiries',
                isActive: _currentIndex == 3,
                onTap: () => _onTabSelected(3),
              ),
              _buildBottomNavItem(
                icon: LucideIcons.coins,
                label: 'Expenses',
                isActive: _currentIndex == 4,
                onTap: () => _onTabSelected(4),
              ),
              _buildBottomNavItem(
                icon: LucideIcons.users,
                label: 'Customers',
                isActive: _currentIndex == 5,
                onTap: () => _onTabSelected(5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.outline,
                size: 20,
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                KeepAliveWrapper(child: DashboardPage()),
                KeepAliveWrapper(child: SelectTripPage()),
                KeepAliveWrapper(child: ManageBookingsPage()),
                KeepAliveWrapper(child: ManageEnquiriesPage()),
                KeepAliveWrapper(child: ExpensesPage()),
                KeepAliveWrapper(child: CustomersPage()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}


