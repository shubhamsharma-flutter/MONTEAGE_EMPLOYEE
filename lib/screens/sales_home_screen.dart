import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../controllers/sales_controller.dart';
import '../infrastructure/routes/admin_routes.dart';
import '../services/sales_api.dart';
import '../utils/constants/color_constants.dart';
import '../widgets/app_ui.dart';
import '../widgets/leave_ui.dart';
import '../widgets/sales_ui.dart';

class SalesHomeScreen extends GetView<SalesController> {
  const SalesHomeScreen({super.key});

  static const _tiles = <(SalesListType, IconData, Color)>[
    (
      SalesListType.todayFollowups,
      Icons.phone_in_talk_rounded,
      AppColor.primary,
    ),
    (SalesListType.todayVisits, Icons.location_on_rounded, AppColor.accent),
    (SalesListType.completedToday, Icons.task_alt_rounded, AppColor.success),
    (SalesListType.nextDay, Icons.event_rounded, AppColor.warning),
    (SalesListType.nextWeek, Icons.date_range_rounded, AppColor.info),
    (SalesListType.allVisits, Icons.map_rounded, Color(0xFF7C3AED)),
  ];

  @override
  Widget build(BuildContext context) {
    return SalesScaffold(
      title: 'CRM',
      subtitle: 'Visits & follow-ups',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: controller.relink,
        ),
      ],
      floatingActionButton: Obx(
        () => controller.isLinked
            ? FloatingActionButton.extended(
                onPressed: () => Get.toNamed(AdminRoutes.salesAddVisit),
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text('Add Visit'),
              )
            : const SizedBox.shrink(),
      ),
      body: Obx(() {
        if (!controller.isLinked) {
          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              AppMessageState(
                icon: Icons.link_off_rounded,
                title: 'Sales account not linked',
                message:
                    'Your employee profile has no sales id yet. Ask your admin '
                    'to link your sales account, then log out and sign in '
                    'again.',
                actionLabel: 'Check again',
                onAction: controller.relink,
                color: AppColor.warning,
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
            children: [
              _SummaryHeader(controller: controller),
              SizedBox(height: 24.h),
              const AppSectionTitle(
                title: 'Your lists',
                subtitle: 'Tap a list to see its leads',
              ),
              SizedBox(height: 12.h),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
                childAspectRatio: 1.35,
                children: [
                  for (final (type, icon, color) in _tiles)
                    _ListTile(
                      type: type,
                      icon: icon,
                      color: color,
                      state: controller.stateOf(type),
                    ),
                ],
              ),
              SizedBox(height: 24.h),
              AppSectionTitle(
                title: 'Today\'s follow-ups',
                subtitle: 'Leads to contact today',
                trailing: TextButton.icon(
                  onPressed: () => _openList(SalesListType.todayFollowups),
                  iconAlignment: IconAlignment.end,
                  icon: Icon(Icons.arrow_forward_rounded, size: 16.sp),
                  label: const Text('See all'),
                ),
              ),
              SizedBox(height: 12.h),
              _TodayPreview(controller: controller),
            ],
          ),
        );
      }),
    );
  }
}

void _openList(SalesListType type) =>
    Get.toNamed(AdminRoutes.salesLeads, arguments: type);

String _countText(SalesListState state) {
  if (!state.hasLoaded.value) return state.isLoading.value ? '…' : '-';
  return state.leads.length.toString();
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.controller});

  final SalesController controller;

  @override
  Widget build(BuildContext context) => Obx(_build);

  Widget _build() {
    final name = controller.salesName.value.trim();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.primaryLight, AppColor.primary, AppColor.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: const [
          BoxShadow(
            color: AppColor.primaryGlow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Soft decorative circles.
          Positioned(right: -40.w, top: -50.h, child: _circle(150.w)),
          Positioned(right: 50.w, bottom: -70.h, child: _circle(120.w)),
          Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 11.sp,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  DateFormat('EEEE, dd MMM')
                                      .format(DateTime.now()),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            name.isEmpty
                                ? greeting
                                : '$greeting, ${name.split(' ').first}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 19.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Here\'s your sales day at a glance',
                            style: GoogleFonts.inter(
                              fontSize: 12.5.sp,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 26.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    _HeaderStat(
                      icon: Icons.phone_in_talk_rounded,
                      label: 'Follow-ups',
                      state: controller.stateOf(SalesListType.todayFollowups),
                    ),
                    SizedBox(width: 8.w),
                    _HeaderStat(
                      icon: Icons.location_on_rounded,
                      label: 'Visits today',
                      state: controller.stateOf(SalesListType.todayVisits),
                    ),
                    SizedBox(width: 8.w),
                    _HeaderStat(
                      icon: Icons.task_alt_rounded,
                      label: 'Completed',
                      state: controller.stateOf(SalesListType.completedToday),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.06),
    ),
  );
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.state,
  });

  final IconData icon;
  final String label;
  final SalesListState state;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16.sp, color: Colors.white.withValues(alpha: 0.9)),
            SizedBox(height: 6.h),
            Text(
              _countText(state),
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.type,
    required this.icon,
    required this.color,
    required this.state,
  });

  final SalesListType type;
  final IconData icon;
  final Color color;
  final SalesListState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _openList(type),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBox(
                icon: icon,
                color: color,
                background: color.withValues(alpha: 0.10),
                size: 38,
              ),
              const Spacer(),
              Obx(
                () => Text(
                  _countText(state),
                  style: GoogleFonts.inter(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  type.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20.sp,
                color: AppColor.textDisabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayPreview extends StatelessWidget {
  const _TodayPreview({required this.controller});

  final SalesController controller;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final state = controller.stateOf(SalesListType.todayFollowups);
    if (state.isLoading.value && !state.hasLoaded.value) {
      return const LeaveLoadingCards(count: 2);
    }
    if (state.errorMessage.value.isNotEmpty) {
      return AppMessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load follow-ups',
        message: state.errorMessage.value,
        actionLabel: 'Retry',
        onAction: () => controller.load(SalesListType.todayFollowups),
        color: AppColor.danger,
      );
    }
    if (state.leads.isEmpty) {
      return const AppMessageState(
        icon: Icons.celebration_rounded,
        title: 'No follow-ups today',
        message: 'You\'re all caught up. Add a visit to start a new lead.',
        color: AppColor.success,
      );
    }
    return Column(
      children: [
        for (final lead in state.leads.take(3))
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: SalesLeadCard(
              lead: lead,
              onTap: () =>
                  Get.toNamed(AdminRoutes.salesLeadDetail, arguments: lead),
              onUpdate: () => showSalesFollowupSheet(context, lead),
            ),
          ),
      ],
    );
  }
}
