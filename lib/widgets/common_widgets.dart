import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SectionHeader extends StatelessWidget {
const SectionHeader({
super.key,
required this.title,
this.subtitle,
this.action,
});

final String title;
final String? subtitle;
final Widget? action;

@override
Widget build(BuildContext context) {
return Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontSize: 22,
fontWeight: FontWeight.w800,
),
),
if (subtitle != null) ...[
const SizedBox(height: 6),
Text(
subtitle!,
style: TextStyle(color: Colors.grey.shade700),
),
],
],
),
),
if (action != null) action!,
],
);
}
}

class SoftCard extends StatelessWidget {
const SoftCard({
super.key,
required this.child,
this.padding,
});

final Widget child;
final EdgeInsetsGeometry? padding;

@override
Widget build(BuildContext context) {
return Container(
padding: padding ?? const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(24),
boxShadow: [
BoxShadow(
color: AppColors.rose.withOpacity(0.08),
blurRadius: 24,
offset: const Offset(0, 12),
),
],
),
child: child,
);
}
}

class GradientBanner extends StatelessWidget {
const GradientBanner({
super.key,
required this.title,
required this.subtitle,
this.trailing,
});

final String title;
final String subtitle;
final Widget? trailing;

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(28),
gradient: const LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
AppColors.sage,
AppColors.blush,
AppColors.rose,
],
),
),
child: Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.w800,
color: Colors.white,
),
),
const SizedBox(height: 8),
Text(
subtitle,
style: const TextStyle(color: Colors.white),
),
],
),
),
if (trailing != null) trailing!,
],
),
);
}
}

class StatCard extends StatelessWidget {
const StatCard({
super.key,
required this.icon,
required this.title,
required this.value,
});

final IconData icon;
final String title;
final String value;

@override
Widget build(BuildContext context) {
return Expanded(
child: SoftCard(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
CircleAvatar(
backgroundColor: AppColors.sage,
child: Icon(
icon,
color: AppColors.ink,
),
),
const SizedBox(height: 14),
Text(
value,
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 4),
Text(
title,
style: TextStyle(color: Colors.grey.shade700),
),
],
),
),
);
}
}

class PillChip extends StatelessWidget {
const PillChip({
super.key,
required this.text,
required this.color,
this.textColor,
});

final String text;
final Color color;
final Color? textColor;

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 8,
),
decoration: BoxDecoration(
color: color,
borderRadius: BorderRadius.circular(20),
),
child: Text(
text,
style: TextStyle(
fontWeight: FontWeight.w700,
color: textColor ?? AppColors.ink,
),
),
);
}
}

class EmptyPlaceholder extends StatelessWidget {
const EmptyPlaceholder({
super.key,
required this.title,
required this.subtitle,
this.icon = Icons.inbox_outlined,
});

final String title;
final String subtitle;
final IconData icon;

@override
Widget build(BuildContext context) {
return SoftCard(
child: Column(
children: [
CircleAvatar(
radius: 28,
backgroundColor: AppColors.blush.withOpacity(0.35),
child: Icon(
icon,
color: AppColors.rose,
size: 28,
),
),
const SizedBox(height: 14),
Text(
title,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.w700,
),
),
const SizedBox(height: 6),
Text(
subtitle,
textAlign: TextAlign.center,
style: TextStyle(color: Colors.grey.shade700),
),
],
),
);
}
}

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.label,
    this.hasBadge = false,
  });

  final IconData icon;
  final String label;
  final bool hasBadge;
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex == index;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onTap(index),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 62,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.blush
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: isSelected
                                        ? AppColors.ink
                                        : AppColors.ink.withOpacity(0.75),
                                  ),
                                  if (item.hasBadge)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.ink
                                    : AppColors.ink.withOpacity(0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}