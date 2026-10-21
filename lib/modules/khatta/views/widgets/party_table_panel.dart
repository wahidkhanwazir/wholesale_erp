import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/utils/currency_formatter.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../controllers/khata_controller.dart';
import '../../models/party_model.dart';
import '../../config/khata_strings.dart';
import 'party_detail_side_dialog.dart';

class PartyTablePanel extends StatelessWidget {
  const PartyTablePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KhataController>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar & Filter Controls Header
          _buildControlsHeader(controller),

          const Divider(height: 1, color: AppColors.border),

          // 2. Full-Width Parties Table
          Expanded(
            child: Obx(() {
              final parties = controller.partyList;
              final isCustomer = controller.currentType.value == PartyType.customer;

              if (parties.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No ${isCustomer ? "customers" : "suppliers"} found matching your search.',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          controller.activeSearchQuery = '';
                          controller.activeFilter = FilterChipType.all;
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset filters'),
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      // Table Column Headers
                      _buildTableHeader(isCustomer),

                      const Divider(height: 1, color: AppColors.border),

                      // Scrollable List of Party Rows
                      Expanded(
                        child: ListView.separated(
                          itemCount: parties.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (context, index) {
                            final party = parties[index];
                            return _PartyTableRow(
                              party: party,
                              isCustomer: isCustomer,
                              onTap: () => showPartyDetailSideDialog(context, party),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Top Controls Bar: Search Field, Filter Chips, Sort Dropdown & Count
  Widget _buildControlsHeader(KhataController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(controller),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildFilterChips(controller)),
                    const SizedBox(width: 8),
                    _buildSortDropdown(controller),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              // Search Input Box
              SizedBox(
                width: 320,
                child: _buildSearchField(controller),
              ),
              const SizedBox(width: 14),

              // Filter Chips Row
              Expanded(child: _buildFilterChips(controller)),
              const SizedBox(width: 14),

              // Count Badge & Sort Dropdown
              _buildCountBadge(controller),
              const SizedBox(width: 10),
              _buildSortDropdown(controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField(KhataController controller) {
    return Obx(() {
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
    });
  }

  Widget _buildFilterChips(KhataController controller) {
    return Obx(() {
      final currentFilter = controller.activeFilter;
      final isCustomer = controller.currentType.value == PartyType.customer;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'All Parties',
              isSelected: currentFilter == FilterChipType.all,
              onTap: () => controller.activeFilter = FilterChipType.all,
            ),
            const SizedBox(width: 6),
            _buildFilterChip(
              label: isCustomer ? 'Baqaya (Lene hain)' : 'Baqaya (Dene hain)',
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
    });
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
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge(KhataController controller) {
    return Obx(() {
      final count = controller.partyList.length;
      final isCustomer = controller.currentType.value == PartyType.customer;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '${isCustomer ? "Customers" : "Suppliers"}: $count',
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
      );
    });
  }

  Widget _buildSortDropdown(KhataController controller) {
    return Obx(() {
      final currentSort = controller.activeSort;
      return Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: PopupMenuButton<SortType>(
          initialValue: currentSort,
          onSelected: (sort) => controller.activeSort = sort,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sort, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                currentSort == SortType.balanceDesc ? 'Sort: Balance ▾' : 'Sort: Name ▾',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: SortType.balanceDesc,
              child: Text('Sort by Highest Balance', style: TextStyle(fontSize: 12)),
            ),
            PopupMenuItem(
              value: SortType.nameAsc,
              child: Text('Sort by Name (A-Z)', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    });
  }

  /// Table Header Row
  Widget _buildTableHeader(bool isCustomer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      color: AppColors.background,
      child: const Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'PARTY / BUSINESS NAME',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'CONTACT & PHONE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'CITY & MARKET ADDRESS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'TOTAL BUSINESS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'KHATTA STATUS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'NET BAQAYA',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
              ),
            ),
          ),
          SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'ACTION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive Party Row with hover effect and clickable action
class _PartyTableRow extends StatefulWidget {
  final PartyModel party;
  final bool isCustomer;
  final VoidCallback onTap;

  const _PartyTableRow({
    required this.party,
    required this.isCustomer,
    required this.onTap,
  });

  @override
  State<_PartyTableRow> createState() => _PartyTableRowState();
}

class _PartyTableRowState extends State<_PartyTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final party = widget.party;
    final accentColor = widget.isCustomer ? AppColors.primary : AppColors.secondary;

    Color balanceColor;
    Color balanceBg;
    if (party.balance > 0) {
      balanceColor = AppColors.error;
      balanceBg = AppColors.errorLight.withValues(alpha: 0.3);
    } else if (party.balance < 0) {
      balanceColor = AppColors.success;
      balanceBg = AppColors.accentLight;
    } else {
      balanceColor = AppColors.textMuted;
      balanceBg = AppColors.background;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          color: _isHovered ? AppColors.primary.withValues(alpha: 0.04) : AppColors.surface,
          child: Row(
            children: [
              // 1. Party / Business Name (with initials avatar & seller type tag)
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: accentColor.withValues(alpha: 0.14),
                      child: Text(
                        party.initials,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  party.name,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  party.sellerType,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            party.contactPerson.isNotEmpty
                                ? '${party.contactPerson} • Code: ${party.id}'
                                : 'Code: ${party.id}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 2. Phone / WhatsApp
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        party.phone,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 3. City & Market Address
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.city,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (party.address.isNotEmpty)
                      Text(
                        party.address,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 4. Total Business Volume
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.format(party.totalBilled),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.isCustomer ? 'Total sales' : 'Total purchases',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 5. Khata Status Badge
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: balanceBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: balanceColor.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      party.statusCaption,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: balanceColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 6. Net Baqaya (Balance)
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    CurrencyFormatter.format(party.balance.abs()),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: balanceColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // 7. Action Button
              SizedBox(
                width: 120,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isHovered ? accentColor : AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _isHovered ? accentColor : AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Statement',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _isHovered ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: _isHovered ? Colors.white : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
