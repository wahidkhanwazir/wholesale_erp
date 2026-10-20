import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/widgets/desktop_layout.dart';
import 'package:wholesale_app/core/widgets/custom_button.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../controllers/khata_controller.dart';
import '../config/khata_strings.dart';
import 'widgets/kpi_strip.dart';
import 'widgets/party_list_panel.dart';
import 'widgets/party_detail_panel.dart';
import 'widgets/party_form_dialog.dart';
import 'widgets/payment_dialog.dart';

class KhataView extends StatelessWidget {
  final String currentRoute;
  final PartyType initialType;

  const KhataView({
    super.key,
    required this.currentRoute,
    this.initialType = PartyType.customer,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure KhataController is registered
    final controller = Get.put(KhataController());
    if (initialType != controller.currentType.value) {
      controller.currentType.value = initialType;
    }

    return Obx(() {
      final config = controller.config;
      final isCustomer = controller.currentType.value == PartyType.customer;

      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
            controller.searchFocusNode.requestFocus();
          },
          const SingleActivator(LogicalKeyboardKey.f2): () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => PaymentDialog(
                type: controller.currentType.value,
                initialParty: controller.selectedParty,
              ),
            );
          },
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => PartyFormDialog(
                type: controller.currentType.value,
              ),
            );
          },
        },
        child: DesktopLayout(
          currentRoute: currentRoute,
          title: KhataStrings.khataTitle,
          subtitle: config.subtitle,

          // 1. Mode Switcher Dropdown Pill right next to "Khata" title
          titleSuffix: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: PopupMenuButton<PartyType>(
              initialValue: controller.currentType.value,
              tooltip: 'Switch Khata Mode',
              offset: const Offset(0, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border),
              ),
              onSelected: (type) => controller.switchType(type),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    config.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 20),
                ],
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: PartyType.customer,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Customers',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isCustomer ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Lene hain (Receivable)',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (isCustomer) const Icon(Icons.check, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: PartyType.supplier,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Suppliers',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: !isCustomer ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Dene hain (Payable)',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (!isCustomer) const Icon(Icons.check, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Header Action Buttons (Sleek compact sizing)
          headerActions: [
            // Primary Action Button (Receive Payment / Pay Supplier)
            CustomButton(
              text: config.primaryBtnText,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => PaymentDialog(
                    type: controller.currentType.value,
                    initialParty: controller.selectedParty,
                  ),
                );
              },
            ),
            const SizedBox(width: 6),

            // Secondary Action Button (+ Add Customer / + Add Supplier)
            CustomButton(
              text: config.addPartyBtnText,
              isSecondary: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => PartyFormDialog(
                    type: controller.currentType.value,
                  ),
                );
              },
            ),
          ],

          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top KPI Summary Cards Strip
                const KpiStrip(),
                const SizedBox(height: 16),

                // Main Split View Area
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 768;

                      if (isMobile) {
                        // Mobile (<768px): Single pane (List view or Detail view with Back button)
                        if (controller.isDetailView.value && controller.selectedParty != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextButton.icon(
                                onPressed: () => controller.goBackToList(),
                                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                label: const Text('Back to List', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(height: 8),
                              const Expanded(
                                child: SingleChildScrollView(
                                  child: PartyDetailPanel(),
                                ),
                              ),
                            ],
                          );
                        }
                        return const PartyListPanel(width: double.infinity);
                      }

                      // Desktop / Tablet (>=768px): Split View Layout (~30% List, ~70% Detail)
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Expanded(
                            flex: 3, // ~30% width
                            child: PartyListPanel(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 7, // ~70% width
                            child: controller.selectedParty != null
                                ? const SingleChildScrollView(
                                    child: PartyDetailPanel(),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(40),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Select a party from the list to view their running Khata statement.',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
