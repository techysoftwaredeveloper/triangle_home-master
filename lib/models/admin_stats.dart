class AdminStats {
  final int totalProperties;
  final int totalBookings;
  final int totalUsers;
  final double totalRevenue;
  final int pendingProperties;
  final List<ChartDataPoint> revenueHistory;
  final List<ChartDataPoint> bookingHistory;

  AdminStats({
    required this.totalProperties,
    required this.totalBookings,
    required this.totalUsers,
    required this.totalRevenue,
    required this.pendingProperties,
    this.revenueHistory = const [],
    this.bookingHistory = const [],
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalProperties: json['totalProperties'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      pendingProperties: json['pendingProperties'] ?? 0,
      revenueHistory: (json['revenueHistory'] as List?)
              ?.map((e) => ChartDataPoint.fromJson(e))
              .toList() ??
          [],
      bookingHistory: (json['bookingHistory'] as List?)
              ?.map((e) => ChartDataPoint.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ChartDataPoint {
  final String label;
  final double value;

  ChartDataPoint({required this.label, required this.value});

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
