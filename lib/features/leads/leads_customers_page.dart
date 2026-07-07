import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../enquiries/manage_enquiries_page.dart';
import '../customers/customers_page.dart';

class LeadsCustomersPage extends StatelessWidget {
  const LeadsCustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.surfaceContainerLowest,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceVariant,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Manrope', fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Manrope', fontSize: 14),
              tabs: const [
                Tab(text: 'Leads'),
                Tab(text: 'Customers'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ManageEnquiriesPage(),
                CustomersPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
