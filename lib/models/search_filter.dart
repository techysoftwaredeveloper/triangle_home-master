class SearchFilter {
  final String? city;
  final List<String>? localities;
  final String? college;
  final String? accommodationType;
  final String? tenantType;
  final String? roomType;
  final double? minPrice;
  final double? maxPrice;

  SearchFilter({
    this.city,
    this.localities,
    this.college,
    this.accommodationType,
    this.tenantType,
    this.roomType,
    this.minPrice,
    this.maxPrice,
  });

  SearchFilter copyWith({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
    double? minPrice,
    double? maxPrice,
  }) {
    return SearchFilter(
      city: city ?? this.city,
      localities: localities ?? this.localities,
      college: college ?? this.college,
      accommodationType: accommodationType ?? this.accommodationType,
      tenantType: tenantType ?? this.tenantType,
      roomType: roomType ?? this.roomType,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }

  bool get isEmpty =>
      (city == null || city!.isEmpty) &&
      (localities == null || localities!.isEmpty) &&
      (college == null || college!.isEmpty) &&
      accommodationType == null &&
      tenantType == null &&
      roomType == null &&
      minPrice == null &&
      maxPrice == null;
}
