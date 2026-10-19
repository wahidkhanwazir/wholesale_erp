import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/modules/inventory/controllers/inventory_controller.dart';
import 'package:wholesale_app/modules/khatta/customers/controllers/customers_controller.dart';
import 'package:wholesale_app/modules/khatta/suppliers/controllers/suppliers_controller.dart';
import 'package:wholesale_app/modules/sales/controllers/sales_controller.dart';
import 'package:wholesale_app/modules/purchases/controllers/purchases_controller.dart';
import 'package:wholesale_app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import 'package:wholesale_app/modules/sales/models/sale_model.dart';
import 'package:wholesale_app/modules/purchases/models/purchase_model.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.put<InventoryController>(InventoryController());
    Get.put<CustomersController>(CustomersController());
    Get.put<SuppliersController>(SuppliersController());
    Get.put<SalesController>(SalesController());
    Get.put<PurchasesController>(PurchasesController());
    Get.put<DashboardController>(DashboardController());
  });

  tearDown(() {
    Get.reset();
  });

  test('New sale deducts stock and updates customer khata', () {
    final inventoryCtrl = Get.find<InventoryController>();
    final customersCtrl = Get.find<CustomersController>();
    final salesCtrl = Get.find<SalesController>();

    final product = inventoryCtrl.products.first;
    final initialStock = product.stockQuantity;

    final customer = customersCtrl.customers.first;
    final initialBalance = customer.outstandingBalance;

    final saleItem = SaleItem(
      productId: product.id,
      productName: product.name,
      productCode: product.code,
      size: product.size,
      color: product.color,
      quantity: 5,
      unitPrice: product.salePrice,
    );

    final grandTotal = saleItem.total;
    const paid = 0.0; // on credit

    final sale = SaleModel(
      id: 'TEST-SALE-001',
      invoiceNumber: salesCtrl.generateInvoiceNumber(),
      date: DateTime.now(),
      customerId: customer.id,
      customerName: customer.name,
      items: [saleItem],
      subtotal: grandTotal,
      discount: 0,
      grandTotal: grandTotal,
      amountPaid: paid,
      remainingBalance: grandTotal,
      paymentStatus: PaymentStatus.unpaid,
      paymentMethod: PaymentMethod.credit,
    );

    final result = salesCtrl.createNewSale(sale);
    expect(result.success, isTrue);

    // Verify stock deducted
    final updatedProduct = inventoryCtrl.getProductById(product.id);
    expect(updatedProduct!.stockQuantity, initialStock - 5);

    // Verify customer balance increased by grandTotal
    final updatedCustomer = customersCtrl.getCustomerById(customer.id);
    expect(updatedCustomer!.outstandingBalance, initialBalance + grandTotal);
  });

  test(
    'Customer payment decreases outstanding balance and adds ledger entry',
    () {
      final customersCtrl = Get.find<CustomersController>();
      final customer = customersCtrl.customers.first;
      final initialBalance = customer.outstandingBalance;
      final initialLedgerCount = customer.ledger.length;

      const paymentAmount = 15000.0;
      final success = customersCtrl.receivePayment(
        customerId: customer.id,
        amount: paymentAmount,
        method: PaymentMethod.cash,
        date: DateTime.now(),
        note: 'Test Payment',
      );

      expect(success, isTrue);

      final updatedCustomer = customersCtrl.getCustomerById(customer.id);
      expect(
        updatedCustomer!.outstandingBalance,
        initialBalance - paymentAmount,
      );
      expect(updatedCustomer.ledger.length, initialLedgerCount + 1);
      expect(updatedCustomer.ledger.last.credit, paymentAmount);
    },
  );

  test('New purchase replenishes stock and updates supplier payable', () {
    final inventoryCtrl = Get.find<InventoryController>();
    final suppliersCtrl = Get.find<SuppliersController>();
    final purchasesCtrl = Get.find<PurchasesController>();

    final product = inventoryCtrl.products.first;
    final initialStock = product.stockQuantity;

    final supplier = suppliersCtrl.suppliers.first;
    final initialPayable = supplier.outstandingPayable;

    final purchaseItem = PurchaseItem(
      productId: product.id,
      productName: product.name,
      productCode: product.code,
      size: product.size,
      color: product.color,
      quantity: 50,
      unitPrice: product.purchasePrice,
    );

    final grandTotal = purchaseItem.total;
    const paid = 0.0; // on credit

    final purchase = PurchaseModel(
      id: 'TEST-PUR-001',
      purchaseNumber: purchasesCtrl.generatePurchaseNumber(),
      date: DateTime.now(),
      supplierId: supplier.id,
      supplierName: supplier.name,
      items: [purchaseItem],
      subtotal: grandTotal,
      discount: 0,
      grandTotal: grandTotal,
      amountPaid: paid,
      remainingPayable: grandTotal,
      paymentStatus: PaymentStatus.unpaid,
      paymentMethod: PaymentMethod.credit,
    );

    purchasesCtrl.createNewPurchase(purchase);

    // Verify stock replenished
    final updatedProduct = inventoryCtrl.getProductById(product.id);
    expect(updatedProduct!.stockQuantity, initialStock + 50);

    // Verify supplier payable updated
    final updatedSupplier = suppliersCtrl.getSupplierById(supplier.id);
    expect(updatedSupplier!.outstandingPayable, initialPayable + grandTotal);
  });
}
