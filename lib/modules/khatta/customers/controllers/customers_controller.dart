import 'package:get/get.dart';
import 'package:wholesale_app/data/mock_data/mock_seed_data.dart';
import '../models/customer_model.dart';
import '../models/ledger_model.dart';
import '../models/payment_model.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import 'package:wholesale_app/modules/sales/models/sale_model.dart';

class CustomersController extends GetxController {
  final customers = <CustomerModel>[].obs;
  final payments = <PaymentModel>[].obs;
  final searchQuery = ''.obs;
  final selectedCustomer = Rxn<CustomerModel>();

  int _voucherCounter = 100;
  int _txCounter = 1;

  @override
  void onInit() {
    super.onInit();
    loadInitialCustomers();
  }

  void loadInitialCustomers() {
    final list = MockSeedData.getCustomers();
    customers.assignAll(list);
    if (list.isNotEmpty) {
      selectedCustomer.value = list.first;
    }
  }

  List<CustomerModel> get filteredCustomers {
    if (searchQuery.value.isEmpty) {
      return customers;
    }
    final q = searchQuery.value.toLowerCase();
    return customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.city.toLowerCase().contains(q);
    }).toList();
  }

  double get totalReceivables =>
      customers.where((c) => c.isActive).fold(0.0, (sum, c) => sum + c.derivedBalance);

  CustomerModel? getCustomerById(String id) {
    try {
      return customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void selectCustomer(CustomerModel customer) {
    selectedCustomer.value = customer;
  }

  /// Duplicate validation check
  ({bool isDuplicate, String field}) checkDuplicate(String name, String phone, {String? excludeId}) {
    final normName = name.trim().toLowerCase();
    final normPhone = phone.replaceAll(RegExp(r'\s+'), '').toLowerCase();

    for (final c in customers) {
      if (excludeId != null && c.id == excludeId) continue;
      if (c.name.trim().toLowerCase() == normName) {
        return (isDuplicate: true, field: 'name');
      }
      final existingPhone = c.phone.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      if (existingPhone.isNotEmpty && existingPhone == normPhone) {
        return (isDuplicate: true, field: 'phone');
      }
    }
    return (isDuplicate: false, field: '');
  }

  ({bool success, String message, CustomerModel? customer}) addCustomerResult(CustomerModel customer) {
    final dup = checkDuplicate(customer.name, customer.phone);
    if (dup.isDuplicate) {
      final msg = dup.field == 'name'
          ? 'Customer with name "${customer.name}" already exists.'
          : 'Customer with phone "${customer.phone}" already exists.';
      return (success: false, message: msg, customer: null);
    }

    customers.insert(0, customer);
    selectedCustomer.value = customer;
    return (success: true, message: '${customer.name} registered successfully.', customer: customer);
  }

  void addCustomer(CustomerModel customer) {
    addCustomerResult(customer);
  }

  ({bool success, String message}) updateCustomer(CustomerModel updatedCustomer) {
    final dup = checkDuplicate(updatedCustomer.name, updatedCustomer.phone, excludeId: updatedCustomer.id);
    if (dup.isDuplicate) {
      final msg = dup.field == 'name'
          ? 'Another customer with name "${updatedCustomer.name}" already exists.'
          : 'Another customer with phone "${updatedCustomer.phone}" already exists.';
      return (success: false, message: msg);
    }

    final index = customers.indexWhere((c) => c.id == updatedCustomer.id);
    if (index != -1) {
      customers[index] = updatedCustomer;
      customers.refresh();
      if (selectedCustomer.value?.id == updatedCustomer.id) {
        selectedCustomer.value = updatedCustomer;
      }
      return (success: true, message: 'Customer details updated successfully.');
    }
    return (success: false, message: 'Customer not found.');
  }

  /// Rule 5: Deactivated parties stay in customers list so other modules don't break.
  ({bool success, String message}) deactivateCustomer(String customerId) {
    final index = customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      final updated = customers[index].copyWith(isActive: false);
      customers[index] = updated;
      customers.refresh();
      if (selectedCustomer.value?.id == customerId) {
        selectedCustomer.value = updated;
      }
      return (success: true, message: 'Customer deactivated successfully.');
    }
    return (success: false, message: 'Customer not found.');
  }

  void addSaleToCustomer(SaleModel sale) {
    final index = customers.indexWhere((c) => c.id == sale.customerId);
    if (index == -1) return;

    final customer = customers[index];
    final oldBalance = customer.derivedBalance;

    final updatedLedger = List<LedgerTransaction>.from(customer.ledger);
    final nowMs = DateTime.now().microsecondsSinceEpoch;

    // 1. Debit the sale grand total
    final balanceAfterInvoice = oldBalance + sale.grandTotal;
    updatedLedger.add(
      LedgerTransaction(
        id: 'LED-C-$nowMs-${_txCounter++}',
        partyId: customer.id,
        partyType: PartyType.customer,
        date: sale.date,
        referenceType: 'Sale ${sale.invoiceNumber}',
        description: 'Invoice Total (${sale.items.length} items)',
        debit: sale.grandTotal,
        credit: 0.0,
        runningBalance: balanceAfterInvoice,
      ),
    );

    // 2. If paid at time of sale, credit the paid amount
    double finalBalance = balanceAfterInvoice;
    if (sale.amountPaid > 0) {
      finalBalance = balanceAfterInvoice - sale.amountPaid;
      updatedLedger.add(
        LedgerTransaction(
          id: 'LED-C-$nowMs-${_txCounter++}',
          partyId: customer.id,
          partyType: PartyType.customer,
          date: sale.date,
          referenceType: 'Payment on ${sale.invoiceNumber}',
          description: 'Payment via ${sale.paymentMethod.displayName}',
          debit: 0.0,
          credit: sale.amountPaid,
          runningBalance: finalBalance,
        ),
      );
    }

    final updatedCustomer = customer.copyWith(
      totalPurchases: customer.totalPurchases + sale.grandTotal,
      amountReceived: customer.amountReceived + sale.amountPaid,
      outstandingBalance: finalBalance,
      ledger: updatedLedger,
    );

    customers[index] = updatedCustomer;
    customers.refresh();

    if (selectedCustomer.value?.id == customer.id) {
      selectedCustomer.value = updatedCustomer;
    }
  }

  /// Rule 1: New method returning structured result object
  ({bool success, String message, PaymentModel? payment}) receivePaymentResult({
    required String customerId,
    required double amount,
    required PaymentMethod method,
    required DateTime date,
    String? note,
    String? reference,
  }) {
    final index = customers.indexWhere((c) => c.id == customerId);
    if (index == -1) {
      return (success: false, message: 'Customer not found.', payment: null);
    }

    if (amount <= 0) {
      return (success: false, message: 'Payment amount must be greater than 0.', payment: null);
    }

    final customer = customers[index];
    final oldBalance = customer.derivedBalance;
    final newBalance = oldBalance - amount;

    _voucherCounter++;
    final voucherNo = 'RCV-${_voucherCounter.toString().padLeft(4, '0')}';
    final nowMs = DateTime.now().microsecondsSinceEpoch;

    final updatedLedger = List<LedgerTransaction>.from(customer.ledger);
    updatedLedger.add(
      LedgerTransaction(
        id: 'LED-RCV-$nowMs-${_txCounter++}',
        partyId: customer.id,
        partyType: PartyType.customer,
        date: date,
        referenceType: 'Payment Received',
        description: 'Voucher #$voucherNo - ${method.displayName}${note != null && note.isNotEmpty ? ' ($note)' : ''}',
        debit: 0.0,
        credit: amount,
        runningBalance: newBalance,
        voucherNumber: voucherNo,
      ),
    );

    final paymentRecord = PaymentModel(
      id: 'PAY-REC-$nowMs',
      voucherNumber: voucherNo,
      partyType: PartyType.customer,
      partyId: customer.id,
      partyName: customer.name,
      date: date,
      amount: amount,
      paymentMethod: method,
      reference: reference,
      notes: note,
    );

    payments.insert(0, paymentRecord);

    final updatedCustomer = customer.copyWith(
      amountReceived: customer.amountReceived + amount,
      outstandingBalance: newBalance,
      ledger: updatedLedger,
    );

    customers[index] = updatedCustomer;
    customers.refresh();

    if (selectedCustomer.value?.id == customer.id) {
      selectedCustomer.value = updatedCustomer;
    }

    return (
      success: true,
      message: 'Received Rs. ${amount.toStringAsFixed(0)} from ${customer.name}. Voucher #$voucherNo.',
      payment: paymentRecord,
    );
  }

  /// Rule 1: Old public method delegates to receivePaymentResult and returns bool
  bool receivePayment({
    required String customerId,
    required double amount,
    required PaymentMethod method,
    required DateTime date,
    String? note,
  }) {
    final res = receivePaymentResult(
      customerId: customerId,
      amount: amount,
      method: method,
      date: date,
      note: note,
    );
    return res.success;
  }

  /// Rule 4: Reversal allowed ONLY for Payment, Opening Balance and Adjustment entries.
  ({bool success, String message}) reverseLedgerEntry({
    required String customerId,
    required String transactionId,
    required String reason,
  }) {
    final index = customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return (success: false, message: 'Customer not found.');

    final customer = customers[index];
    final txIndex = customer.ledger.indexWhere((tx) => tx.id == transactionId);
    if (txIndex == -1) return (success: false, message: 'Transaction not found.');

    final targetTx = customer.ledger[txIndex];
    if (!targetTx.isCanBeReversed) {
      return (
        success: false,
        message: 'This entry type cannot be reversed from Khata. Reverse from the invoice (Sales/Purchases).',
      );
    }

    final updatedLedger = List<LedgerTransaction>.from(customer.ledger);
    updatedLedger[txIndex] = targetTx.copyWith(isReversed: true);

    // Opposite entry (if original was credit, reverse with debit, and vice versa)
    final nowMs = DateTime.now().microsecondsSinceEpoch;
    final revDebit = targetTx.credit;
    final revCredit = targetTx.debit;

    updatedLedger.add(
      LedgerTransaction(
        id: 'LED-REV-$nowMs-${_txCounter++}',
        partyId: customer.id,
        partyType: PartyType.customer,
        date: DateTime.now(),
        referenceType: 'Reversal',
        description: 'Reversal of ${targetTx.referenceType} (${reason.isEmpty ? "Correction" : reason})',
        debit: revDebit,
        credit: revCredit,
        runningBalance: 0.0, // Re-calculated below
        reversedEntryId: targetTx.id,
      ),
    );

    // Recalculate running balance for all ledger items
    double currentBal = 0.0;
    final recalculatedLedger = <LedgerTransaction>[];
    for (final tx in updatedLedger) {
      currentBal += (tx.debit - tx.credit);
      recalculatedLedger.add(tx.copyWith(runningBalance: currentBal));
    }

    final updatedCustomer = customer.copyWith(
      outstandingBalance: currentBal,
      ledger: recalculatedLedger,
    );

    customers[index] = updatedCustomer;
    customers.refresh();

    if (selectedCustomer.value?.id == customer.id) {
      selectedCustomer.value = updatedCustomer;
    }

    return (success: true, message: 'Ledger entry reversed successfully.');
  }
}
