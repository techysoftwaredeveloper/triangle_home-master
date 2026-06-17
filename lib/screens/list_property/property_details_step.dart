import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:triangle_home/services/property_structure_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/toggle_buttons.dart';

class PropertyStructureData {
  final List<Map<String, dynamic>> floors;
  final List<Map<String, dynamic>> rooms;
  final List<Map<String, dynamic>> beds;
  final bool hasPendingWrites;
  PropertyStructureData({
    required this.floors,
    required this.rooms,
    required this.beds,
    required this.hasPendingWrites,
  });
}

class PropertyDetailsStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic>? initialData;

  const PropertyDetailsStep({
    super.key,
    required this.onContinue,
    this.initialData,
  });

  @override
  State<PropertyDetailsStep> createState() => _PropertyDetailsStepState();
}

class _PropertyDetailsStepState extends State<PropertyDetailsStep> {
  final PropertyStructureService _structureService = PropertyStructureService();
  String _selectedGender = 'Anyone';
  String _numberingSystem = 'Numeric (101)';
  String? _propertyId;
  Timer? _numberingDebounce;

  // Expansion states
  final Set<String> _expandedFloors = {};
  final Set<String> _expandedRooms = {};

  final List<Map<String, dynamic>> _numberingStrategies = [
    {
      'label': 'Numeric (101)',
      'desc': '101, 102, 103...',
      'icon': Icons.pin_outlined,
    },
    {
      'label': 'Floor Based',
      'desc': 'F1-R1, F1-R2...',
      'icon': Icons.layers_outlined,
    },
    {
      'label': 'Alpha-Numeric',
      'desc': 'A1, A2, A3...',
      'icon': Icons.abc_rounded,
    },
    {
      'label': 'Custom',
      'desc': 'Your own rule',
      'icon': Icons.edit_note_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _propertyId = widget.initialData?['propertyId'];
    final details = widget.initialData?['propertyDetails'] ?? {};
    _selectedGender = details['gender'] ?? 'Anyone';
    _numberingSystem = details['numberingSystem'] ?? 'Numeric (101)';
  }

  @override
  void dispose() {
    _numberingDebounce?.cancel();
    super.dispose();
  }

  /// Saves the selected numbering system to Firestore (debounced 800ms).
  void _saveNumberingSystem(String system) {
    _numberingDebounce?.cancel();
    _numberingDebounce = Timer(const Duration(milliseconds: 800), () {
      if (_propertyId != null) {
        FirebaseFirestore.instance
            .collection('properties')
            .doc(_propertyId)
            .set({'numberingSystem': system}, SetOptions(merge: true));
      }
    });
  }

  Stream<PropertyStructureData> _getStructureStream() {
    if (_propertyId == null) {
      return Stream.value(
        PropertyStructureData(
          floors: [],
          rooms: [],
          beds: [],
          hasPendingWrites: false,
        ),
      );
    }

    final floorsStream =
        FirebaseFirestore.instance
            .collection('properties')
            .doc(_propertyId)
            .collection('floors')
            .orderBy('floorNumber')
            .snapshots();

    final roomsStream =
        FirebaseFirestore.instance
            .collection('properties')
            .doc(_propertyId)
            .collection('rooms')
            .snapshots();

    final bedsStream =
        FirebaseFirestore.instance
            .collection('properties')
            .doc(_propertyId)
            .collection('beds')
            .snapshots();

    return Rx.combineLatest3(floorsStream, roomsStream, bedsStream, (
      QuerySnapshot<Map<String, dynamic>> floorsSnap,
      QuerySnapshot<Map<String, dynamic>> roomsSnap,
      QuerySnapshot<Map<String, dynamic>> bedsSnap,
    ) {
      final floors = floorsSnap.docs.map((doc) => doc.data()).toList();
      final rooms = roomsSnap.docs.map((doc) => doc.data()).toList();
      final beds = bedsSnap.docs.map((doc) => doc.data()).toList();
      final hasPendingWrites =
          floorsSnap.metadata.hasPendingWrites ||
          roomsSnap.metadata.hasPendingWrites ||
          bedsSnap.metadata.hasPendingWrites;

      return PropertyStructureData(
        floors: floors,
        rooms: rooms,
        beds: beds,
        hasPendingWrites: hasPendingWrites,
      );
    });
  }

  // ==================== DIALOGS & SHEET WORKFLOWS ====================

  void _showAddFloorSheet([Map<String, dynamic>? existingFloor]) {
    final isEditing = existingFloor != null;
    final nameController = TextEditingController(
      text: existingFloor?['name'] ?? '',
    );
    final numberController = TextEditingController(
      text:
          existingFloor != null ? existingFloor['floorNumber'].toString() : '',
    );
    final descController = TextEditingController(
      text: existingFloor?['description'] ?? '',
    );
    String status = existingFloor?['status'] ?? 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isEditing ? 'Edit Floor' : 'Add Floor',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Floor Name',
                      hintText: 'e.g. Ground Floor, First Floor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Floor Number',
                      hintText: 'e.g. 0 for Ground, 1 for First',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Floor Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'Inactive',
                        child: Text('Inactive'),
                      ),
                      DropdownMenuItem(
                        value: 'Under Maintenance',
                        child: Text('Under Maintenance'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => status = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Floor Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            numberController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all required fields'),
                            ),
                          );
                          return;
                        }

