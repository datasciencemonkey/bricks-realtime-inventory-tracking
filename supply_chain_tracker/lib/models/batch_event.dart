class BatchEvent {
  final int recordId;
  final String batchId;
  final String productId;
  final String productName;
  final String event;
  final String eventTimeCst;
  final String entityInvolved;
  final String entityName;
  final String entityLocation;
  final double entityLatitude;
  final double entityLongitude;
  final String eventTimeCstReadable;

  BatchEvent({
    required this.recordId,
    required this.batchId,
    required this.productId,
    required this.productName,
    required this.event,
    required this.eventTimeCst,
    required this.entityInvolved,
    required this.entityName,
    required this.entityLocation,
    required this.entityLatitude,
    required this.entityLongitude,
    required this.eventTimeCstReadable,
  });

  factory BatchEvent.fromJson(Map<String, dynamic> json) {
    return BatchEvent(
      recordId: json['record_id'] as int,
      batchId: json['batch_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      event: json['event'] as String,
      eventTimeCst: json['event_time_cst'] as String,
      entityInvolved: json['entity_involved'] as String,
      entityName: json['entity_name'] as String,
      entityLocation: json['entity_location'] as String,
      entityLatitude: (json['entity_latitude'] as num).toDouble(),
      entityLongitude: (json['entity_longitude'] as num).toDouble(),
      eventTimeCstReadable: json['event_time_cst_readable'] as String,
    );
  }
}
