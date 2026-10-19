import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../customers/controllers/customers_controller.dart';
import '../suppliers/controllers/suppliers_controller.dart';
import '../models/party_model.dart';
import '../config/khata_config.dart';

enum FilterChipType { all, baqaya, overdueOrDueSoon, advance }
enum SortType { balanceDesc, nameAsc }

class KhataController extends GetxController {
  final currentType = PartyType.customer.obs;
  final isDetailView = false.obs; // Controls List Screen vs Detail Screen navigation on mobile

  // State per type
  final customerSearch = ''.obs;
  final supplierSearch = ''.obs;

  final customerFilter = FilterChipType.all.obs;
  final supplierFilter = FilterChipType.all.obs;

  final customerSort = SortType.balanceDesc.obs;
  final supplierSort = SortType.balanceDesc.obs;

  final selectedCustomerId = Rxn<String>();
  final selectedSupplierId = Rxn<String>();

  final searchFocusNode = FocusNode();

  CustomersController get customersCtrl => Get.find<CustomersController>();
  SuppliersController get suppliersCtrl => Get.find<SuppliersController>();

  KhataConfig get config => KhataConfig.forType(currentType.value);

  @override
  void onInit() {
    super.onInit();

    // Check deep-linking arguments
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map;
      if (args.containsKey('type') && args['type'] is PartyType) {
        currentType.value = args['type'] as PartyType;
      }
      if (args.containsKey('partyId') && args['partyId'] is String) {
        final partyId = args['partyId'] as String;
        if (currentType.value == PartyType.customer) {
          selectedCustomerId.value = partyId;
        } else {
          selectedSupplierId.value = partyId;
        }
        isDetailView.value = true;
      }
    }

