import 'package:get/get.dart';
import 'package:wholesale_app/data/mock_data/mock_seed_data.dart';
import '../models/supplier_model.dart';
import '../models/ledger_model.dart';
import '../models/payment_model.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import 'package:wholesale_app/modules/purchases/models/purchase_model.dart';

class SuppliersController extends GetxController {
  final suppliers = <SupplierModel>[].obs;
  final payments = <PaymentModel>[].obs;
  final searchQuery = ''.obs;
  final selectedSupplier = Rxn<SupplierModel>();

  int _voucherCounter = 200;
  int _txCounter = 1;

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
      suppliers.where((s) => s.isActive).fold(0.0, (sum, s) => sum + s.derivedPayable);

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

  /// Duplicate validation check
  ({bool isDuplicate, String field}) checkDuplicate(String name, String phone, {String? excludeId}) {
    final normName = name.trim().toLowerCase();
    final normPhone = phone.replaceAll(RegExp(r'\s+'), '').toLowerCase();

    for (final s in suppliers) {
      if (excludeId != null && s.id == excludeId) continue;
      if (s.name.trim().toLowerCase() == normName) {
        return (isDuplicate: true, field: 'name');
      }
      final existingPhone = s.phone.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      if (existingPhone.isNotEmpty && existingPhone == normPhone) {
        return (isDuplicate: true, field: 'phone');
      }
    }
    return (isDuplicate: false, field: '');
  }

  ({bool success, String message, SupplierModel? supplier}) addSupplierResult(SupplierModel supplier) {
    final dup = checkDuplicate(supplier.name, supplier.phone);
    if (dup.isDuplicate) {
      final msg = dup.field == 'name'
          ? 'Supplier with name "${supplier.name}" already exists.'
          : 'Supplier with phone "${supplier.phone}" already exists.';
      return (success: false, message: msg, supplier: null);
    }

    suppliers.insert(0, supplier);
    selectedSupplier.value = supplier;
    return (success: true, message: '${supplier.name} registered successfully.', supplier: supplier);
  }

  void addSupplier(SupplierModel supplier) {
    addSupplierResult(supplier);
  }

  ({bool success, String message}) updateSupplier(SupplierModel updatedSupplier) {
    final dup = checkDuplicate(updatedSupplier.name, updatedSupplier.phone, excludeId: updatedSupplier.id);
    if (dup.isDuplicate) {
      final msg = dup.field == 'name'
          ? 'Another supplier with name "${updatedSupplier.name}" already exists.'
          : 'Another supplier with phone "${updatedSupplier.phone}" already exists.';
      return (success: false, message: msg);
    }

    final index = suppliers.indexWhere((s) => s.id == updatedSupplier.id);
    if (index != -1) {
      suppliers[index] = updatedSupplier;
      suppliers.refresh();
      if (selectedSupplier.value?.id == updatedSupplier.id) {
        selectedSupplier.value = updatedSupplier;
      }
      return (success: true, message: 'Supplier details updated successfully.');
    }
    return (success: false, message: 'Supplier not found.');
  }

  /// Rule 5: Deactivated parties stay in suppliers list so other modules don't break.
  ({bool success, String message}) deactivateSupplier(String supplierId) {
    final index = suppliers.indexWhere((s) => s.id == supplierId);
    if (index != -1) {
      final updated = suppliers[index].copyWith(isActive: false);
      suppliers[index] = updated;
      suppliers.refresh();
      if (selectedSupplier.value?.id == supplierId) {
        selectedSupplier.value = updated;
      }
      return (success: true, message: 'Supplier deactivated successfully.');
    }
    return (success: false, message: 'Supplier not found.');
  }

