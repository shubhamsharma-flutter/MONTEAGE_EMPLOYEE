import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monteage_employee/utils/constants/color_constants.dart';

/// White card with a thin border, the base surface for content on every screen.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12.r);
    return Material(
      color: AppColor.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColor.border),
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.all(16.w),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Icon on a soft tinted square.
class AppIconBox extends StatelessWidget {
  const AppIconBox({
    super.key,
    required this.icon,
    this.color = AppColor.primary,
    this.background = AppColor.primaryTint,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size.h,
      width: size.h,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(icon, color: color, size: (size * 0.55).sp),
    );
  }
}

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 2.h),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    height: 1.4,
                    color: AppColor.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: AppColor.textSecondary,
        ),
      ),
    );
  }
}

/// Full-width main action, with a spinner while [isLoading].
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      disabledBackgroundColor: AppColor.primaryLight,
      disabledForegroundColor: Colors.white,
    );
    final text = Text(
      label,
      style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600),
    );

    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: isLoading
          ? FilledButton(
              onPressed: null,
              style: style,
              child: SizedBox(
                height: 22.h,
                width: 22.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            )
          : icon == null
              ? FilledButton(onPressed: onPressed, style: style, child: text)
              : FilledButton.icon(
                  onPressed: onPressed,
                  style: style,
                  icon: Icon(icon, size: 20.sp),
                  label: text,
                ),
    );
  }
}

/// Centered message for empty and error states, with an optional action.
class AppMessageState extends StatelessWidget {
  const AppMessageState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color = AppColor.primary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(20.w),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            AppIconBox(
              icon: icon,
              color: color,
              background: color.withValues(alpha: 0.10),
              size: 48,
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                height: 1.4,
                color: AppColor.textMuted,
              ),
            ),
            if (actionLabel != null) ...[
              SizedBox(height: 14.h),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class AppNavItem {
  const AppNavItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Flat bottom navigation. [currentIndex] is null on screens outside the tabs.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.items, this.currentIndex});

  final List<AppNavItem> items;
  final int? currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(top: BorderSide(color: AppColor.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _AppNavButton(
                  item: items[i],
                  isActive: i == currentIndex,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppNavButton extends StatelessWidget {
  const _AppNavButton({required this.item, required this.isActive});

  final AppNavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColor.primary : AppColor.textMuted;

    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: isActive ? AppColor.primaryTint : Colors.transparent,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Icon(item.icon, size: 22.sp, color: color),
            ),
            SizedBox(height: 3.h),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
