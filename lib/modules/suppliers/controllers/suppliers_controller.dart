import 'package:get/get.dart';
import '../../../data/mock_data/mock_seed_data.dart';
import '../models/supplier_model.dart';
import '../models/ledger_model.dart';
import '../../../shared/models/enums.dart';
import '../../purchases/models/purchase_model.dart';

class SuppliersController extends GetxController {
  final suppliers = <SupplierModel>[].obs;
  final searchQuery = ''.obs;
  final selectedSupplier = Rxn<SupplierModel>();

  @override
  void onInit() {
    super.onInit();
    loadInitialSuppliers();
  }

  void loadInitialSuppliers() {
    final list = MockSeedData.getSuppliers();
    suppliers.assignAll(list);
    if (list.isNotEmpty) {
      selectedSupplier.value = list.first;
    }
  }

  List<SupplierModel> get filteredSuppliers {
    if (searchQuery.value.isEmpty) {
      return suppliers;
    }
    final q = searchQuery.value.toLowerCase();
    return suppliers.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.phone.toLowerCase().contains(q) ||
          s.city.toLowerCase().contains(q);
    }).toList();
  }

  double get totalPayables =>
      suppliers.fold(0.0, (sum, s) => sum + s.outstandingPayable);

  SupplierModel? getSupplierById(String id) {
    try {
      return suppliers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  void selectSupplier(SupplierModel supplier) {
    selectedSupplier.value = supplier;
  }

  void addSupplier(SupplierModel supplier) {
    suppliers.insert(0, supplier);
    selectedSupplier.value = supplier;
    if (Get.context != null) {
      Get.snackbar(
        'Supplier Added',
        '${supplier.name} added to suppliers list.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void addPurchaseToSupplier(PurchaseModel purchase) {
    final index = suppliers.indexWhere((s) => s.id == purchase.supplierId);
    if (index == -1) return;

    final supplier = suppliers[index];
    final oldPayable = supplier.outstandingPayable;

    final updatedLedger = List<LedgerTransaction>.from(supplier.ledger);

    // 1. Credit the bill grand total (increases payable)
    final payableAfterBill = oldPayable + purchase.grandTotal;
    updatedLedger.add(
      LedgerTransaction(
        id: 'LED-S-${DateTime.now().millisecondsSinceEpoch}-1',
        partyId: supplier.id,
        partyType: PartyType.supplier,
        date: purchase.date,
        referenceType: 'Purchase Bill ${purchase.purchaseNumber}',
        description: 'Bill Total (${purchase.items.length} items)',
        debit: 0.0,
        credit: purchase.grandTotal,
        runningBalance: payableAfterBill,
      ),
    );

    // 2. If paid at time of purchase, debit the paid amount (decreases payable)
    double finalPayable = payableAfterBill;
    if (purchase.amountPaid > 0) {
      finalPayable = payableAfterBill - purchase.amountPaid;
      updatedLedger.add(
        LedgerTransaction(
          id: 'LED-S-${DateTime.now().millisecondsSinceEpoch}-2',
          partyId: supplier.id,
          partyType: PartyType.supplier,
          date: purchase.date,
          referenceType: 'Payment on ${purchase.purchaseNumber}',
          description: 'Payment via ${purchase.paymentMethod.displayName}',
          debit: purchase.amountPaid,
          credit: 0.0,
          runningBalance: finalPayable,
        ),
      );
    }

    final updatedSupplier = supplier.copyWith(
      totalPurchases: supplier.totalPurchases + purchase.grandTotal,
      totalPaid: supplier.totalPaid + purchase.amountPaid,
      outstandingPayable: finalPayable,
      ledger: updatedLedger,
    );

    suppliers[index] = updatedSupplier;
    suppliers.refresh();

    if (selectedSupplier.value?.id == supplier.id) {
      selectedSupplier.value = updatedSupplier;
    }
  }

  bool paySupplier({
    required String supplierId,
    required double amount,
    required PaymentMethod method,
    required DateTime date,
    String? note,
  }) {
    final index = suppliers.indexWhere((s) => s.id == supplierId);
    if (index == -1) return false;

    final supplier = suppliers[index];
    final oldPayable = supplier.outstandingPayable;
    final newPayable = (oldPayable - amount).clamp(0.0, double.infinity);

    final updatedLedger = List<LedgerTransaction>.from(supplier.ledger);
    final voucherNo = 'PAY-${DateTime.now().millisecondsSinceEpoch % 10000}';

    updatedLedger.add(
      LedgerTransaction(
        id: 'LED-PAY-${DateTime.now().millisecondsSinceEpoch}',
        partyId: supplier.id,
        partyType: PartyType.supplier,
        date: date,
        referenceType: 'Payment Sent',
        description:
            'Voucher #$voucherNo - ${method.displayName}${note != null && note.isNotEmpty ? ' ($note)' : ''}',
        debit: amount,
        credit: 0.0,
        runningBalance: newPayable,
      ),
    );

    final updatedSupplier = supplier.copyWith(
      totalPaid: supplier.totalPaid + amount,
      outstandingPayable: newPayable,
      ledger: updatedLedger,
    );

    suppliers[index] = updatedSupplier;
    suppliers.refresh();

    if (selectedSupplier.value?.id == supplier.id) {
      selectedSupplier.value = updatedSupplier;
    }

    if (Get.context != null) {
      Get.snackbar(
        'Payment Recorded',
        'Paid Rs. ${amount.toStringAsFixed(0)} to ${supplier.name}. Remaining Payable: Rs. ${newPayable.toStringAsFixed(0)}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    return true;
  }
}