  void addPurchaseToSupplier(PurchaseModel purchase) {
    final index = suppliers.indexWhere((s) => s.id == purchase.supplierId);
    if (index == -1) return;

    final supplier = suppliers[index];
    final oldPayable = supplier.derivedPayable;

    final updatedLedger = List<LedgerTransaction>.from(supplier.ledger);
    final nowMs = DateTime.now().microsecondsSinceEpoch;

    // 1. Credit the bill grand total (increases payable)
    final payableAfterBill = oldPayable + purchase.grandTotal;
    updatedLedger.add(
      LedgerTransaction(
        id: 'LED-S-$nowMs-${_txCounter++}',
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
          id: 'LED-S-$nowMs-${_txCounter++}',
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

  /// Rule 1: New method returning structured result object
  ({bool success, String message, PaymentModel? payment}) paySupplierResult({
    required String supplierId,
    required double amount,
    required PaymentMethod method,
    required DateTime date,
    String? note,
    String? reference,
  }) {
    final index = suppliers.indexWhere((s) => s.id == supplierId);
    if (index == -1) {
      return (success: false, message: 'Supplier not found.', payment: null);
    }

    if (amount <= 0) {
      return (success: false, message: 'Disbursement amount must be greater than 0.', payment: null);
    }

    final supplier = suppliers[index];
    final oldPayable = supplier.derivedPayable;
    final newPayable = oldPayable - amount;

    _voucherCounter++;
    final voucherNo = 'PAY-${_voucherCounter.toString().padLeft(4, '0')}';
    final nowMs = DateTime.now().microsecondsSinceEpoch;

    final updatedLedger = List<LedgerTransaction>.from(supplier.ledger);
    updatedLedger.add(
      LedgerTransaction(
        id: 'LED-PAY-$nowMs-${_txCounter++}',
        partyId: supplier.id,
        partyType: PartyType.supplier,
        date: date,
        referenceType: 'Payment Sent',
        description: 'Voucher #$voucherNo - ${method.displayName}${note != null && note.isNotEmpty ? ' ($note)' : ''}',
        debit: amount,
        credit: 0.0,
        runningBalance: newPayable,
        voucherNumber: voucherNo,
      ),
    );

    final paymentRecord = PaymentModel(
      id: 'PAY-DISB-$nowMs',
      voucherNumber: voucherNo,
      partyType: PartyType.supplier,
      partyId: supplier.id,
      partyName: supplier.name,
      date: date,
      amount: amount,
      paymentMethod: method,
      reference: reference,
      notes: note,
    );

    payments.insert(0, paymentRecord);

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

    return (
      success: true,
      message: 'Paid Rs. ${amount.toStringAsFixed(0)} to ${supplier.name}. Voucher #$voucherNo.',
      payment: paymentRecord,
    );
  }

  /// Rule 1: Old public method delegates to paySupplierResult and returns bool
  bool paySupplier({
    required String supplierId,
    required double amount,
    required PaymentMethod method,
    required DateTime date,
    String? note,
  }) {
    final res = paySupplierResult(
      supplierId: supplierId,
      amount: amount,
      method: method,
      date: date,
      note: note,
    );
    return res.success;
  }

  /// Rule 4: Reversal allowed ONLY for Payment, Opening Balance and Adjustment entries.
  ({bool success, String message}) reverseLedgerEntry({
    required String supplierId,
    required String transactionId,
    required String reason,
  }) {
    final index = suppliers.indexWhere((s) => s.id == supplierId);
    if (index == -1) return (success: false, message: 'Supplier not found.');

    final supplier = suppliers[index];
    final txIndex = supplier.ledger.indexWhere((tx) => tx.id == transactionId);
    if (txIndex == -1) return (success: false, message: 'Transaction not found.');

    final targetTx = supplier.ledger[txIndex];
    if (!targetTx.isCanBeReversed) {
      return (
        success: false,
        message: 'This entry type cannot be reversed from Khata. Reverse from the invoice (Sales/Purchases).',
      );
    }

    final updatedLedger = List<LedgerTransaction>.from(supplier.ledger);
    updatedLedger[txIndex] = targetTx.copyWith(isReversed: true);

    // Opposite entry (if original was debit, reverse with credit, and vice versa)
    final nowMs = DateTime.now().microsecondsSinceEpoch;
    final revDebit = targetTx.credit;
    final revCredit = targetTx.debit;

    updatedLedger.add(
      LedgerTransaction(
        id: 'LED-REV-$nowMs-${_txCounter++}',
        partyId: supplier.id,
        partyType: PartyType.supplier,
        date: DateTime.now(),
        referenceType: 'Reversal',
        description: 'Reversal of ${targetTx.referenceType} (${reason.isEmpty ? "Correction" : reason})',
        debit: revDebit,
        credit: revCredit,
        runningBalance: 0.0, // Re-calculated below
        reversedEntryId: targetTx.id,
      ),
    );

    // Recalculate running balance for all ledger items (Payable = credit - debit)
    double currentBal = 0.0;
    final recalculatedLedger = <LedgerTransaction>[];
    for (final tx in updatedLedger) {
      currentBal += (tx.credit - tx.debit);
      recalculatedLedger.add(tx.copyWith(runningBalance: currentBal));
    }

    final updatedSupplier = supplier.copyWith(
      outstandingPayable: currentBal,
      ledger: recalculatedLedger,
    );

    suppliers[index] = updatedSupplier;
    suppliers.refresh();

    if (selectedSupplier.value?.id == supplier.id) {
      selectedSupplier.value = updatedSupplier;
    }

    return (success: true, message: 'Ledger entry reversed successfully.');
  }
}
