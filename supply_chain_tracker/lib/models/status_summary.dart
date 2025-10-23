class StatusSummary {
  final int inTransit;
  final int atDc;
  final int atDock;
  final int delivered;
  final int totalUnits;

  StatusSummary({
    required this.inTransit,
    required this.atDc,
    required this.atDock,
    required this.delivered,
    required this.totalUnits,
  });

  factory StatusSummary.fromJson(Map<String, dynamic> json) {
    return StatusSummary(
      inTransit: json['in_transit'] ?? 0,
      atDc: json['at_dc'] ?? 0,
      atDock: json['at_dock'] ?? 0,
      delivered: json['delivered'] ?? 0,
      totalUnits: json['total_units'] ?? 0,
    );
  }
}
