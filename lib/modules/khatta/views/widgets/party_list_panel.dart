import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/utils/currency_formatter.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../controllers/khata_controller.dart';
import '../../models/party_model.dart';
import '../../config/khata_strings.dart';

class PartyListPanel extends StatelessWidget {
  final double? width;

  const PartyListPanel({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KhataController>();

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Search Field & Filter Chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  final activeQuery = controller.activeSearchQuery;
                  return TextField(
                    focusNode: controller.searchFocusNode,
                    controller: TextEditingController(text: activeQuery)
                      ..selection = TextSelection.collapsed(offset: activeQuery.length),
                    onChanged: (val) => controller.activeSearchQuery = val,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: controller.config.searchHint,
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                      suffixIcon: activeQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                              onPressed: () => controller.activeSearchQuery = '',
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      fillColor: AppColors.background,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),

                // Filter Chips Row
                Obx(() {
                  final currentFilter = controller.activeFilter;
                  final isCustomer = controller.currentType.value == PartyType.customer;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'All',
                          isSelected: currentFilter == FilterChipType.all,
                          onTap: () => controller.activeFilter = FilterChipType.all,
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: KhataStrings.baqaya,
                          isSelected: currentFilter == FilterChipType.baqaya,
                          onTap: () => controller.activeFilter = FilterChipType.baqaya,
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: isCustomer ? KhataStrings.overdue : KhataStrings.dueSoon,
                          isSelected: currentFilter == FilterChipType.overdueOrDueSoon,
                          onTap: () => controller.activeFilter = FilterChipType.overdueOrDueSoon,
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: KhataStrings.advance,
                          isSelected: currentFilter == FilterChipType.advance,
                          onTap: () => controller.activeFilter = FilterChipType.advance,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1),

          // List Subheader with Sort Options
          Obx(() {
            final parties = controller.partyList;
            final isCustomer = controller.currentType.value == PartyType.customer;
            final currentSort = controller.activeSort;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${isCustomer ? "CUSTOMERS" : "SUPPLIERS"} (${parties.length})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  PopupMenuButton<SortType>(
                    initialValue: currentSort,
                    onSelected: (sort) => controller.activeSort = sort,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentSort == SortType.balanceDesc ? 'BAQAYA ▾' : 'NAME ▾',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: SortType.balanceDesc,
                        child: Text('Sort by Highest Balance', style: TextStyle(fontSize: 12)),
                      ),
                      const PopupMenuItem(
                        value: SortType.nameAsc,
                        child: Text('Sort by Name (A-Z)', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 1),

          // Party Rows List (Independent vertical scroll inside list panel)
          Expanded(
            child: Obx(() {
              final parties = controller.partyList;
              final selected = controller.selectedParty;

              if (parties.isEmpty) {
                return const Center(
                  child: Text(
                    'No parties found.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                );
              }

              return ListView.separated(
                itemCount: parties.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final party = parties[index];
                  final isSelected = selected?.id == party.id;

                  return _buildPartyRow(
                    context: context,
                    party: party,
                    isSelected: isSelected,
                    onTap: () => controller.selectParty(party.id),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPartyRow({
    required BuildContext context,
    required PartyModel party,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isCustomer = party.type == PartyType.customer;
    final accentColor = isCustomer ? AppColors.primary : AppColors.secondary;

    Color amountColor;
    if (party.balance > 0) {
      amountColor = AppColors.error;
    } else if (party.balance < 0) {
      amountColor = AppColors.success;
    } else {
      amountColor = AppColors.textMuted;
    }

    return Material(
      color: isSelected
          ? accentColor.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: isSelected
                ? Border(left: BorderSide(color: accentColor, width: 4))
                : null,
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: accentColor.withValues(alpha: 0.15),
                child: Text(
                  party.initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Name & City/Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${party.city} • ${party.phone}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Balance & Caption
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormatter.format(party.balance.abs()),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    party.statusCaption,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
