import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/utils/currency_formatter.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../controllers/khata_controller.dart';
import '../../config/khata_strings.dart';

class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KhataController>();

    return RepaintBoundary(
      child: Obx(() {
        final isCustomer = controller.currentType.value == PartyType.customer;

        final card1Title = isCustomer ? KhataStrings.totalReceivable : KhataStrings.totalPayable;
        final card1Value = CurrencyFormatter.format(controller.kpiTotalReceivableOrPayable);
        final card1Color = isCustomer ? AppColors.success : AppColors.error;

        final card2Title = isCustomer ? KhataStrings.overdue30Days : KhataStrings.dueThisWeek;
        final card2Value = CurrencyFormatter.format(controller.kpiOverdueOrDueThisWeek);
        final card2Color = AppColors.error;

        final card3Title = isCustomer ? KhataStrings.baqayaCustomers : KhataStrings.baqayaSuppliers;
        final card3Value = controller.kpiPartiesWithBalanceCount;
        const card3Color = AppColors.textPrimary;

        final card4Title = isCustomer ? KhataStrings.todayCollection : KhataStrings.paidThisMonth;
        final card4Value = CurrencyFormatter.format(controller.kpiTodayCollectionOrPaidThisMonth);
        final card4Color = isCustomer ? AppColors.success : AppColors.success;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            if (isDesktop) {
              // Desktop: 4 Cards in 1 Row
              return Row(
                children: [
                  Expanded(child: _buildKpiCard(title: card1Title, value: card1Value, valueColor: card1Color)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildKpiCard(title: card2Title, value: card2Value, valueColor: card2Color)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildKpiCard(title: card3Title, value: card3Value, valueColor: card3Color)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildKpiCard(title: card4Title, value: card4Value, valueColor: card4Color)),
                ],
              );
            } else {
              // Tablet / Mobile: 2x2 Responsive Grid
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildKpiCard(title: card1Title, value: card1Value, valueColor: card1Color)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildKpiCard(title: card2Title, value: card2Value, valueColor: card2Color)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildKpiCard(title: card3Title, value: card3Value, valueColor: card3Color)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildKpiCard(title: card4Title, value: card4Value, valueColor: card4Color)),
                    ],
                  ),
                ],
              );
            }
          },
        );
      }),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
