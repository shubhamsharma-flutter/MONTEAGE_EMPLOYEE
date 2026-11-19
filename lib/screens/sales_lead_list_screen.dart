import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/sales_controller.dart';
import '../infrastructure/routes/admin_routes.dart';
import '../models/sales_lead_model.dart';
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

  /// Selected status filter; null shows every status.
  String? _status;

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
      subtitle: salesListCaption(type),
      floatingActionButton:
          type == SalesListType.todayVisits || type == SalesListType.allVisits
          ? FloatingActionButton.extended(
              onPressed: () => Get.toNamed(AdminRoutes.salesAddVisit),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add Visit'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => controller.load(type),
        child: Obx(() {
          final all = state.leads.toList();

          // Status counts for the filter chips, most common first.
          final counts = <String, int>{};
          for (final l in all) {
            counts[l.action] = (counts[l.action] ?? 0) + 1;
          }
          final statuses = counts.keys.toList()
            ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
          final status = counts.containsKey(_status) ? _status : null;

          final q = _query.trim().toLowerCase();
          final leads = all
              .where((l) => status == null || l.action == status)
              .where((l) => q.isEmpty || l.searchText.contains(q))
              .toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
            children: [
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search organization, name or phone',
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
              if (statuses.length > 1) ...[
                SizedBox(height: 12.h),
                SizedBox(
                  height: 34.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'All',
                        count: all.length,
                        icon: Icons.apps_rounded,
                        color: AppColor.primary,
                        selected: status == null,
                        onTap: () => setState(() => _status = null),
                      ),
                      for (final s in statuses)
                        _FilterChip(
                          label: s.isEmpty ? 'New' : s,
                          count: counts[s]!,
                          icon: salesStatusIcon(s),
                          color: salesStatusColor(s),
                          selected: status == s,
                          onTap: () => setState(() => _status = s),
                        ),
                    ],
                  ),
                ),
              ],
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
                  icon: q.isEmpty && status == null
                      ? Icons.inbox_rounded
                      : Icons.search_off_rounded,
                  title: q.isEmpty && status == null
                      ? 'Nothing here yet'
                      : 'No matches',
                  message: q.isEmpty && status == null
                      ? 'There are no ${type.title.toLowerCase()} right now.'
                      : 'No lead matches your search or filter.',
                )
              else ...[
                _ResultCount(count: leads.length, total: all.length),
                for (final lead in leads)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: SalesLeadCard(
                      lead: lead,
                      onTap: () => _openLead(lead),
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

  void _openLead(SalesLead lead) =>
      Get.toNamed(AdminRoutes.salesLeadDetail, arguments: lead);
}

class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final noun = total == 1 ? 'lead' : 'leads';
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h, left: 2.w),
      child: Row(
        children: [
          Icon(Icons.groups_rounded, size: 16.sp, color: AppColor.textMuted),
          SizedBox(width: 6.w),
          Text(
            count == total ? '$total $noun' : 'Showing $count of $total $noun',
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : AppColor.surface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: selected ? color : AppColor.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.sp, color: selected ? Colors.white : color),
              SizedBox(width: 6.w),
              Text(
                '$label  $count',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColor.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
