import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/bed_model.dart';
import 'package:triangle_home/models/room_model.dart';
import 'package:triangle_home/theme/app_theme.dart';

class BedSelectionSheet extends StatefulWidget {
  final String propertyId;
  final Function(RoomModel, BedModel) onSelected;

  const BedSelectionSheet({
    super.key,
    required this.propertyId,
    required this.onSelected,
  });

  @override
  State<BedSelectionSheet> createState() => _BedSelectionSheetState();
}

class _BedSelectionSheetState extends State<BedSelectionSheet> {
  RoomModel? _selectedRoom;
  BedModel? _selectedBed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(child: _buildRoomList()),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(Icons.bed_rounded, color: AppTheme.successColor, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Your Bed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              Text(
                'Choose a specific room and bed',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('properties')
              .doc(widget.propertyId)
              .collection('rooms')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms =
            snapshot.data!.docs
                .map((doc) => RoomModel.fromFirestore(doc))
                .toList();

        if (rooms.isEmpty) {
          return Center(
            child: Text(
              'No rooms available',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: rooms.length,
          itemBuilder:
              (context, index) => _RoomSelectionCard(
                propertyId: widget.propertyId,
                room: rooms[index],
                isSelected: _selectedRoom?.id == rooms[index].id,
                selectedBedId: _selectedBed?.id,
                onRoomTap:
                    (room) => setState(() {
                      _selectedRoom = room;
                      _selectedBed = null;
                    }),
                onBedTap: (bed) => setState(() => _selectedBed = bed),
              ),
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    final bool canConfirm = _selectedRoom != null && _selectedBed != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              canConfirm
                  ? () => widget.onSelected(_selectedRoom!, _selectedBed!)
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Confirm Selection',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomSelectionCard extends StatelessWidget {
  final String propertyId;
  final RoomModel room;
  final bool isSelected;
  final String? selectedBedId;
  final Function(RoomModel) onRoomTap;
  final Function(BedModel) onBedTap;

  const _RoomSelectionCard({
    required this.propertyId,
    required this.room,
    required this.isSelected,
    this.selectedBedId,
    required this.onRoomTap,
    required this.onBedTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color:
            isSelected
                ? AppTheme.successColor.withValues(alpha: 0.02)
                : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.successColor : const Color(0xFFF1F5F9),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onRoomTap(room),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildRoomIcon(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${room.roomNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${room.roomType.name.toUpperCase()} • Floor ${room.floor}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${room.baseRent.toInt()}/mo',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[const Divider(height: 1), _buildBedGrid()],
          ],
        ),
      ),
    );
  }

  Widget _buildRoomIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            isSelected
                ? AppTheme.successColor.withValues(alpha: 0.1)
                : const Color(0xFFF8FAFC),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.meeting_room_rounded,
        color: isSelected ? AppTheme.successColor : Colors.grey[400],
        size: 20,
      ),
    );
  }

  Widget _buildBedGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('properties')
              .doc(propertyId)
              .collection('rooms')
              .doc(room.id)
              .collection('beds')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);

        final beds =
            snapshot.data!.docs
                .map((doc) => BedModel.fromFirestore(doc))
                .toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                beds
                    .map(
                      (bed) => _BedChip(
                        bed: bed,
                        isSelected: selectedBedId == bed.id,
                        onTap: () => onBedTap(bed),
                      ),
                    )
                    .toList(),
          ),
        );
      },
    );
  }
}

class _BedChip extends StatelessWidget {
  final BedModel bed;
  final bool isSelected;
  final VoidCallback onTap;

  const _BedChip({
    required this.bed,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = bed.status == BedStatus.available;

    return InkWell(
      onTap: isAvailable ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.5,
        child: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppTheme.successColor
                    : (isAvailable ? Colors.white : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppTheme.successColor : const Color(0xFFF1F5F9),
            ),
          ),
          child: Column(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : (isAvailable ? Icons.bed_outlined : Icons.block_flipped),
                size: 16,
                color:
                    isSelected
                        ? Colors.white
                        : (isAvailable ? AppTheme.successColor : Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                bed.bedNumber,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color:
                      isSelected
                          ? Colors.white
                          : (isAvailable
                              ? AppTheme.textDarkColor
                              : Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
