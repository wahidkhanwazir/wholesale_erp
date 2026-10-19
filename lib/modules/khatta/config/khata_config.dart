import 'package:flutter/material.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import 'khata_strings.dart';

class KhataConfig {
  final PartyType type;
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color accentBadgeColor;
  final String searchHint;
  final String primaryBtnText;
  final String addPartyBtnText;
  final String billHeaderLabel;
  final String paymentHeaderLabel;
  final String positiveBalanceLabel; // Lene hain or Dene hain

  KhataConfig._({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.accentBadgeColor,
    required this.searchHint,
    required this.primaryBtnText,
    required this.addPartyBtnText,
    required this.billHeaderLabel,
    required this.paymentHeaderLabel,
    required this.positiveBalanceLabel,
  });

  factory KhataConfig.forType(PartyType type) {
    if (type == PartyType.customer) {
      return KhataConfig._(
        type: PartyType.customer,
        title: 'Customers',
        subtitle: KhataStrings.customersSubtitle,
        primaryColor: AppColors.primary,
        accentBadgeColor: AppColors.primary,
        searchHint: KhataStrings.searchCustomers,
        primaryBtnText: KhataStrings.receivePayment,
        addPartyBtnText: KhataStrings.addCustomer,
        billHeaderLabel: KhataStrings.billDr,
        paymentHeaderLabel: KhataStrings.wasooliCr,
        positiveBalanceLabel: KhataStrings.leneHain,
      );
    } else {
      return KhataConfig._(
        type: PartyType.supplier,
        title: 'Suppliers',
        subtitle: KhataStrings.suppliersSubtitle,
        primaryColor: AppColors.primary,
        accentBadgeColor: AppColors.secondary,
        searchHint: KhataStrings.searchSuppliers,
        primaryBtnText: KhataStrings.paySupplier,
        addPartyBtnText: KhataStrings.addSupplier,
        billHeaderLabel: KhataStrings.billCr,
        paymentHeaderLabel: KhataStrings.adayegiDr,
        positiveBalanceLabel: KhataStrings.deneHain,
      );
    }
  }
}
