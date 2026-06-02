import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/toggle_buttons.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class PropertyDetailsStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic>? initialData;

  const PropertyDetailsStep({super.key, required this.onContinue, this.initialData});

  @override
  State<PropertyDetailsStep> createState() => _PropertyDetailsStepState();
}

class _PropertyDetailsStepState extends State<PropertyDetailsStep> {
  String _selectedGender = 'Men';
  int _singleRooms = 0;
  int _doubleRooms = 0;
  int _tripleRooms = 0;
  int _dormitoryBeds = 0;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData?['propertyDetails'] ?? {};
    _selectedGender = data['gender'] ?? 'Men';
    _singleRooms = data['singleRooms'] ?? 0;
    _doubleRooms = data['doubleRooms'] ?? 0;
    _tripleRooms = data['tripleRooms'] ?? 0;
    _dormitoryBeds = data['dormitoryBeds'] ?? 0;
    _descriptionController = TextEditingController(text: data['description'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    int totalCapacity = _singleRooms + (_doubleRooms * 2) + (_tripleRooms * 3) + _dormitoryBeds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gender Preference *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor)),
          const SizedBox(height: 12),
          CustomToggleButtons(
            options: const ['Men', 'Women', 'Anyone'],
            selectedOption: _selectedGender,
            onOptionSelected: (val) => setState(() => _selectedGender = val),
            activeColor: AppTheme.successColor,
          ),
          const SizedBox(height: 32),
          const Text('Room Inventory *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor)),
          const SizedBox(height: 16),
          _buildCounterRow('Single Rooms', _singleRooms, (val) => setState(() => _singleRooms = val)),
          _buildCounterRow('Double Rooms', _doubleRooms, (val) => setState(() => _doubleRooms = val)),
          _buildCounterRow('Triple Rooms', _tripleRooms, (val) => setState(() => _tripleRooms = val)),
          _buildCounterRow('Dormitory Beds', _dormitoryBeds, (val) => setState(() => _dormitoryBeds = val)),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Capacity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 16, color: AppTheme.successColor),
                    const SizedBox(width: 8),
                    Text('$totalCapacity Residents', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.successColor)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          InputField(
            label: 'Property Description (Optional)',
            controller: _descriptionController,
            maxLines: 4,
            hintText: 'Tell us about your property, facilities and environment...',
            activeColor: AppTheme.successColor,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onContinue({
                  'propertyDetails': {
                    'gender': _selectedGender,
                    'singleRooms': _singleRooms,
                    'doubleRooms': _doubleRooms,
                    'tripleRooms': _tripleRooms,
                    'dormitoryBeds': _dormitoryBeds,
                    'description': _descriptionController.text,
                    'totalCapacity': totalCapacity,
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterRow(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textLightColor)),
          Row(
            children: [
              IconButton(
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 24),
                color: AppTheme.textMutedColor,
              ),
              const SizedBox(width: 12),
              Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => onChanged(value + 1),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                color: AppTheme.successColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
