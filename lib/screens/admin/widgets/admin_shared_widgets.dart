import 'package:flutter/material.dart';

class TabHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final bool isNarrow;

  const TabHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (actions != null) ...[
          const SizedBox(width: 16),
          Row(children: actions!),
        ],
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String count;
  final String label;
  final Color bg;
  final Color color;
  final IconData icon;
  final String? percentage;
  final bool? isUp;
  final String? sub;

  const SummaryCard({
    super.key,
    required this.count,
    required this.label,
    required this.bg,
    required this.color,
    required this.icon,
    this.percentage,
    this.isUp,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxHeight < 120 || constraints.maxWidth < 150;
        final double padding = isSmall ? 12.0 : 20.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmall ? 6 : 8),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: color, size: isSmall ? 16 : 20),
                    ),
                    if (percentage != null && !isSmall)
                      Row(
                        children: [
                          Icon(
                            isUp == false ? Icons.arrow_downward : Icons.arrow_upward,
                            color: Colors.green,
                            size: 12,
                          ),
                          Text(
                            percentage!,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                SizedBox(height: isSmall ? 8 : 16),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: isSmall ? 22 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSmall ? 10 : 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (sub != null && !isSmall) ...[
                  const SizedBox(height: 4),
                  Text(
                    sub!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ],
            ),
          ),
        );
      }
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class PaginationBtn extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final bool active;

  const PaginationBtn({super.key, this.icon, this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2563EB) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 16, color: active ? Colors.white : const Color(0xFF64748B))
            : Text(
                label!,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class SearchFilterRow extends StatelessWidget {
  final String hint;
  final bool isNarrow;
  final Function(String)? onSearch;
  final TextEditingController? controller;

  const SearchFilterRow({
    super.key,
    required this.hint,
    required this.isNarrow,
    this.onSearch,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onSearch,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: InputBorder.none,
                      hintStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildAction('Filter', Icons.tune),
        if (!isNarrow) ...[
          const SizedBox(width: 12),
          _buildAction('More Filters', null, true),
          const SizedBox(width: 12),
          _buildAction('Newest First', null, true),
        ],
      ],
    );
  }

  Widget _buildAction(String label, [IconData? icon, bool hasDropdown = false]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: const Color(0xFF64748B)), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          if (hasDropdown || icon == null) ...[
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
          ],
        ],
      ),
    );
  }
}
