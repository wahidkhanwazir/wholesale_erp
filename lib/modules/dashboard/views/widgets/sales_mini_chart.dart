import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../controllers/dashboard_controller.dart';

class SalesMiniChart extends StatelessWidget {
  final List<DashboardDaySales> data;

  const SalesMiniChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxAmount = data.isEmpty
        ? 100000.0
        : data.map((e) => e.amount).reduce(max).clamp(50000.0, double.infinity);

    final totalWeekSales = data.fold(0.0, (sum, e) => sum + e.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Sales Performance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Last 7 days turnover across wholesale orders',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Total: ${CurrencyFormatter.format(totalWeekSales)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar Chart Area
          SizedBox(
            height: 195,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == data.length - 1; // Today
                final barRatio = (item.amount / maxAmount).clamp(0.05, 1.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Amount Label on Top
                        Text(
                          item.amount > 0
                              ? CurrencyFormatter.formatCompact(item.amount)
                              : '0',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isLast
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // The Bar
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: barRatio,
                              child: Container(
                                width: 22,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: isLast
                                        ? [AppColors.accent, AppColors.primary]
                                        : [
                                            const Color(0xFF68B28B),
                                            const Color(0xFF2D6A4F),
                                          ],
                                  ),
                                  boxShadow: isLast
                                      ? [
                                          BoxShadow(
                                            color: AppColors.accent.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 5,
                                            offset: const Offset(0, -2),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Day Name
                        Text(
                          item.dayLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isLast
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isLast
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item.count > 0 ? '${item.count} ord' : '—',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: item.count > 0
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
