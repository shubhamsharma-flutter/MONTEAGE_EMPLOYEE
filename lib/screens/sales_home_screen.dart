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
    (SalesListType.todayFollowups, Icons.phone_callback_rounded, AppColor.primary),
    (SalesListType.todayVisits, Icons.place_rounded, AppColor.accent),
    (SalesListType.completedToday, Icons.task_alt_rounded, AppColor.success),
    (SalesListType.nextDay, Icons.today_rounded, AppColor.warning),
    (SalesListType.nextWeek, Icons.date_range_rounded, AppColor.info),
    (SalesListType.allVisits, Icons.storefront_rounded, AppColor.textSecondary),
  ];

  @override
  Widget build(BuildContext context) {
    return SalesScaffold(
      title: 'Sales',
      subtitle: 'Visits & follow-ups',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: controller.relink,
        ),
      ],
      floatingActionButton: Obx(() => controller.isLinked
          ? FloatingActionButton.extended(
              onPressed: () => Get.toNamed(AdminRoutes.salesAddVisit),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add Visit'),
            )
          : const SizedBox.shrink()),
      body: Obx(() {
        if (!controller.isLinked) {
          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              AppMessageState(
                icon: Icons.link_off_rounded,
                title: 'Sales account not linked',
                message:
                    'Your sales account is linked when you sign in, using your '
                    'registered mobile number and password. Log out and sign in '
                    'again. If it still does not appear, ask your admin to '
                    'create a sales account for your mobile number.',
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
              SizedBox(height: 20.h),
              const AppSectionTitle(title: 'Your lists'),
              SizedBox(height: 10.h),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
                childAspectRatio: 1.45,
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
                trailing: TextButton(
                  onPressed: () => _openList(SalesListType.todayFollowups),
                  child: const Text('See all'),
                ),
              ),
              SizedBox(height: 10.h),
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

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.controller});

  final SalesController controller;

  @override
  Widget build(BuildContext context) => Obx(_build);

  Widget _build() {
    final name = controller.salesName.value.trim();
    final followups = controller.stateOf(SalesListType.todayFollowups);
    final visits = controller.stateOf(SalesListType.todayVisits);
    final done = controller.stateOf(SalesListType.completedToday);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.primary, AppColor.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, dd MMM').format(DateTime.now()),
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            name.isEmpty ? 'Your sales day' : 'Hi ${name.split(' ').first}, here\'s your day',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _HeaderStat(label: 'Follow-ups due', state: followups),
              _HeaderStat(label: 'Visits today', state: visits),
              _HeaderStat(label: 'Completed', state: done),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.state});

  final String label;
  final SalesListState state;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _countText(state),
            style: GoogleFonts.inter(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

String _countText(SalesListState state) {
  if (!state.hasLoaded.value) return state.isLoading.value ? '…' : '-';
  return state.leads.length.toString();
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
                size: 36,
              ),
              const Spacer(),
              Obx(() => Text(
                    _countText(state),
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColor.textPrimary,
                    ),
                  )),
            ],
          ),
          const Spacer(),
          Text(
            type.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColor.textPrimary,
            ),
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
        icon: Icons.event_available_rounded,
        title: 'No follow-ups today',
        message: 'You\'re all caught up. Add a visit to start a new lead.',
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