    // Initialize initial selections if empty
    if (selectedCustomerId.value == null && customersCtrl.customers.isNotEmpty) {
      selectedCustomerId.value = customersCtrl.customers.first.id;
    }
    if (selectedSupplierId.value == null && suppliersCtrl.suppliers.isNotEmpty) {
      selectedSupplierId.value = suppliersCtrl.suppliers.first.id;
    }
  }

  @override
  void onClose() {
    searchFocusNode.dispose();
    super.onClose();
  }

  void switchType(PartyType newType) {
    currentType.value = newType;
    isDetailView.value = false;

    // Auto-select the first party after switching mode
    if (newType == PartyType.customer && customersCtrl.customers.isNotEmpty) {
      final first = customersCtrl.customers.first;
      selectedCustomerId.value = first.id;
      customersCtrl.selectCustomer(first);
    } else if (newType == PartyType.supplier && suppliersCtrl.suppliers.isNotEmpty) {
      final first = suppliersCtrl.suppliers.first;
      selectedSupplierId.value = first.id;
      suppliersCtrl.selectSupplier(first);
    }
  }

  void goBackToList() {
    isDetailView.value = false;
  }

  // Active Search Query
  String get activeSearchQuery =>
      currentType.value == PartyType.customer ? customerSearch.value : supplierSearch.value;

  set activeSearchQuery(String val) {
    if (currentType.value == PartyType.customer) {
      customerSearch.value = val;
    } else {
      supplierSearch.value = val;
    }
  }

  // Active Filter
  FilterChipType get activeFilter =>
      currentType.value == PartyType.customer ? customerFilter.value : supplierFilter.value;

  set activeFilter(FilterChipType filter) {
    if (currentType.value == PartyType.customer) {
      customerFilter.value = filter;
    } else {
      supplierFilter.value = filter;
    }
  }

  // Active Sort
  SortType get activeSort =>
      currentType.value == PartyType.customer ? customerSort.value : supplierSort.value;

  set activeSort(SortType sort) {
    if (currentType.value == PartyType.customer) {
      customerSort.value = sort;
    } else {
      supplierSort.value = sort;
    }
  }

  // Active Parties List
  List<PartyModel> get partyList {
    if (currentType.value == PartyType.customer) {
      final query = customerSearch.value.trim().toLowerCase();
      final filter = customerFilter.value;
      final sort = customerSort.value;

      var list = customersCtrl.customers
          .where((c) => c.isActive) // Filter out deactivated parties in UI
          .map((c) => PartyModel.fromCustomer(c))
          .where((p) {
        final matchesSearch = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.phone.toLowerCase().contains(query) ||
            p.city.toLowerCase().contains(query);

        if (!matchesSearch) return false;

        switch (filter) {
          case FilterChipType.baqaya:
            return p.balance > 0;
          case FilterChipType.overdueOrDueSoon:
            return p.isOverdueOrDueSoon;
          case FilterChipType.advance:
            return p.balance < 0;
          case FilterChipType.all:
            return true;
        }
      }).toList();

      if (sort == SortType.balanceDesc) {
        list.sort((a, b) => b.balance.compareTo(a.balance));
      } else {
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }

      return list;
    } else {
      final query = supplierSearch.value.trim().toLowerCase();
      final filter = supplierFilter.value;
      final sort = supplierSort.value;

      var list = suppliersCtrl.suppliers
          .where((s) => s.isActive) // Filter out deactivated parties in UI
          .map((s) => PartyModel.fromSupplier(s))
          .where((p) {
        final matchesSearch = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.phone.toLowerCase().contains(query) ||
            p.city.toLowerCase().contains(query);

        if (!matchesSearch) return false;

        switch (filter) {
          case FilterChipType.baqaya:
            return p.balance > 0;
          case FilterChipType.overdueOrDueSoon:
            return p.isOverdueOrDueSoon;
          case FilterChipType.advance:
            return p.balance < 0;
          case FilterChipType.all:
            return true;
        }
      }).toList();

      if (sort == SortType.balanceDesc) {
        list.sort((a, b) => b.balance.compareTo(a.balance));
      } else {
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }

      return list;
    }
  }

  // Selected Party
  PartyModel? get selectedParty {
    final list = partyList;
    final selectedId = currentType.value == PartyType.customer
        ? selectedCustomerId.value
        : selectedSupplierId.value;

    if (selectedId != null) {
      try {
        return list.firstWhere((p) => p.id == selectedId);
      } catch (_) {
        if (list.isNotEmpty) return list.first;
      }
    } else if (list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  void selectParty(String partyId) {
    if (currentType.value == PartyType.customer) {
      selectedCustomerId.value = partyId;
      final c = customersCtrl.getCustomerById(partyId);
      if (c != null) customersCtrl.selectCustomer(c);
    } else {
      selectedSupplierId.value = partyId;
      final s = suppliersCtrl.getSupplierById(partyId);
      if (s != null) suppliersCtrl.selectSupplier(s);
    }
    isDetailView.value = true; // Open detail screen on tap in mobile
  }

  // KPI Metrics Calculation
  double get kpiTotalReceivableOrPayable {
    if (currentType.value == PartyType.customer) {
      return customersCtrl.totalReceivables;
    } else {
      return suppliersCtrl.totalPayables;
    }
  }

  double get kpiOverdueOrDueThisWeek {
    if (currentType.value == PartyType.customer) {
      return customersCtrl.customers
          .where((c) => c.isActive)
          .fold(0.0, (sum, c) => sum + c.overdueAmount);
    } else {
      return suppliersCtrl.suppliers
          .where((s) => s.isActive && s.isDueSoon)
          .fold(0.0, (sum, s) => sum + s.derivedPayable);
    }
  }

  String get kpiPartiesWithBalanceCount {
    if (currentType.value == PartyType.customer) {
      final active = customersCtrl.customers.where((c) => c.isActive).toList();
      final withBal = active.where((c) => c.derivedBalance > 0).length;
      return '$withBal of ${active.length}';
    } else {
      final active = suppliersCtrl.suppliers.where((s) => s.isActive).toList();
      final withBal = active.where((s) => s.derivedPayable > 0).length;
      return '$withBal of ${active.length}';
    }
  }

  double get kpiTodayCollectionOrPaidThisMonth {
    final now = DateTime.now();
    if (currentType.value == PartyType.customer) {
      // Sum today's received payments
      return customersCtrl.payments
          .where((p) => !p.isReversed && p.date.year == now.year && p.date.month == now.month && p.date.day == now.day)
          .fold(0.0, (sum, p) => sum + p.amount);
    } else {
      // Sum this month's disbursements
      return suppliersCtrl.payments
          .where((p) => !p.isReversed && p.date.year == now.year && p.date.month == now.month)
          .fold(0.0, (sum, p) => sum + p.amount);
    }
  }
}
