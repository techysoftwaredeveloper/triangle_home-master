class AdminStats {
  final int totalProperties;
  final int totalBookings;
  final int totalUsers;
  final double totalRevenue;
  final int pendingProperties;

  AdminStats({
    required this.totalProperties,
    required this.totalBookings,
    required this.totalUsers,
    required this.totalRevenue,
    required this.pendingProperties,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalProperties: json['totalProperties'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      pendingProperties: json['pendingProperties'] ?? 0,
    );
  }
}
