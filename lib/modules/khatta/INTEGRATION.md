# Khata Module Integration Instructions

These are the exact copy-paste code snippets for integrating the unified **Khata Module** into the main app routes, navigation sidebar, and initial bindings.

---

### 1. Update `lib/core/routes/app_routes.dart`

Add the unified Khata route constant:

```dart
class AppRoutes {
  static const String dashboard = '/dashboard';
  static const String sales = '/sales';
  static const String purchases = '/purchases';
  static const String customers = '/customers';
  static const String suppliers = '/suppliers';
  static const String inventory = '/inventory';
  static const String khata = '/khata'; // <-- ADD THIS LINE
}
```

---

### 2. Update `lib/core/routes/app_pages.dart`

Add the `KhataView` page route definition:

```dart
import '../../modules/khatta/views/khata_view.dart';
import '../../modules/khatta/bindings/khata_binding.dart';

// Inside AppPages.routes list:
GetPage(
  name: AppRoutes.khata,
  page: () => const KhataView(currentRoute: AppRoutes.khata),
  binding: KhataBinding(),
  transition: Transition.fadeIn,
),
```

---

### 3. Update `lib/core/widgets/sidebar_navigation.dart`

Add the "Khata" menu item in the sidebar navigation list:

```dart
_buildNavItem(
  title: 'Khata',
  icon: Icons.menu_book_rounded,
  route: AppRoutes.khata,
),
```

---

### 4. Update `lib/core/bindings/initial_binding.dart`

Optionally update `InitialBinding` to register `KhataBinding`:

```dart
import '../../modules/khatta/bindings/khata_binding.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    KhataBinding().dependencies();
    // ...
  }
}
```
