import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../models/status_summary.dart';
import '../services/api_service.dart';

// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Inventory data provider with auto-refresh
final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getInventory();
});

// Inventory summary provider
final inventorySummaryProvider = FutureProvider<StatusSummary>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getInventorySummary();
});

// Filtered inventory state
class InventoryFilters {
  final List<String> selectedProducts;
  final List<String> selectedStatuses;

  InventoryFilters({
    required this.selectedProducts,
    required this.selectedStatuses,
  });

  InventoryFilters copyWith({
    List<String>? selectedProducts,
    List<String>? selectedStatuses,
  }) {
    return InventoryFilters(
      selectedProducts: selectedProducts ?? this.selectedProducts,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
    );
  }
}

// Filter state provider
final inventoryFiltersProvider =
    StateNotifierProvider<InventoryFiltersNotifier, InventoryFilters>((ref) {
  return InventoryFiltersNotifier();
});

class InventoryFiltersNotifier extends StateNotifier<InventoryFilters> {
  InventoryFiltersNotifier()
      : super(InventoryFilters(selectedProducts: [], selectedStatuses: []));

  void setProducts(List<String> products) {
    state = state.copyWith(selectedProducts: products);
  }

  void setStatuses(List<String> statuses) {
    state = state.copyWith(selectedStatuses: statuses);
  }

  void reset(List<String> allProducts, List<String> allStatuses) {
    state = InventoryFilters(
      selectedProducts: allProducts,
      selectedStatuses: allStatuses,
    );
  }
}

// Filtered inventory provider
final filteredInventoryProvider = Provider<List<InventoryItem>>((ref) {
  final inventory = ref.watch(inventoryProvider);
  final filters = ref.watch(inventoryFiltersProvider);

  return inventory.when(
    data: (items) {
      if (filters.selectedProducts.isEmpty &&
          filters.selectedStatuses.isEmpty) {
        return items;
      }

      return items.where((item) {
        final productMatch = filters.selectedProducts.isEmpty ||
            filters.selectedProducts.contains(item.productName);
        final statusMatch = filters.selectedStatuses.isEmpty ||
            filters.selectedStatuses.contains(item.status);
        return productMatch && statusMatch;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Available products provider
final availableProductsProvider = Provider<List<String>>((ref) {
  final inventory = ref.watch(inventoryProvider);
  return inventory.when(
    data: (items) {
      return items.map((i) => i.productName).toSet().toList()..sort();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Available statuses provider
final availableStatusesProvider = Provider<List<String>>((ref) {
  final inventory = ref.watch(inventoryProvider);
  return inventory.when(
    data: (items) {
      return items.map((i) => i.status).toSet().toList()..sort();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
