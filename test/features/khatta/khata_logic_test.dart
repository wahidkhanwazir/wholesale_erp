import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/data/mock_data/mock_seed_data.dart';
import 'package:wholesale_app/modules/khatta/customers/controllers/customers_controller.dart';
import 'package:wholesale_app/modules/khatta/suppliers/controllers/suppliers_controller.dart';
import 'package:wholesale_app/modules/khatta/customers/models/customer_model.dart';
import 'package:wholesale_app/shared/models/enums.dart';

void main() {
  group('Khata Module Logic Tests', () {
    late CustomersController customersCtrl;
    late SuppliersController suppliersCtrl;

    setUp(() {
      Get.reset();
      customersCtrl = Get.put(CustomersController());
      suppliersCtrl = Get.put(SuppliersController());
    });

    tearDown(() {
      Get.reset();
    });

    test('Rule 3: Assert derived balance == stored balance for every party in MockSeedData', () {
      final customers = MockSeedData.getCustomers();
      for (final c in customers) {
        final derived = c.derivedBalance;
        final stored = c.outstandingBalance;
        expect(derived, closeTo(stored, 0.01), reason: 'Customer ${c.name} balance mismatch');
      }

      final suppliers = MockSeedData.getSuppliers();
      for (final s in suppliers) {
        final derived = s.derivedPayable;
        final stored = s.outstandingPayable;
        expect(derived, closeTo(stored, 0.01), reason: 'Supplier ${s.name} balance mismatch');
      }
    });

    test('Customer receive payment updates derived balance and stores PaymentModel', () {
      final customer = customersCtrl.customers.first;
      final initialBalance = customer.derivedBalance;

      final result = customersCtrl.receivePaymentResult(
        customerId: customer.id,
        amount: 10000.0,
        method: PaymentMethod.cash,
        date: DateTime.now(),
        note: 'Partial khata settlement',
      );

      expect(result.success, isTrue);
      expect(result.payment, isNotNull);
      expect(result.payment!.voucherNumber, startsWith('RCV-'));

      final updated = customersCtrl.getCustomerById(customer.id);
      expect(updated!.derivedBalance, equals(initialBalance - 10000.0));
      expect(customersCtrl.payments.length, equals(1));
    });

    test('Supplier payment updates derived payable and stores PaymentModel', () {
      final supplier = suppliersCtrl.suppliers.first;
      final initialPayable = supplier.derivedPayable;

      final result = suppliersCtrl.paySupplierResult(
        supplierId: supplier.id,
        amount: 15000.0,
        method: PaymentMethod.bank,
        date: DateTime.now(),
        note: 'Bank disbursement',
      );

      expect(result.success, isTrue);
      expect(result.payment, isNotNull);
      expect(result.payment!.voucherNumber, startsWith('PAY-'));

      final updated = suppliersCtrl.getSupplierById(supplier.id);
      expect(updated!.derivedPayable, equals(initialPayable - 15000.0));
      expect(suppliersCtrl.payments.length, equals(1));
    });

    test('Duplicate customer check prevents registering duplicate phone or name', () {
      final existing = customersCtrl.customers.first;

      // Duplicate name
      final dupNameResult = customersCtrl.addCustomerResult(
        CustomerModel(
          id: 'NEW-001',
          name: existing.name.toUpperCase(), // Case insensitive check
          phone: '+92 399 0000000',
          city: 'Lahore',
          totalPurchases: 0,
          amountReceived: 0,
          outstandingBalance: 0,
        ),
      );
      expect(dupNameResult.success, isFalse);
      expect(dupNameResult.message, contains('already exists'));

      // Duplicate phone
      final dupPhoneResult = customersCtrl.addCustomerResult(
        CustomerModel(
          id: 'NEW-002',
          name: 'Unique Shop Name',
          phone: existing.phone,
          city: 'Lahore',
          totalPurchases: 0,
          amountReceived: 0,
          outstandingBalance: 0,
        ),
      );
      expect(dupPhoneResult.success, isFalse);
      expect(dupPhoneResult.message, contains('already exists'));
    });

    test('Rule 4: Reversal allowed only for Payment/Opening, NOT for Sales/Purchases', () {
      final customer = customersCtrl.customers.first;

      // Find sale entry
      final saleTx = customer.ledger.firstWhere((tx) => tx.referenceType.toLowerCase().contains('sale'));
      expect(saleTx.isCanBeReversed, isFalse);

      final saleRevRes = customersCtrl.reverseLedgerEntry(
        customerId: customer.id,
        transactionId: saleTx.id,
        reason: 'Attempt reverse sale',
      );
      expect(saleRevRes.success, isFalse);

      // Find payment entry
      final payTx = customer.ledger.firstWhere((tx) => tx.referenceType.toLowerCase().contains('payment'));
      expect(payTx.isCanBeReversed, isTrue);

      final payRevRes = customersCtrl.reverseLedgerEntry(
        customerId: customer.id,
        transactionId: payTx.id,
        reason: 'Wrong entry correction',
      );
      expect(payRevRes.success, isTrue);
    });

    test('Rule 5: Deactivated parties stay in list with isActive = false', () {
      final customer = customersCtrl.customers.first;
      final initialCount = customersCtrl.customers.length;

      final res = customersCtrl.deactivateCustomer(customer.id);
      expect(res.success, isTrue);

      expect(customersCtrl.customers.length, equals(initialCount));
      final deactivated = customersCtrl.getCustomerById(customer.id);
      expect(deactivated!.isActive, isFalse);
    });
  });
}
