import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../shared/models/enums.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.fromPaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const StatusBadge(
          label: 'Paid',
          backgroundColor: AppColors.successLight,
          textColor: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case PaymentStatus.partial:
        return const StatusBadge(
          label: 'Partial',
          backgroundColor: AppColors.warningLight,
          textColor: AppColors.warning,
          icon: Icons.timelapse,
        );
      case PaymentStatus.unpaid:
        return const StatusBadge(
          label: 'Unpaid',
          backgroundColor: AppColors.errorLight,
          textColor: AppColors.error,
          icon: Icons.error_outline,
        );
    }
  }

  factory StatusBadge.fromStockStatus(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return const StatusBadge(
          label: 'In Stock',
          backgroundColor: AppColors.successLight,
          textColor: AppColors.success,
          icon: Icons.inventory_2_outlined,
        );
      case StockStatus.lowStock:
        return const StatusBadge(
          label: 'Low Stock',
          backgroundColor: AppColors.warningLight,
          textColor: AppColors.warning,
          icon: Icons.warning_amber_rounded,
        );
      case StockStatus.outOfStock:
        return const StatusBadge(
          label: 'Out of Stock',
          backgroundColor: AppColors.errorLight,
          textColor: AppColors.error,
          icon: Icons.remove_circle_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
