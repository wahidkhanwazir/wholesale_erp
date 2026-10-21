import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/utils/currency_formatter.dart';
import 'package:wholesale_app/core/widgets/custom_button.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../controllers/khata_controller.dart';
import '../../models/party_model.dart';
import '../../config/khata_strings.dart';
import 'ledger_table.dart';
import 'invoices_table.dart';
import 'payments_table.dart';
import 'payment_dialog.dart';
import 'quick_bill_dialog.dart';
import 'party_form_dialog.dart';
import 'statement_export_dialog.dart';

/// Shows the right-side dialogue modal sliding in from the right edge,
/// matching the desktop side-dialog pattern with a dimmed backdrop overlay.
void showPartyDetailSideDialog(BuildContext context, PartyModel party) {
  final controller = Get.find<KhataController>();
  controller.selectParty(party.id);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss Khata Details',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: PartyDetailSideDialog(
          partyId: party.id,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

class PartyDetailSideDialog extends StatefulWidget {
  final String partyId;
  final VoidCallback onClose;

  const PartyDetailSideDialog({
    super.key,
    required this.partyId,
    required this.onClose,
  });

  @override
  State<PartyDetailSideDialog> createState() => _PartyDetailSideDialogState();
}

class _PartyDetailSideDialogState extends State<PartyDetailSideDialog> {
  int _activeTabIndex = 0;
  DateTime _fromDate = DateTime(2026, 7, 21);
  DateTime _toDate = DateTime(2026, 10, 21);
  String _typeFilter = 'Sab entries';

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KhataController>();
    final mediaQuery = MediaQuery.of(context);
    final dialogWidth = (mediaQuery.size.width * 0.72).clamp(720.0, 1150.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: dialogWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 28,
              spreadRadius: 6,
              offset: const Offset(-6, 0),
            ),
          ],
        ),
        child: Obx(() {
          final parties = controller.partyList;
          PartyModel? party;
          try {
            party = parties.firstWhere((p) => p.id == widget.partyId);
          } catch (_) {
            party = controller.selectedParty;
          }

          if (party == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Party details not found.', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: widget.onClose, child: const Text('Close')),
                ],
              ),
            );
          }

          final isCustomer = party.type == PartyType.customer;
          final accentColor = isCustomer ? AppColors.primary : AppColors.secondary;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Header Area (Tags + Close 'X' + Title + Subtitle)
              _buildDialogHeader(context, controller, party, accentColor, isCustomer),

              const Divider(height: 1, color: AppColors.border),

              // 2. Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 4 Summary Metric Cards Strip (Like screenshot: 4 neat cards in a row)
                      _buildSummaryMetricCards(party, isCustomer),
                      const SizedBox(height: 20),

                      // Tab Navigation Bar
                      _buildTabBar(accentColor, isCustomer),
                      const SizedBox(height: 16),

                      // Active Tab Content
                      _buildActiveTabContent(context, party, accentColor, isCustomer),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // 3. Sticky Bottom Action Bar (Matching screenshot bottom bar)
              _buildBottomActionBar(context, controller, party, isCustomer),
            ],
          );
        }),
      ),
    );
  }

  /// Dialog Header with Badges row, Close 'X' button, Title and Subtitle metadata
  Widget _buildDialogHeader(
    BuildContext context,
    KhataController controller,
    PartyModel party,
    Color accentColor,
    bool isCustomer,
  ) {
    Color balanceBadgeColor;
    Color balanceBadgeBg;
    if (party.balance > 0) {
      balanceBadgeColor = AppColors.error;
      balanceBadgeBg = AppColors.errorLight.withValues(alpha: 0.35);
    } else if (party.balance < 0) {
      balanceBadgeColor = AppColors.success;
      balanceBadgeBg = AppColors.accentLight;
    } else {
      balanceBadgeColor = AppColors.textMuted;
      balanceBadgeBg = AppColors.background;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 18, 16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of top status badges and the close 'X' button
          Row(
            children: [
              // Badge 1: Party ID Code
              _buildPillTag(
                label: party.id,
                textColor: AppColors.textPrimary,
                bgColor: AppColors.background,
                borderColor: AppColors.border,
                icon: Icons.tag,
              ),
              const SizedBox(width: 8),

              // Badge 2: Party Type / Seller Category
              _buildPillTag(
                label: party.sellerType,
                textColor: accentColor,
                bgColor: accentColor.withValues(alpha: 0.1),
                borderColor: accentColor.withValues(alpha: 0.3),
                icon: isCustomer ? Icons.person_outline : Icons.factory_outlined,
              ),
              const SizedBox(width: 8),

              // Badge 3: Khata Active status
              _buildPillTag(
                label: 'Active Khata',
                textColor: AppColors.success,
                bgColor: AppColors.accentLight,
                borderColor: AppColors.success.withValues(alpha: 0.25),
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 8),

              // Badge 4: Balance status
              _buildPillTag(
                label: party.statusCaption,
                textColor: balanceBadgeColor,
                bgColor: balanceBadgeBg,
                borderColor: balanceBadgeColor.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 8),

              // Badge 5: City
              if (party.city.isNotEmpty)
                _buildPillTag(
                  label: party.city,
                  textColor: AppColors.textSecondary,
                  bgColor: AppColors.background,
                  borderColor: AppColors.border,
                  icon: Icons.location_on_outlined,
                ),

              const Spacer(),

              // Quick Edit Button
              IconButton(
                tooltip: 'Edit Party Details',
                icon: const Icon(Icons.edit_outlined, size: 19, color: AppColors.textSecondary),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => PartyFormDialog(
                      type: party.type,
                      existingParty: party,
                    ),
                  );
                },
              ),

              // Close 'X' Button on top right
              IconButton(
                tooltip: 'Close Dialogue (Esc)',
                splashRadius: 20,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textPrimary),
                ),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Big prominent Title (Party Name)
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accentColor.withValues(alpha: 0.15),
                child: Text(
                  party.initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Subtitle Metadata Line
                    Text(
                      '${party.contactPerson.isNotEmpty ? '${party.contactPerson} • ' : ''}'
                      '${party.phone} • ${party.city}'
                      '${party.address.isNotEmpty ? ' • ${party.address}' : ''}'
                      '${party.creditLimit != null && party.creditLimit! > 0 ? ' • Credit Limit: Rs. ${party.creditLimit!.toStringAsFixed(0)}' : ''}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper to build sleek pill badges matching the screenshot
  Widget _buildPillTag({
    required String label,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 4 KPI Summary Metric Cards in a horizontal row
  Widget _buildSummaryMetricCards(PartyModel party, bool isCustomer) {
    Color balanceColor;
    Color balanceBg;
    if (party.balance > 0) {
      balanceColor = AppColors.error;
      balanceBg = AppColors.errorLight.withValues(alpha: 0.25);
    } else if (party.balance < 0) {
      balanceColor = AppColors.success;
      balanceBg = AppColors.accentLight;
    } else {
      balanceColor = AppColors.textMuted;
      balanceBg = AppColors.background;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;

        final cards = [
          _buildMetricCard(
            title: isCustomer ? 'NET KHATTA BAQAYA' : 'TOTAL PAYABLE (DENE HAIN)',
            value: CurrencyFormatter.format(party.balance.abs()),
            subtitle: party.balance > 0
                ? (isCustomer ? 'Baqaya wasool karna hai' : 'Baqaya ada karna hai')
                : (party.balance < 0 ? 'Advance jama hai' : 'Khata mukammal clear hai'),
            valueColor: balanceColor,
            bgColor: balanceBg,
            borderColor: balanceColor.withValues(alpha: 0.3),
            isHighlighted: true,
          ),
          _buildMetricCard(
            title: isCustomer ? 'TOTAL SALES TURNOVER' : 'TOTAL PURCHASES FROM MILL',
            value: CurrencyFormatter.format(party.totalBilled),
            subtitle: isCustomer ? 'Mukammal sale bills' : 'Mukammal purchase bills',
            valueColor: AppColors.textPrimary,
          ),
          _buildMetricCard(
            title: isCustomer ? 'WASOOLI (PAYMENTS RECEIVED)' : 'ADA-YEGI (PAYMENTS MADE)',
            value: CurrencyFormatter.format(party.totalPaidOrReceived),
            subtitle: isCustomer ? 'Bank & Cash collections' : 'Disbursed to mill',
            valueColor: AppColors.success,
          ),
          _buildMetricCard(
            title: 'CREDIT LIMIT & STATUS',
            value: party.creditLimit != null && party.creditLimit! > 0
                ? CurrencyFormatter.format(party.creditLimit!)
                : 'Standard',
            subtitle: party.creditLimit != null && party.creditLimit! > 0
                ? (party.balance > party.creditLimit! ? 'Limit exceeded!' : 'Within safe credit limit')
                : 'No limit restriction',
            valueColor: AppColors.textPrimary,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: cards[i]),
              ],
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
    Color? bgColor,
    Color? borderColor,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
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
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Navigation Tab Bar inside the side dialog
  Widget _buildTabBar(Color accentColor, bool isCustomer) {
    final tabs = [
      'Ledger Statement',
      isCustomer ? 'Invoices (Sales)' : 'Bills (Purchases)',
      'Payments History',
      'Profile & Info',
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            InkWell(
              onTap: () => setState(() => _activeTabIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _activeTabIndex == i ? accentColor : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _activeTabIndex == i ? FontWeight.w700 : FontWeight.w500,
                    color: _activeTabIndex == i ? accentColor : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Active Tab Content
  Widget _buildActiveTabContent(
    BuildContext context,
    PartyModel party,
    Color accentColor,
    bool isCustomer,
  ) {
    if (_activeTabIndex == 0) {
      // Tab 0: Running Ledger
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Controls Row (From Date, To Date, Entry Type)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // From Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fromDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _fromDate = picked);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy').format(_fromDate),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Text('to', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),

                  // To Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _toDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _toDate = picked);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy').format(_toDate),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Entry Type Dropdown
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _typeFilter,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        onChanged: (val) {
                          if (val != null) setState(() => _typeFilter = val);
                        },
                        items: const [
                          DropdownMenuItem(value: 'Sab entries', child: Text('All Entries')),
                          DropdownMenuItem(value: 'Sales / Purchases', child: Text('Bills Only')),
                          DropdownMenuItem(value: 'Payments', child: Text('Payments Only')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Export / Print options
              PopupMenuButton<String>(
                tooltip: 'Statement Options',
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print_outlined, size: 16, color: AppColors.textPrimary),
                      SizedBox(width: 6),
                      Text('Print / Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textPrimary),
                    ],
                  ),
                ),
                onSelected: (val) {
                  if (val == 'export') {
                    showDialog(
                      context: context,
                      builder: (ctx) => StatementExportDialog(party: party),
                    );
                  } else if (val == 'copy') {
                    _copyStatement(party);
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Export PDF / Excel', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy_outlined, size: 16, color: AppColors.textPrimary),
                        SizedBox(width: 8),
                        Text('Copy Statement Text', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ledger Table
          LedgerTable(
            party: party,
            fromDate: _fromDate,
            toDate: _toDate,
            typeFilter: _typeFilter,
          ),
        ],
      );
    } else if (_activeTabIndex == 1) {
      // Tab 1: Invoices / Bills
      return InvoicesTable(
        party: party,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } else if (_activeTabIndex == 2) {
      // Tab 2: Payments
      return PaymentsTable(
        party: party,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } else {
      // Tab 3: Profile & Info
      return _buildProfileInfoTab(party, isCustomer);
    }
  }

  /// Tab 3: Detailed Party Profile & Khata Settings
  Widget _buildProfileInfoTab(PartyModel party, bool isCustomer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Khata Account Information',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Account Code', party.id),
          _buildInfoRow('Trading / Shop Name', party.name),
          _buildInfoRow('Category', party.sellerType),
          if (party.contactPerson.isNotEmpty)
            _buildInfoRow('Contact Person', party.contactPerson),
          _buildInfoRow('Phone / WhatsApp', party.phone),
          _buildInfoRow('City', party.city),
          if (party.address.isNotEmpty)
            _buildInfoRow('Market / Factory Address', party.address),
          _buildInfoRow(
            'Initial Opening Balance',
            '${CurrencyFormatter.format(party.openingBalance)} (${party.openingBalanceType})',
          ),
          if (party.creditLimit != null && party.creditLimit! > 0)
            _buildInfoRow('Credit Limit', CurrencyFormatter.format(party.creditLimit!)),
          _buildInfoRow('Account Status', party.isActive ? 'Active' : 'Deactivated'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  /// Sticky Bottom Action Bar matching the screenshot
  Widget _buildBottomActionBar(
    BuildContext context,
    KhataController controller,
    PartyModel party,
    bool isCustomer,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Code & Status
          Row(
            children: [
              Text(
                'Party ID: ${party.id}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                isCustomer ? 'Customer Khata' : 'Supplier Ledger',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),

          // Right: Action Buttons
          Row(
            children: [
              // Close button
              OutlinedButton(
                onPressed: widget.onClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Close', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),

              // + Sale / + Purchase Quick Bill button
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => QuickBillDialog(party: party),
                  );
                },
                icon: Icon(isCustomer ? Icons.receipt_long : Icons.shopping_bag_outlined, size: 16),
                label: Text(isCustomer ? '+ Quick Sale' : '+ Purchase Bill', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 10),

              // Receive Payment / Pay Supplier (Primary Action Button)
              CustomButton(
                text: isCustomer ? KhataStrings.receivePayment : KhataStrings.paySupplier,
                icon: Icons.payments_outlined,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => PaymentDialog(
                      type: party.type,
                      initialParty: party,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyStatement(PartyModel party) {
    final buffer = StringBuffer();
    buffer.writeln('=== KHATA STATEMENT ===');
    buffer.writeln('Name: ${party.name}');
    buffer.writeln('Phone: ${party.phone}');
    buffer.writeln('City: ${party.city}');
    buffer.writeln('Current Balance: Rs. ${party.balance.toStringAsFixed(0)}');
    buffer.writeln('=======================');
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    Get.snackbar(
      'Copied',
      'Statement summary copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
    );
  }
}
