import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

// ── Stat Card ────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? color;
  final IconData? icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, color: accent, size: 14),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 0.5)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      color: accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(unit!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status; // 'completed' | 'running' | 'not_run' | 'error'

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        color = AppTheme.success;
        label = 'Completed';
        icon = Icons.check_circle_outline;
        break;
      case 'running':
        color = AppTheme.warning;
        label = 'Running';
        icon = Icons.sync;
        break;
      case 'error':
        color = AppTheme.error;
        label = 'Error';
        icon = Icons.error_outline;
        break;
      default:
        color = AppTheme.textSecondary;
        label = 'Not Run';
        icon = Icons.radio_button_unchecked;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 5),
        Text(label,
            style:
                TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: AppTheme.primary,
            margin: const EdgeInsets.only(right: 10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              if (subtitle != null)
                Text(subtitle!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Shimmer Loading ───────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox(
      {super.key, required this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.bgCardLight,
      highlightColor: AppTheme.bgCard.withOpacity(0.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.bgCardLight,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// ── Glowing Button ────────────────────────────────────────────────────────────
class GlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color? color;

  const GlowButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: loading ? accent.withOpacity(0.3) : accent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: loading
              ? []
              : [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 16, spreadRadius: 1)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgDark),
              )
            else if (icon != null)
              Icon(icon, size: 18, color: AppTheme.bgDark),
            if (icon != null || loading) const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.bgDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
