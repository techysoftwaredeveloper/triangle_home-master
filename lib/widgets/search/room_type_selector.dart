import 'package:flutter/material.dart';
import 'package:triangle_home/widgets/search/option_button.dart';


class RoomTypeSelector extends StatelessWidget {
  final List<String> roomTypes;
  final String selectedType;
  final Function(String) onTypeSelected;

  const RoomTypeSelector({
    super.key,
    required this.roomTypes,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Room Type:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roomTypes.map((type) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 48) / 3,
              child: OptionButton(
                text: type,
                isSelected: selectedType == type,
                onTap: () => onTypeSelected(type),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}