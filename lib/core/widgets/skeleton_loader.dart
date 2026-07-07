import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/pointer_lock.dart';

class SkeletonLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Widget skeleton;

  const SkeletonLoader({
    super.key,
    required this.child,
    required this.isLoading,
    required this.skeleton,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _colorAnimation = ColorTween(
      begin: AppColors.surfaceContainerHigh,
      end: AppColors.surfaceContainerLow,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(SkeletonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      lockCanvasPointers();
      Future.delayed(const Duration(milliseconds: 150), () {
        unlockCanvasPointers();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return IgnorePointer(
      ignoring: true,
      child: SkeletonColorScope(
        colorAnimation: _colorAnimation,
        child: widget.skeleton,
      ),
    );
  }
}

class SkeletonColorScope extends InheritedWidget {
  final Animation<Color?> colorAnimation;

  const SkeletonColorScope({
    super.key,
    required this.colorAnimation,
    required super.child,
  });

  static Animation<Color?>? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SkeletonColorScope>()?.colorAnimation;
  }

  @override
  bool updateShouldNotify(SkeletonColorScope oldWidget) {
    return colorAnimation != oldWidget.colorAnimation;
  }
}

class SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colorAnimation = SkeletonColorScope.of(context);

    if (colorAnimation != null) {
      return AnimatedBuilder(
        animation: colorAnimation,
        builder: (context, child) {
          return Container(
            width: width,
            height: height,
            margin: margin,
            decoration: BoxDecoration(
              color: colorAnimation.value ?? AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          );
        },
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBlock(width: 200, height: 32),
          const SizedBox(height: 8),
          const SkeletonBlock(width: double.infinity, height: 16),
          const SizedBox(height: 28),

          // Stats skeletons
          const SkeletonBlock(width: double.infinity, height: 92, borderRadius: 12),
          const SizedBox(height: 16),
          const SkeletonBlock(width: double.infinity, height: 92, borderRadius: 12),
          const SizedBox(height: 28),

          // 3 Action Row buttons skeleton
          Row(
            children: [
              Expanded(child: const SkeletonBlock(width: double.infinity, height: 80, borderRadius: 12)),
              const SizedBox(width: 12),
              Expanded(child: const SkeletonBlock(width: double.infinity, height: 80, borderRadius: 12)),
              const SizedBox(width: 12),
              Expanded(child: const SkeletonBlock(width: double.infinity, height: 80, borderRadius: 12)),
            ],
          ),
          const SizedBox(height: 36),

          // Recent Bookings Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonBlock(width: 150, height: 24),
              SkeletonBlock(width: 60, height: 16),
            ],
          ),
          const SizedBox(height: 16),

          // Recent Bookings Cards
          for (int i = 0; i < 3; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SkeletonBlock(width: 50, height: 50, borderRadius: 8),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBlock(width: 160, height: 16),
                        SizedBox(height: 8),
                        SkeletonBlock(width: 110, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      SkeletonBlock(width: 60, height: 18, borderRadius: 12),
                      SizedBox(height: 8),
                      SkeletonBlock(width: 50, height: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TripsSkeleton extends StatelessWidget {
  const TripsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBlock(width: 240, height: 32),
          const SizedBox(height: 8),
          const SkeletonBlock(width: 280, height: 16),
          const SizedBox(height: 24),

          // Search
          const SkeletonBlock(width: double.infinity, height: 48, borderRadius: 12),
          const SizedBox(height: 24),

          // Chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SkeletonBlock(width: index == 0 ? 120 : 80, height: 40, borderRadius: 20),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 2 Card skeletons
          for (int i = 0; i < 2; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBlock(width: double.infinity, height: 190, borderRadius: 16),
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBlock(width: 160, height: 20),
                        SizedBox(height: 8),
                        SkeletonBlock(width: 120, height: 12),
                        SizedBox(height: 12),
                        SkeletonBlock(width: double.infinity, height: 32),
                        SizedBox(height: 16),
                        SkeletonBlock(width: double.infinity, height: 48, borderRadius: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BookingsSkeleton extends StatelessWidget {
  const BookingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBlock(width: 180, height: 32),
          const SizedBox(height: 8),
          const SkeletonBlock(width: 260, height: 16),
          const SizedBox(height: 24),

          // Search
          const SkeletonBlock(width: double.infinity, height: 48, borderRadius: 12),
          const SizedBox(height: 24),

          // Chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SkeletonBlock(width: 90, height: 40, borderRadius: 20),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Booking Compact Card Skeletons
          for (int i = 0; i < 3; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SkeletonBlock(width: 180, height: 18),
                      SkeletonBlock(width: 80, height: 20, borderRadius: 8),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SkeletonBlock(width: 100, height: 12),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SkeletonBlock(width: 120, height: 12),
                      SkeletonBlock(width: 80, height: 12),
                      SkeletonBlock(width: 60, height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EnquiriesSkeleton extends StatelessWidget {
  const EnquiriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBlock(width: 220, height: 32),
          const SizedBox(height: 8),
          const SkeletonBlock(width: 280, height: 16),
          const SizedBox(height: 24),

          // Search
          const SkeletonBlock(width: double.infinity, height: 48, borderRadius: 12),
          const SizedBox(height: 24),

          // Chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SkeletonBlock(width: 90, height: 40, borderRadius: 20),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Enquiry card skeletons
          for (int i = 0; i < 2; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBlock(width: 140, height: 16),
                  SizedBox(height: 10),
                  SkeletonBlock(width: 120, height: 12),
                  SizedBox(height: 10),
                  SkeletonBlock(width: 180, height: 12),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Hero Card skeleton
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: const [
                SkeletonBlock(width: 90, height: 90, borderRadius: 45),
                SizedBox(height: 16),
                SkeletonBlock(width: 140, height: 20),
                SizedBox(height: 8),
                SkeletonBlock(width: 180, height: 20, borderRadius: 10),
                SizedBox(height: 14),
                SkeletonBlock(width: 220, height: 14),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bento Stats Grid skeleton
          Row(
            children: [
              Expanded(child: const SkeletonBlock(width: double.infinity, height: 88, borderRadius: 16)),
              const SizedBox(width: 12),
              Expanded(child: const SkeletonBlock(width: double.infinity, height: 88, borderRadius: 16)),
              const SizedBox(width: 12),
              Expanded(child: const SkeletonBlock(width: double.infinity, height: 88, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 32),

          // Settings group skeletons
          const SkeletonBlock(width: 100, height: 14),
          const SizedBox(height: 12),
          const SkeletonBlock(width: double.infinity, height: 200, borderRadius: 16),
        ],
      ),
    );
  }
}

class ExpensesSkeleton extends StatelessWidget {
  const ExpensesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBlock(width: 200, height: 28),
          const SizedBox(height: 8),
          const SkeletonBlock(width: double.infinity, height: 14),
          const SizedBox(height: 24),
          const SkeletonBlock(width: double.infinity, height: 80, borderRadius: 12),
          const SizedBox(height: 16),
          for (int i = 0; i < 4; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SkeletonBlock(width: 44, height: 44, borderRadius: 10),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBlock(width: 140, height: 14),
                        SizedBox(height: 8),
                        SkeletonBlock(width: 100, height: 11),
                      ],
                    ),
                  ),
                  const SkeletonBlock(width: 60, height: 18, borderRadius: 8),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CustomersSkeleton extends StatelessWidget {
  const CustomersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBlock(width: 160, height: 28),
          const SizedBox(height: 8),
          const SkeletonBlock(width: double.infinity, height: 14),
          const SizedBox(height: 20),
          const SkeletonBlock(width: double.infinity, height: 48, borderRadius: 12),
          const SizedBox(height: 20),
          for (int i = 0; i < 4; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SkeletonBlock(width: 48, height: 48, borderRadius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBlock(width: 130, height: 14),
                        SizedBox(height: 8),
                        SkeletonBlock(width: 180, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
