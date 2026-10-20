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
import 'payment_dialog.dart';
import 'party_form_dialog.dart';
import 'statement_export_dialog.dart';
import 'quick_bill_dialog.dart';
import 'invoices_table.dart';
import 'payments_table.dart';

class PartyDetailPanel extends StatefulWidget {
  const PartyDetailPanel({super.key});

  @override
  State<PartyDetailPanel> createState() => _PartyDetailPanelState();
}

class _PartyDetailPanelState extends State<PartyDetailPanel> {
  int _activeTabIndex = 0;
  DateTime _fromDate = DateTime(2026, 7, 21);
  DateTime _toDate = DateTime(2026, 10, 19);
  String _typeFilter = 'Sab entries';

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KhataController>();

    return RepaintBoundary(
      child: Obx(() {
        final party = controller.selectedParty;

        if (party == null) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Select a customer or supplier to view their running Khata statement.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          );
        }

        final isCustomer = party.type == PartyType.customer;
        final accentColor = isCustomer ? AppColors.primary : AppColors.secondary;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Party Header Card
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accentColor.withValues(alpha: 0.15),
                    child: Text(
                      party.initials,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name & Metadata (Wraps naturally so full name is displayed without truncation!)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          party.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${party.phone} • ${party.city}${party.address.isNotEmpty ? ' • ${party.address}' : ''}${party.creditLimit != null && party.creditLimit! > 0 ? ' • Credit limit Rs. ${party.creditLimit!.toStringAsFixed(0)}' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Action Buttons Top Right (Sleek compact sizing)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Primary Action: Receive Payment / Pay Supplier
                        CustomButton(
                          text: isCustomer ? KhataStrings.receivePayment : KhataStrings.paySupplier,
                          icon: Icons.payments_outlined,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        const SizedBox(width: 6),

                        // Secondary Action: + Sale / + Purchase
                        CustomButton(
                          text: isCustomer ? '+ Sale' : '+ Purchase',
                          isSecondary: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => QuickBillDialog(party: party),
                            );
                          },
                        ),
                        const SizedBox(width: 6),

                        // Statement Dropdown Menu (Print/PDF, Copy text, WhatsApp)
                        PopupMenuButton<String>(
                          tooltip: 'Statement Options',
                          offset: const Offset(0, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Statement',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textPrimary),
                              ],
                            ),
                          ),
                          onSelected: (val) {
                            if (val == 'print') {
                              _showPrintPdfDialog(context, party);
                            } else if (val == 'copy') {
                              _copyStatementText(party);
                            } else if (val == 'whatsapp') {
                              _showWhatsAppReminderDialog(context, party);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'print',
                              child: Text('Print / PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                            ),
                            const PopupMenuItem(
                              value: 'copy',
                              child: Text('Copy statement text', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                            ),
                            const PopupMenuItem(
                              value: 'whatsapp',
                              child: Text('WhatsApp reminder', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),

                        // Context Menu ⋮
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                          onSelected: (val) {
                            if (val == 'edit') {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => PartyFormDialog(
                                  type: party.type,
                                  existingParty: party,
                                ),
                              );
                            } else if (val == 'deactivate') {
                              _confirmDeactivate(context, controller, party);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16, color: AppColors.textPrimary),
                                  SizedBox(width: 8),
                                  Text('Edit Details', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'deactivate',
                              child: Row(
                                children: [
                                  Icon(Icons.person_off_outlined, size: 16, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Deactivate Account', style: TextStyle(fontSize: 12, color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 4 Summary Metric Cards (Responsive 4 columns vs 2x2 grid)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 650;

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildSummaryTile(
                            title: KhataStrings.pichlaBaqaya,
                            value: CurrencyFormatter.format(party.openingBalance),
                            valueColor: AppColors.textPrimary,
                            isHighlighted: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryTile(
                            title: isCustomer ? KhataStrings.totalBillSale : KhataStrings.totalBillPurchase,
                            value: CurrencyFormatter.format(party.totalBilled),
                            valueColor: AppColors.textPrimary,
                            isHighlighted: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryTile(
                            title: isCustomer ? 'Wasooli (Received)' : 'Ada-yegi (Paid)',
                            value: CurrencyFormatter.format(party.totalPaidOrReceived),
                            valueColor: AppColors.success,
                            isHighlighted: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryTile(
                            title: isCustomer ? 'Baqaya (Lene hain)' : 'Baqaya (Dene hain)',
                            value: CurrencyFormatter.format(party.balance.abs()),
                            valueColor: party.balance > 0 ? (isCustomer ? AppColors.success : AppColors.error) : AppColors.success,
                            isHighlighted: true,
                            highlightBg: isCustomer ? AppColors.accentLight : AppColors.errorLight.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryTile(
                                title: KhataStrings.pichlaBaqaya,
                                value: CurrencyFormatter.format(party.openingBalance),
                                valueColor: AppColors.textPrimary,
                                isHighlighted: false,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSummaryTile(
                                title: isCustomer ? KhataStrings.totalBillSale : KhataStrings.totalBillPurchase,
                                value: CurrencyFormatter.format(party.totalBilled),
                                valueColor: AppColors.textPrimary,
                                isHighlighted: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryTile(
                                title: isCustomer ? 'Wasooli (Received)' : 'Ada-yegi (Paid)',
                                value: CurrencyFormatter.format(party.totalPaidOrReceived),
                                valueColor: AppColors.success,
                                isHighlighted: false,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSummaryTile(
                                title: isCustomer ? 'Baqaya (Lene hain)' : 'Baqaya (Dene hain)',
                                value: CurrencyFormatter.format(party.balance.abs()),
                                valueColor: party.balance > 0 ? (isCustomer ? AppColors.success : AppColors.error) : AppColors.success,
                                isHighlighted: true,
                                highlightBg: isCustomer ? AppColors.accentLight : AppColors.errorLight.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 18),

              // Tab Bar Headers
              DefaultTabController(
                length: 4,
                child: TabBar(
                  onTap: (index) => setState(() => _activeTabIndex = index),
                  labelColor: accentColor,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: accentColor,
                  indicatorWeight: 3,
                  isScrollable: true,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  tabs: [
                    const Tab(text: 'Ledger'),
                    Tab(text: isCustomer ? 'Invoices' : 'Bills'),
                    const Tab(text: 'Payments'),
                    const Tab(text: 'Info'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Active Tab Content
              _buildActiveTabContent(party),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActiveTabContent(PartyModel party) {
    if (_activeTabIndex == 0) {
      // Tab 1: Ledger Table with From Date & To Date controls matching Screenshot 1
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // From Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fromDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                onSurface: AppColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => _fromDate = picked);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('MM/dd/yyyy').format(_fromDate),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // To Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _toDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                onSurface: AppColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => _toDate = picked);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('MM/dd/yyyy').format(_toDate),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Entries Filter Dropdown
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _typeFilter,
                        isDense: true,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        items: ['Sab entries', 'Sales / Purchases', 'Payments', 'Opening'].map((f) {
                          return DropdownMenuItem(value: f, child: Text(f));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _typeFilter = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Active Print / PDF Button
              SizedBox(
                height: 38,
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => StatementExportDialog(party: party),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Print / PDF',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          LedgerTable(
            party: party,
            fromDate: _fromDate,
            toDate: _toDate,
            typeFilter: _typeFilter,
          ),
        ],
      );
    } else if (_activeTabIndex == 1) {
      // Tab 2: Invoices / Bills Table matching Screenshot 1
      return InvoicesTable(
        party: party,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } else if (_activeTabIndex == 2) {
      // Tab 3: Dedicated Payments Table matching Screenshot 1
      return PaymentsTable(
        party: party,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } else {
      // Tab 4: Dedicated Info Card Grid matching Screenshot 1
      return _buildInfoTab(party);
    }
  }

  Widget _buildInfoTab(PartyModel party) {
    final creditLimit = party.creditLimit ?? 0.0;
    final balance = party.balance.clamp(0.0, double.infinity);
    final utilizedRatio = creditLimit > 0 ? (balance / creditLimit).clamp(0.0, 1.0) : 0.0;
    final percentUtilized = creditLimit > 0 ? (utilizedRatio * 100).toInt() : 0;

    // Dynamic Aging calculation (FIFO)
    final now = DateTime.now();
    double age0to30 = 0.0;
    double age31to60 = 0.0;
    double age60Plus = 0.0;

    for (final tx in party.ledger) {
      if (tx.isReversed) continue;
      final isCustomer = party.type == PartyType.customer;
      final debitOrCredit = isCustomer ? tx.debit : tx.credit;

      if (debitOrCredit > 0) {
        final daysOld = now.difference(tx.date).inDays;
        if (daysOld <= 30) {
          age0to30 += debitOrCredit;
        } else if (daysOld <= 60) {
          age31to60 += debitOrCredit;
        } else {
          age60Plus += debitOrCredit;
        }
      }
    }

    // Deduct total payments received/paid
    final totalPaid = party.totalPaidOrReceived;
    if (totalPaid > 0) {
      double remPayment = totalPaid;
      if (age60Plus > 0) {
        final deduct = remPayment.clamp(0.0, age60Plus);
        age60Plus -= deduct;
        remPayment -= deduct;
      }
      if (remPayment > 0 && age31to60 > 0) {
        final deduct = remPayment.clamp(0.0, age31to60);
        age31to60 -= deduct;
        remPayment -= deduct;
      }
      if (remPayment > 0 && age0to30 > 0) {
        final deduct = remPayment.clamp(0.0, age0to30);
        age0to30 -= deduct;
        remPayment -= deduct;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: Phone & City/Address
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                label: 'Phone',
                value: party.phone,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildInfoCard(
                label: 'City / Address',
                value: '${party.city}${party.address.isNotEmpty ? ' ${party.address}' : ''}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 2: Credit Limit & Payment Terms
        Row(
          children: [
            // Card 3: Credit Limit
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Credit limit',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      creditLimit > 0
                          ? CurrencyFormatter.format(creditLimit)
                          : 'No limit set',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (creditLimit > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: utilizedRatio,
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            utilizedRatio > 0.85 ? AppColors.error : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$percentUtilized% use ho chuka',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Baqaya: ${CurrencyFormatter.format(party.balance.abs())}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Card 4: Payment Terms
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Payment terms',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${party.creditDays ?? 30} din',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 3: Aging (baqaya) Full Width Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Aging (baqaya)',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    const TextSpan(text: '0-30 din: '),
                    TextSpan(
                      text: CurrencyFormatter.format(age0to30),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    const TextSpan(text: '  |  31-60: '),
                    TextSpan(
                      text: CurrencyFormatter.format(age31to60),
                      style: TextStyle(color: age31to60 > 0 ? AppColors.warning : AppColors.textPrimary),
                    ),
                    const TextSpan(text: '  |  60+: '),
                    TextSpan(
                      text: CurrencyFormatter.format(age60Plus),
                      style: TextStyle(color: age60Plus > 0 ? AppColors.error : AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required String title,
    required String value,
    required Color valueColor,
    bool isHighlighted = false,
    Color? highlightBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted ? (highlightBg ?? AppColors.accentLight) : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isHighlighted ? valueColor.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            maxLines: 2, // Allows label to wrap without being truncated!
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
  }

  void _showPrintPdfDialog(BuildContext context, PartyModel party) {
    showDialog(
      context: context,
      builder: (ctx) => StatementExportDialog(party: party),
    );
  }

  void _copyStatementText(PartyModel party) {
    final isCustomer = party.type == PartyType.customer;
    final buffer = StringBuffer();

    buffer.writeln('========================================');
    buffer.writeln('KHATA STATEMENT - ${party.name.toUpperCase()}');
    buffer.writeln('========================================');
    buffer.writeln('Phone: ${party.phone}');
    if (party.city.isNotEmpty) buffer.writeln('City: ${party.city}');
    if (party.address.isNotEmpty) buffer.writeln('Address: ${party.address}');
    buffer.writeln('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('SUMMARY:');
    buffer.writeln('• Total Billed: Rs. ${party.totalBilled.toStringAsFixed(0)}');
    buffer.writeln('• Total Paid / Received: Rs. ${party.totalPaidOrReceived.toStringAsFixed(0)}');
    final balType = party.balance > 0 ? (isCustomer ? 'Lene hain' : 'Dene hain') : 'Cleared';
    buffer.writeln('• Closing Balance (Baqaya): Rs. ${party.balance.abs().toStringAsFixed(0)} ($balType)');
    buffer.writeln('----------------------------------------');
    buffer.writeln('STATEMENT TRANSACTIONS:');

    if (party.ledger.isEmpty) {
      buffer.writeln('No transaction records found.');
    } else {
      for (final tx in party.ledger) {
        final dateStr = DateFormat('dd/MM/yy').format(tx.date);
        final drStr = tx.debit > 0 ? 'Dr: Rs.${tx.debit.toStringAsFixed(0)}' : '';
        final crStr = tx.credit > 0 ? 'Cr: Rs.${tx.credit.toStringAsFixed(0)}' : '';
        final amountStr = [drStr, crStr].where((s) => s.isNotEmpty).join(' | ');
        buffer.writeln('$dateStr - ${tx.referenceType} | $amountStr | Bal: Rs.${tx.runningBalance.toStringAsFixed(0)}');
      }
    }

    buffer.writeln('----------------------------------------');
    buffer.writeln('Generated via Wholesale ERP');
    buffer.writeln('========================================');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    Get.snackbar(
      'Statement Copied',
      'Khata statement text for ${party.name} copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _showWhatsAppReminderDialog(BuildContext context, PartyModel party) {
    final isCustomer = party.type == PartyType.customer;
    final balType = isCustomer ? 'Lene hain (Receivable)' : 'Dene hain (Payable)';

    final defaultMsg = '''Assalam-o-Alaikum ${party.name},

Aap ke Khata ka summary statement:
------------------------------------
• Total Bill: Rs. ${party.totalBilled.toStringAsFixed(0)}
• Total Paid / Received: Rs. ${party.totalPaidOrReceived.toStringAsFixed(0)}
• Baqaya Amount ($balType): Rs. ${party.balance.abs().toStringAsFixed(0)}
------------------------------------
Baraye meherbani baqaya wajeeb-ul-ada meqdaar ki settlement kar dein.

Shukriya,
Wholesale ERP''';

    final msgController = TextEditingController(text: defaultMsg);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: AppColors.success, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'WhatsApp Reminder – ${party.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Reminder Message (Editable):',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: msgController,
                maxLines: 7,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: msgController.text));
                      Get.back();
                      Get.snackbar(
                        'Message Copied',
                        'WhatsApp message text copied to clipboard.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primary,
                        colorText: Colors.white,
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16, color: AppColors.textPrimary),
                    label: const Text('Copy Text', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    text: 'Send on WhatsApp',
                    icon: Icons.send_rounded,
                    onPressed: () {
                      final text = msgController.text;
                      Clipboard.setData(ClipboardData(text: text));
                      Get.back();

                      Get.snackbar(
                        'WhatsApp Ready',
                        'Reminder copied to clipboard for ${party.name}.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primary,
                        colorText: Colors.white,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, KhataController controller, PartyModel party) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Account?'),
        content: Text('Are you sure you want to deactivate ${party.name}? Account will remain in database for historical records.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              if (party.type == PartyType.customer) {
                controller.customersCtrl.deactivateCustomer(party.id);
              } else {
                controller.suppliersCtrl.deactivateSupplier(party.id);
              }
              Get.snackbar('Account Deactivated', '${party.name} is now inactive.');
            },
            child: const Text('Deactivate', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
