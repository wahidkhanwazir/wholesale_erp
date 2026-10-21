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
import 'package:wholesale_app/modules/khatta/customers/models/customer_model.dart';
import 'package:wholesale_app/modules/khatta/suppliers/models/supplier_model.dart';

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

  test('Sales filtering by customer name, status, and date range works correctly', () {
    final salesCtrl = Get.find<SalesController>();
    final allCount = salesCtrl.sales.length;
    expect(salesCtrl.filteredSales.length, allCount);

    // Filter by customer
    final targetCustomer = salesCtrl.sales.first.customerName;
    salesCtrl.customerFilter.value = targetCustomer;
    expect(
      salesCtrl.filteredSales.every((s) => s.customerName == targetCustomer),
      isTrue,
    );
    expect(salesCtrl.filteredSales.isNotEmpty, isTrue);

    // Filter by 'All' resets customer filter
    salesCtrl.customerFilter.value = 'All';
    expect(salesCtrl.filteredSales.length, allCount);

    // Filter by Date Range
    final firstDate = salesCtrl.sales.first.date;
    salesCtrl.startDate.value = DateTime(firstDate.year, firstDate.month, firstDate.day);
    salesCtrl.endDate.value = DateTime(firstDate.year, firstDate.month, firstDate.day);
    expect(
      salesCtrl.filteredSales.every(
        (s) =>
            s.date.year == firstDate.year &&
            s.date.month == firstDate.month &&
            s.date.day == firstDate.day,
      ),
      isTrue,
    );

    // Clear date range resets
    salesCtrl.clearDateRange();
    expect(salesCtrl.filteredSales.length, allCount);
  });

  test('Purchases filtering by supplier name, status, and date range works correctly', () {
    final purchasesCtrl = Get.find<PurchasesController>();
    final allCount = purchasesCtrl.purchases.length;
    expect(purchasesCtrl.filteredPurchases.length, allCount);

    // Filter by supplier
    final targetSupplier = purchasesCtrl.purchases.first.supplierName;
    purchasesCtrl.supplierFilter.value = targetSupplier;
    expect(
      purchasesCtrl.filteredPurchases.every((p) => p.supplierName == targetSupplier),
      isTrue,
    );
    expect(purchasesCtrl.filteredPurchases.isNotEmpty, isTrue);

    // Filter by 'All' resets supplier filter
    purchasesCtrl.supplierFilter.value = 'All';
    expect(purchasesCtrl.filteredPurchases.length, allCount);

    // Clear date range
    purchasesCtrl.clearDateRange();
    expect(purchasesCtrl.filteredPurchases.length, allCount);
  });

  test('Add customer/seller with contactPerson, sellerType and location details', () {
    final customersCtrl = Get.find<CustomersController>();
    final initialCount = customersCtrl.customers.length;

    customersCtrl.addCustomer(
      CustomerModel(
        id: 'CUST-TEST-1',
        name: 'Al-Madina Garments',
        contactPerson: 'Haji Aslam',
        sellerType: 'Wholesale Customer',
        phone: '0300-1234567',
        city: 'Gujranwala',
        address: 'Shop 12, Main Cloth Market',
        outstandingBalance: 45000,
        totalPurchases: 0,
        amountReceived: 0,
        ledger: [],
      ),
    );

    expect(customersCtrl.customers.length, initialCount + 1);
    final added = customersCtrl.customers.firstWhere((c) => c.name == 'Al-Madina Garments');
    expect(added.contactPerson, 'Haji Aslam');
    expect(added.sellerType, 'Wholesale Customer');
    expect(added.phone, '0300-1234567');
    expect(added.city, 'Gujranwala');
    expect(added.address, 'Shop 12, Main Cloth Market');
    expect(added.outstandingBalance, 45000);

    // Also add a Sales Agent seller
    customersCtrl.addCustomer(
      CustomerModel(
        id: 'CUST-TEST-2',
        name: 'Kamran & Sons Trading',
        contactPerson: 'Kamran Sheikh',
        sellerType: 'Sales Agent / Seller',
        phone: '0321-9876543',
        city: 'Faisalabad',
        address: 'Office 4, Textile Plaza',
        outstandingBalance: 0,
        totalPurchases: 0,
        amountReceived: 0,
        ledger: [],
      ),
    );

    final agent = customersCtrl.customers.firstWhere((c) => c.name == 'Kamran & Sons Trading');
    expect(agent.sellerType, 'Sales Agent / Seller');
    expect(agent.contactPerson, 'Kamran Sheikh');
  });

  test('Add supplier with contactPerson, mill name, city, address and opening payable', () {
    final suppliersCtrl = Get.find<SuppliersController>();
    final initialCount = suppliersCtrl.suppliers.length;

    suppliersCtrl.addSupplier(
      SupplierModel(
        id: 'SUPP-TEST-1',
        name: 'Sitara Textile Mills',
        contactPerson: 'Mian Bashir',
        phone: '0301-7654321',
        city: 'Faisalabad',
        address: 'Sargodha Road, Industrial Estate',
        outstandingPayable: 120000,
        totalPurchases: 0,
        totalPaid: 0,
        ledger: [],
      ),
    );

    expect(suppliersCtrl.suppliers.length, initialCount + 1);
    final added = suppliersCtrl.suppliers.firstWhere((s) => s.name == 'Sitara Textile Mills');
    expect(added.contactPerson, 'Mian Bashir');
    expect(added.phone, '0301-7654321');
    expect(added.city, 'Faisalabad');
    expect(added.address, 'Sargodha Road, Industrial Estate');
    expect(added.outstandingPayable, 120000);
  });
}

