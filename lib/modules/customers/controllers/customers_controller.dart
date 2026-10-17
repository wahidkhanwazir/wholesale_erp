import 'package:get/get.dart';
import '../../../data/mock_data/mock_seed_data.dart';
import '../models/customer_model.dart';
import '../models/ledger_model.dart';
import '../../../shared/models/enums.dart';
import '../../sales/models/sale_model.dart';

class CustomersController extends GetxController {
  final customers = <CustomerModel>[].obs;
  final searchQuery = ''.obs;
  final selectedCustomer = Rxn<CustomerModel>();

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
      customers.fold(0.0, (sum, c) => sum + c.outstandingBalance);

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

  void addCustomer(CustomerModel customer) {
    customers.insert(0, customer);
    selectedCustomer.value = customer;
    if (Get.context != null) {
      Get.snackbar(
        'Customer Added',
        '${customer.name} was successfully registered.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void addSaleToCustomer(SaleModel sale) {
    final index = customers.indexWhere((c) => c.id == sale.customerId);
    if (index == -1) return;

    final customer = customers[index];
    final oldBalance = customer.outstandingBalance;

    final updatedLedger = List<LedgerTransaction>.from(customer.ledger);

    // 1. Debit the sale grand total
    final balanceAfterInvoice = oldBalance + sale.grandTotal;
    updatedLedger.add(
      LedgerTransaction(
        id: 'LED-C-${DateTime.now().millisecondsSinceEpoch}-1',
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
          id: 'LED-C-${DateTime.now().millisecondsSinceEpoch}-2',
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

  bool receivePayment({
    required String customerId,
    required double amount,
    required PaymentMethod method,
    required DateTime date,
    String? note,
  }) {
    final index = customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return false;

    final customer = customers[index];
    final oldBalance = customer.outstandingBalance;
    final newBalance = (oldBalance - amount);

    final updatedLedger = List<LedgerTransaction>.from(customer.ledger);
    final voucherNo = 'RCV-${DateTime.now().millisecondsSinceEpoch % 10000}';

    updatedLedger.add(
      LedgerTransaction(
        id: 'LED-RCV-${DateTime.now().millisecondsSinceEpoch}',
        partyId: customer.id,
        partyType: PartyType.customer,
        date: date,
        referenceType: 'Payment Received',
        description:
            'Voucher #$voucherNo - ${method.displayName}${note != null && note.isNotEmpty ? ' ($note)' : ''}',
        debit: 0.0,
        credit: amount,
        runningBalance: newBalance,
      ),
    );

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

    if (Get.context != null) {
      Get.snackbar(
        'Payment Recorded',
        'Received Rs. ${amount.toStringAsFixed(0)} from ${customer.name}. New Khata Balance: Rs. ${newBalance.toStringAsFixed(0)}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    return true;
  }
}
