import 'package:flutter/material.dart';
import 'package:wholesale_app/core/routes/app_routes.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../views/khata_view.dart';

class CustomersView extends StatelessWidget {
  const CustomersView({super.key});

  @override
  Widget build(BuildContext context) {
    return const KhataView(
      currentRoute: AppRoutes.customers,
      initialType: PartyType.customer,
    );
  }
}
