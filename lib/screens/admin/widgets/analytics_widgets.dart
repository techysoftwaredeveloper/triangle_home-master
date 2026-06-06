import 'package:flutter/material.dart';

class OccupancyOverviewDonut extends StatelessWidget {
  final Map<String, dynamic> data;

  const OccupancyOverviewDonut({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyState(label: 'Occupancy Data');

    final occupied = (data['occupied'] ?? 0) as int;
    final vacant = (data['vacant'] ?? 0) as int;
    final total = occupied + vacant;
    final percentage = total > 0 ? (occupied / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Occupancy Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendItem(
                    color: const Color(0xFF10B981),
                    label: 'Occupied',
                    value: occupied.toString(),
                  ),
                  const SizedBox(height: 8),
                  _LegendItem(
                    color: Colors.white.withOpacity(0.1),
                    label: 'Vacant',
                    value: vacant.toString(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RevenueTrendChart extends StatelessWidget {
  final Map<String, dynamic> data;

  const RevenueTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyState(label: 'Revenue Data');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue Trend',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: const Center(
            child: Text(
              'Chart Placeholder',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class TopPerformingPropertiesList extends StatelessWidget {
  final List<dynamic> properties;

  const TopPerformingPropertiesList({super.key, required this.properties});

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) return const _EmptyState(label: 'Performance Data');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Performing Properties',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'This Month',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...properties.take(3).map((p) => _PropertyRankItem(property: p)).toList(),
      ],
    );
  }
}

class HighRiskPropertiesList extends StatelessWidget {
  final List<dynamic> properties;

  const HighRiskPropertiesList({super.key, required this.properties});

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) return const _EmptyState(label: 'Risk Data');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'High Risk Properties',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...properties.take(3).map((p) => _RiskItem(property: p)).toList(),
      ],
    );
  }
}

class ComplianceSummaryList extends StatelessWidget {
  final Map<String, dynamic> data;

  const ComplianceSummaryList({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyState(label: 'Compliance Data');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Compliance Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const Text(
              'View All',
              style: TextStyle(
                color: Color(0xFF8B5CF6),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ComplianceBadge(label: 'Verified', count: data['verified'] ?? 0, color: const Color(0xFF10B981)),
            _ComplianceBadge(label: 'Review', count: data['review'] ?? 0, color: const Color(0xFFF59E0B)),
            _ComplianceBadge(label: 'Expired', count: data['expired'] ?? 0, color: const Color(0xFFEF4444)),
            _ComplianceBadge(label: 'Rejected', count: data['rejected'] ?? 0, color: Colors.white24),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PropertyRankItem extends StatelessWidget {
  final Map<String, dynamic> property;

  const _PropertyRankItem({required this.property});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                property['thumbnail'] ?? 'https://via.placeholder.com/32',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32, 
                  height: 32, 
                  color: Colors.white.withOpacity(0.05),
                  child: const Icon(Icons.home_work_rounded, color: Colors.white24, size: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['name'] ?? 'Property',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${property['occupancy'] ?? 0}% Occupancy',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                  ),
                ],
              ),
            ),
            Text(
              '₹${property['revenue'] ?? 0}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskItem extends StatelessWidget {
  final Map<String, dynamic> property;

  const _RiskItem({required this.property});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['name'] ?? 'Property',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    property['riskReason'] ?? 'Compliance Failure',
                    style: TextStyle(color: const Color(0xFFEF4444).withOpacity(0.5), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplianceBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ComplianceBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
        ),
        const SizedBox(height: 6),
        Text(
          count.toString(),
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;

  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'No Data Available',
          style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
        ),
      ],
    );
  }
}
