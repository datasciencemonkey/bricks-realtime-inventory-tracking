class InventoryItem {
  final int recordId;
  final String referenceNumber;
  final String productId;
  final String productName;
  final String status;
  final String statusCategory;
  final int qty;
  final double unitPrice;
  final String currentLocation;
  final double latitude;
  final double longitude;
  final String destination;
  final double timeRemainingToDestinationHours;
  final String lastUpdatedCst;
  final String expectedArrivalTime;
  final String batchId;
  final String transitStatus; // "On Time", "Delayed", etc.

  InventoryItem({
    required this.recordId,
    required this.referenceNumber,
    required this.productId,
    required this.productName,
    required this.status,
    required this.statusCategory,
    required this.qty,
    required this.unitPrice,
    required this.currentLocation,
    required this.latitude,
    required this.longitude,
    required this.destination,
    required this.timeRemainingToDestinationHours,
    required this.lastUpdatedCst,
    required this.expectedArrivalTime,
    required this.batchId,
    required this.transitStatus,
  });

  /// Check if this shipment is delayed
  bool get isDelayed => transitStatus.toLowerCase().contains('delay');

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      recordId: json['record_id'] ?? 0,
      referenceNumber: json['reference_number'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      status: json['status'] ?? '',
      statusCategory: json['status_category'] ?? '',
      qty: json['qty'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      currentLocation: json['current_location'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      destination: json['destination'] ?? '',
      timeRemainingToDestinationHours:
          (json['time_remaining_to_destination_hours'] ?? 0).toDouble(),
      lastUpdatedCst: json['last_updated_cst'] ?? '',
      expectedArrivalTime: json['expected_arrival_time'] ?? '',
      batchId: json['batch_id'] ?? '',
      transitStatus: json['transit_status'] ?? 'On Time',
    );
  }
}