                        final floorNum = int.tryParse(numberController.text);
                        if (floorNum == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Floor number must be a valid number',
                              ),
                            ),
                          );
                          return;
                        }

                        // Check for duplicate floor number
                        final isDuplicate = await _structureService
                            .isDuplicateFloorNumber(
                              _propertyId!,
                              floorNum,
                              excludeFloorId:
                                  isEditing ? existingFloor['id'] : null,
                            );
                        if (isDuplicate) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Floor number $floorNum already exists. Choose a different number.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }

                        final payload = {
                          if (isEditing) 'id': existingFloor['id'],
                          'name': nameController.text,
                          'floorNumber': floorNum,
                          'status': status,
                          'description': descController.text,
                        };

                        try {
                          if (isEditing) {
                            await _structureService.updateFloor(
                              _propertyId!,
                              existingFloor['id'],
                              payload,
                            );
                          } else {
                            await _structureService.createFloor(
                              _propertyId!,
                              payload,
                            );
                          }
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving floor: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Create Floor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddRoomSheet(
    Map<String, dynamic> floor,
    List<Map<String, dynamic>> roomsOnFloor,
    int totalRoomsCount,
  ) {
    final floorNumber = (floor['floorNumber'] as num).toInt();

    // Determine default room number based on selected numbering system.
    // Numeric: floor 0 (Ground) â†’ 101+, floor 1 â†’ 201+, etc.
    // Floor Based: F1-R1, F2-R1 (use floorNumber+1 as display level).
    // Alpha-Numeric: uses per-floor room count for suffix.
    String defaultRoomNumber = '';
    if (_numberingSystem == 'Numeric (101)') {
      final baseHundred = (floorNumber + 1) * 100; // Ground=100, 1st=200...
      defaultRoomNumber = '${baseHundred + roomsOnFloor.length + 1}';
    } else if (_numberingSystem == 'Floor Based') {
      defaultRoomNumber = 'F${floorNumber + 1}-R${roomsOnFloor.length + 1}';
    } else if (_numberingSystem == 'Alpha-Numeric') {
      // Use per-floor count so each floor starts at A1
      defaultRoomNumber = 'A${roomsOnFloor.length + 1}';
    }

    final numberController = TextEditingController(text: defaultRoomNumber);
    final areaController = TextEditingController();
    String roomType = 'single';
    int bedCount = 1;
    String status = 'Available';
    final List<String> roomAmenities = [];

    final List<String> amenitiesRepo = [
      'AC',
      'Attached Bath',
      'Balcony',
      'Study Table',
      'Cupboard',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Add Room to ${floor['name']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Room Number / Label',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: roomType,
                      decoration: const InputDecoration(
                        labelText: 'Room Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'single',
                          child: Text('Single Room'),
                        ),
                        DropdownMenuItem(
                          value: 'double',
                          child: Text('Double Sharing'),
                        ),
                        DropdownMenuItem(
                          value: 'triple',
                          child: Text('Triple Sharing'),
                        ),
                        DropdownMenuItem(
                          value: 'dormitory',
                          child: Text('Dormitory'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            roomType = val;
                            if (val == 'single') bedCount = 1;
                            if (val == 'double') bedCount = 2;
                            if (val == 'triple') bedCount = 3;
                            if (val == 'dormitory') bedCount = 4;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bed Count',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed:
                                  bedCount > 1
                                      ? () => setSheetState(() => bedCount--)
                                      : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$bedCount',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setSheetState(() => bedCount++),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: areaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Room Area (Sq. Ft. - Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Room Amenities',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          amenitiesRepo.map((amenity) {
                            final isSelected = roomAmenities.contains(amenity);
                            return FilterChip(
                              label: Text(amenity),
                              selected: isSelected,
                              selectedColor: AppTheme.successColor.withValues(
                                alpha: 0.15,
                              ),
                              checkmarkColor: AppTheme.successColor,
                              onSelected: (selected) {
                                setSheetState(() {
                                  if (selected) {
                                    roomAmenities.add(amenity);
                                  } else {
                                    roomAmenities.remove(amenity);
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Room Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Available',
                          child: Text('Available'),
                        ),
                        DropdownMenuItem(
                          value: 'Occupied',
                          child: Text('Occupied'),
                        ),
                        DropdownMenuItem(
                          value: 'Blocked',
                          child: Text('Blocked'),
                        ),
                        DropdownMenuItem(
                          value: 'Maintenance',
                          child: Text('Maintenance'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => status = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (numberController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a room number'),
                              ),
                            );
                            return;
                          }

                          // Check for duplicate room number
                          final isDuplicate = await _structureService
                              .isDuplicateRoomNumber(
                                _propertyId!,
                                numberController.text,
                              );
                          if (isDuplicate) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Room ${numberController.text} already exists. Choose a different number.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }

                          final payload = {
                            'roomNumber': numberController.text,
                            'roomType': roomType,
                            'occupancyType':
                                roomType == 'single'
                                    ? 'Single Occupancy'
                                    : '${roomType[0].toUpperCase()}${roomType.substring(1)} Sharing',
                            'floor': floorNumber,
                            'floorId': floor['id'],
                            'status': status,
                            'area': double.tryParse(areaController.text),
                            'amenities': roomAmenities,
                            'genderRestriction': _selectedGender, // Inherit property gender
                          };

                          try {
                            await _structureService.createRoomWithBeds(
                              propertyId: _propertyId!,
                              floorId: floor['id'],
                              roomData: payload,
                              bedCount: bedCount,
                              numberingSystem: _numberingSystem,
                            );
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error saving room: $e'),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Room',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== EDIT ROOM SHEET ====================

  void _showEditRoomSheet(Map<String, dynamic> room) {
    String roomType = room['roomType'] ?? 'single';
    String status = room['status'] ?? 'Available';
    final areaController = TextEditingController(
      text: room['area']?.toString() ?? '',
    );
    final List<String> roomAmenities = List<String>.from(
      room['amenities'] ?? [],
    );

    final List<String> amenitiesRepo = [
      'AC',
      'Attached Bath',
      'Balcony',
      'Study Table',
      'Cupboard',
      'WiFi',
      'Geyser',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Edit Room ${room['roomNumber']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: roomType,
                      decoration: const InputDecoration(
                        labelText: 'Room Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'single',
                          child: Text('Single Room'),
                        ),
                        DropdownMenuItem(
                          value: 'double',
                          child: Text('Double Sharing'),
                        ),
                        DropdownMenuItem(
                          value: 'triple',
                          child: Text('Triple Sharing'),
                        ),
                        DropdownMenuItem(
                          value: 'dormitory',
                          child: Text('Dormitory'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => roomType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: areaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Room Area (Sq. Ft. â€” Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Room Amenities',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          amenitiesRepo.map((amenity) {
                            final isSelected = roomAmenities.contains(amenity);
                            return FilterChip(
                              label: Text(amenity),
                              selected: isSelected,
                              selectedColor: AppTheme.successColor.withValues(
                                alpha: 0.15,
                              ),
                              checkmarkColor: AppTheme.successColor,
                              onSelected: (selected) {
                                setSheetState(() {
                                  if (selected) {
                                    roomAmenities.add(amenity);
                                  } else {
                                    roomAmenities.remove(amenity);
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Room Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Available',
                          child: Text('Available'),
                        ),
                        DropdownMenuItem(
                          value: 'Occupied',
                          child: Text('Occupied'),
                        ),
                        DropdownMenuItem(
                          value: 'Blocked',
                          child: Text('Blocked'),
                        ),
                        DropdownMenuItem(
                          value: 'Maintenance',
                          child: Text('Maintenance'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final occupancyType =
                              roomType == 'single'
                                  ? 'Single Occupancy'
                                  : '${roomType[0].toUpperCase()}${roomType.substring(1)} Sharing';

                          try {
                            await _structureService
                                .updateRoomDetails(_propertyId!, room['id'], {
                                  'roomType': roomType,
                                  'occupancyType': occupancyType,
                                  'area': double.tryParse(areaController.text),
                                  'amenities': roomAmenities,
                                  'status': status,
                                });
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating room: \$e'),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== WIDGET BUILDERS ====================

  Widget _buildPropertyOverview(PropertyStructureData data) {
    final int floorsCount = data.floors.length;
    final int roomsCount = data.rooms.length;
    final int bedsCount = data.beds.length;
    final int totalCapacity = data.beds.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.domain_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Property Overview',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Outfit',
                ),
              ),
              if (data.hasPendingWrites) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.cloud_queue_rounded,
                        color: Colors.orange,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Syncing...',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem(
                'Floors',
                '$floorsCount',
                Icons.layers_rounded,
              ),
              _buildOverviewItem(
                'Rooms',
                '$roomsCount',
                Icons.door_front_door_rounded,
              ),
              _buildOverviewItem('Beds', '$bedsCount', Icons.king_bed_rounded),
              _buildOverviewItem(
                'Total Capacity',
                '$totalCapacity',
                Icons.people_alt_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Counts update automatically as you add floors, rooms and beds.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberingSystemSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Room Numbering System',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose how you want to number your rooms and beds.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: _numberingStrategies.length,
          itemBuilder: (context, index) {
            final strategy = _numberingStrategies[index];
            final isSelected = _numberingSystem == strategy['label'];
            return InkWell(
              onTap: () {
                setState(() => _numberingSystem = strategy['label']);
                _saveNumberingSystem(strategy['label']);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppTheme.successColor.withValues(alpha: 0.05)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppTheme.successColor
                            : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            strategy['icon'],
                            color:
                                isSelected
                                    ? AppTheme.successColor
                                    : AppTheme.textMutedColor,
                            size: 18,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strategy['label'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                              color:
                                  isSelected
                                      ? AppTheme.successColor
                                      : AppTheme.textDarkColor,
                            ),
                          ),
                          Text(
                            strategy['desc'],
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 12,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              'This will be applied to new rooms only. Existing rooms will not change.',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloorCard(
    Map<String, dynamic> floor,
    List<Map<String, dynamic>> rooms,
    List<Map<String, dynamic>> beds,
    int totalRooms,
  ) {
    final floorId = floor['id'];
    final isExpanded = _expandedFloors.contains(floorId);

    final floorRooms = rooms.where((r) => r['floorId'] == floorId).toList();
    final floorBeds = beds.where((b) => b['floorId'] == floorId).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              floor['name'] ?? 'Floor',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'Outfit',
              ),
            ),
            subtitle: Text(
              'Rooms: ${floorRooms.length}  |  Beds: ${floorBeds.length}  |  Status: ${floor['status'] ?? 'Active'}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: Colors.grey.shade600,
                  onPressed: () => _showAddFloorSheet(floor),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: Colors.red.shade400,
                  onPressed: () async {
                    final canDelete = await _structureService.canDeleteFloor(
                      _propertyId!,
                      floorId,
                    );
                    if (!canDelete) {
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Cannot Delete Floor'),
                                content: const Text(
                                  'This floor contains active residents. Please transfer or check out residents before deleting.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                        );
                      }
                      return;
                    }

                    if (mounted) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Delete Floor'),
                              content: Text(
                                'Are you sure you want to delete ${floor['name']}? This will also delete all rooms and beds on this floor.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        await _structureService.deleteFloor(
                          _propertyId!,
                          floorId,
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedFloors.remove(floorId);
                      } else {
                        _expandedFloors.add(floorId);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50.withValues(alpha: 0.5),
              child: Column(
                // stretch so OutlinedButton.icon fills full card width
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        () => _showAddRoomSheet(floor, floorRooms, totalRooms),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Room'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                      side: const BorderSide(color: AppTheme.successColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (floorRooms.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No rooms on this floor yet.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...floorRooms.map((room) => _buildRoomItem(room, beds)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomItem(
    Map<String, dynamic> room,
    List<Map<String, dynamic>> beds,
  ) {
    final roomId = room['id'];
    final isExpanded = _expandedRooms.contains(roomId);
    final roomBeds = beds.where((b) => b['roomId'] == roomId).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text(
              'Room ${room['roomNumber']} (${room['occupancyType']})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Beds: ${roomBeds.length}  |  Status: ${room['status']}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit room button
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  color: Colors.grey.shade600,
                  onPressed: () => _showEditRoomSheet(room),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  color: Colors.red.shade400,
                  onPressed: () async {
                    final canDelete = await _structureService.canDeleteRoom(
                      _propertyId!,
                      roomId,
                    );
                    if (!canDelete) {
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Cannot Delete Room'),
                                content: const Text(
                                  'This room contains occupied beds. Please checkout or transfer residents first.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                        );
                      }
                      return;
                    }

                    if (mounted) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Delete Room'),
                              content: Text(
                                'Are you sure you want to delete Room ${room['roomNumber']}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        await _structureService.deleteRoom(
                          _propertyId!,
                          roomId,
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedRooms.remove(roomId);
                      } else {
                        _expandedRooms.add(roomId);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children:
                    roomBeds.map((bed) => _buildBedRow(bed, room)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBedRow(Map<String, dynamic> bed, Map<String, dynamic> room) {
    final status = bed['status'] ?? 'available';
    final residentId = bed['currentResidentId'];

    Color statusColor = Colors.green;
    if (status == 'occupied') statusColor = Colors.blue;
    if (status == 'reserved' || status == 'booked') statusColor = Colors.orange;
    if (status == 'maintenance') statusColor = Colors.red;
    if (status == 'blocked') statusColor = Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.king_bed_outlined, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bed ${bed['bedNumber']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (residentId != null)
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(residentId)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text(
                          'Occupied',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        );
                      }
                      final bData = snapshot.data!.data()!;
                      final rName =
                          bData['tenantDetails']?[0]?['name'] ?? 'Resident';
                      return Text(
                        'Resident: $rName (${bData['status'] ?? 'Active'})',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  )
                else
                  Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(color: statusColor, fontSize: 10),
                  ),
              ],
            ),
          ),
          if (residentId == null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 16),
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(
                      value: 'available',
                      child: Text('Mark Available'),
                    ),
                    PopupMenuItem(
                      value: 'maintenance',
                      child: Text('Mark Maintenance'),
                    ),
                    PopupMenuItem(value: 'blocked', child: Text('Block Bed')),
                  ],
              onSelected: (val) async {
                await _structureService.updateBedStatus(
                  propertyId: _propertyId!,
                  roomId: room['id'],
                  bedId: bed['id'],
                  newStatus: val,
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PropertyStructureData>(
      stream: _getStructureStream(),
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            PropertyStructureData(
              floors: [],
              rooms: [],
              beds: [],
              hasPendingWrites: false,
            );

        return SizedBox.expand(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gender Preference *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDarkColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomToggleButtons(
                      options: const ['Men', 'Women', 'Anyone'],
                      selectedOption: _selectedGender,
                      onOptionSelected:
                          (val) => setState(() => _selectedGender = val),
                      activeColor: AppTheme.successColor,
                    ),
                    const SizedBox(height: 24),
                    _buildPropertyOverview(data),
                    const SizedBox(height: 24),
                    _buildNumberingSystemSelector(),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Floors',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showAddFloorSheet(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Floor'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.successColor,
                            side: const BorderSide(
                              color: AppTheme.successColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (data.floors.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.domain_disabled_rounded,
                              color: Colors.grey.shade300,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No floors added yet',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add your first floor to start adding rooms and beds.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...data.floors.map(
                        (floor) => _buildFloorCard(
                          floor,
                          data.rooms,
                          data.beds,
                          data.rooms.length,
                        ),
                      ),
                  ],
                ),
              ),

              // Sticky Summary Footer
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildFooterStat('Floors', '${data.floors.length}'),
                            _buildFooterStat('Rooms', '${data.rooms.length}'),
                            _buildFooterStat('Beds', '${data.beds.length}'),
                            _buildFooterStat('Capacity', '${data.beds.length}'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          widget.onContinue({
                            'propertyDetails': {
                              'gender': _selectedGender,
                              'numberingSystem': _numberingSystem,
                              'floorsCount': data.floors.length,
                              'singleRooms':
                                  data.rooms
                                      .where((r) => r['roomType'] == 'single')
                                      .length,
                              'doubleRooms':
                                  data.rooms
                                      .where((r) => r['roomType'] == 'double')
                                      .length,
                              'tripleRooms':
                                  data.rooms
                                      .where((r) => r['roomType'] == 'triple')
                                      .length,
                              'dormitoryBeds':
                                  data.beds.where((b) {
                                    final room = data.rooms.firstWhere(
                                      (r) => r['id'] == b['roomId'],
                                      orElse: () => <String, dynamic>{},
                                    );
                                    return room['roomType'] == 'dormitory';
                                  }).length,
                              'totalCapacity': data.beds.length,
                            },
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
