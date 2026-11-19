import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/sales_controller.dart';
import '../infrastructure/routes/admin_routes.dart';
import '../services/sales_api.dart';
import '../utils/constants/color_constants.dart';
import '../widgets/app_ui.dart';
import '../widgets/leave_ui.dart';
import '../widgets/sales_ui.dart';

/// One searchable lead list; which one comes from the [SalesListType]
/// route argument.
class SalesLeadListScreen extends StatefulWidget {
  const SalesLeadListScreen({super.key});

  @override
  State<SalesLeadListScreen> createState() => _SalesLeadListScreenState();
}

class _SalesLeadListScreenState extends State<SalesLeadListScreen> {
  final SalesController controller = Get.find<SalesController>();
  final SalesListType type = Get.arguments as SalesListType;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  // Completed follow-ups are history; everything else can be updated.
  bool get _canUpdate => type != SalesListType.completedToday;

  @override
  void initState() {
    super.initState();
    final state = controller.stateOf(type);
    if (!state.hasLoaded.value && !state.isLoading.value) {
      controller.load(type);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.stateOf(type);

    return SalesScaffold(
      title: type.title,
      subtitle: 'Pull down to refresh',
      floatingActionButton: type == SalesListType.todayVisits ||
              type == SalesListType.allVisits
          ? FloatingActionButton.extended(
              onPressed: () => Get.toNamed(AdminRoutes.salesAddVisit),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add Visit'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => controller.load(type),
        child: Obx(() {
          final q = _query.trim().toLowerCase();
          final leads = q.isEmpty
              ? state.leads.toList()
              : state.leads.where((l) => l.searchText.contains(q)).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
            children: [
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search by organization, name or phone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          }),
                        ),
                ),
              ),
              SizedBox(height: 14.h),
              if (state.isLoading.value && !state.hasLoaded.value)
                const LeaveLoadingCards()
              else if (state.errorMessage.value.isNotEmpty)
                AppMessageState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Could not load ${type.title.toLowerCase()}',
                  message: state.errorMessage.value,
                  actionLabel: 'Retry',
                  onAction: () => controller.load(type),
                  color: AppColor.danger,
                )
              else if (leads.isEmpty)
                AppMessageState(
                  icon: q.isEmpty
                      ? Icons.inbox_rounded
                      : Icons.search_off_rounded,
                  title: q.isEmpty ? 'Nothing here yet' : 'No matches',
                  message: q.isEmpty
                      ? 'There are no ${type.title.toLowerCase()} right now.'
                      : 'No lead matches "$_query".',
                )
              else ...[
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Text(
                    '${leads.length} ${leads.length == 1 ? 'lead' : 'leads'}',
                    style: LeaveText.body(12.5),
                  ),
                ),
                for (final lead in leads)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: SalesLeadCard(
                      lead: lead,
                      onTap: () => Get.toNamed(
                        AdminRoutes.salesLeadDetail,
                        arguments: lead,
                      ),
                      onUpdate: _canUpdate
                          ? () => showSalesFollowupSheet(context, lead)
                          : null,
                    ),
                  ),
              ],
            ],
          );
        }),
      ),
    );
  }
}
