import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/parking_zone.dart';
import '../models/vehicle_reading.dart';
import '../providers/parking_provider.dart';
import '../utils/zone_name_helper.dart';

/// Modal bottom sheet enabling a live parking demo update from the Home card.
class VehicleSimulatorSheet extends StatefulWidget {
  const VehicleSimulatorSheet({super.key});

  @override
  State<VehicleSimulatorSheet> createState() => _VehicleSimulatorSheetState();
}

class _VehicleSimulatorSheetState extends State<VehicleSimulatorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _speedController;
  late TextEditingController _rssiController;
  VehicleReading? _latestResult;
  bool _submissionFailed = false;
  String _selectedPreset = 'parked';

  @override
  void initState() {
    super.initState();
    final randomId = 'CAR_${100 + math.Random().nextInt(900)}';
    _idController = TextEditingController(text: randomId);
    _latController = TextEditingController(text: '18.5204');
    _lonController = TextEditingController(text: '73.8567');
    _speedController = TextEditingController(text: '0.0');
    _rssiController = TextEditingController(text: '-48.0');
  }

  @override
  void dispose() {
    _idController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _speedController.dispose();
    _rssiController.dispose();
    super.dispose();
  }

  void _applyPreset(String name) {
    _selectedPreset = name;
    if (name == 'parked') {
      _speedController.text = '0.0';
      _rssiController.text = '-48.0';
    } else {
      _speedController.text = '8.5';
      _rssiController.text = '-88.0';
    }
    setState(() {});
  }

  void _selectZoneCoordinates(ParkingZone zone) {
    _latController.text = zone.center.latitude.toStringAsFixed(5);
    _lonController.text = zone.center.longitude.toStringAsFixed(5);
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submissionFailed = false);

    final reading = VehicleReading(
      vehicleId: _idController.text.trim(),
      timestamp: DateTime.now(),
      lat: double.tryParse(_latController.text.trim()) ?? 18.5204,
      lon: double.tryParse(_lonController.text.trim()) ?? 73.8567,
      gpsSpeed: double.tryParse(_speedController.text.trim()),
      bleRssi: double.tryParse(_rssiController.text.trim()),
      predictedState: 'moving',
    );
    final result =
        await context.read<ParkingProvider>().submitTelemetry(reading);
    if (mounted) {
      setState(() {
        _latestResult = result;
        _submissionFailed = result == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParkingProvider>();
    final quickZones = provider.zones.take(4).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
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
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Try a Live Parking Update',
                      style: AppTypography.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Simulate a car parking or driving by to watch spot counts update live.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPresetButton(
                      label: 'Car just parked',
                      icon: Icons.local_parking_rounded,
                      isSelected: _selectedPreset == 'parked',
                      onTap: () => _applyPreset('parked'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPresetButton(
                      label: 'Car driving by',
                      icon: Icons.directions_car_rounded,
                      isSelected: _selectedPreset == 'moving',
                      onTap: () => _applyPreset('moving'),
                    ),
                  ),
                ],
              ),
              if (quickZones.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Pick an area:', style: AppTypography.labelSmall),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: quickZones.map((z) {
                      final shortLabel = ZoneNameHelper.getShortName(
                        z.zoneId,
                        z.name,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          height: 40,
                          child: ActionChip(
                            label: Text(
                              shortLabel,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppColors.surfaceElevated,
                            onPressed: () => _selectZoneCoordinates(z),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _idController,
                decoration: inputDec('Car label', Icons.badge_rounded),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter a car label' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: TextInputType.number,
                      decoration:
                          inputDec('Latitude', Icons.location_on_rounded),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lonController,
                      keyboardType: TextInputType.number,
                      decoration:
                          inputDec('Longitude', Icons.location_on_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _speedController,
                      keyboardType: TextInputType.number,
                      decoration: inputDec('Speed (m/s)', Icons.speed_rounded),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rssiController,
                      keyboardType: TextInputType.number,
                      decoration: inputDec(
                        'Bluetooth signal',
                        Icons.bluetooth_rounded,
                      ),
                    ),
                  ),
                ],
              ),
              if (_submissionFailed) ...[
                const SizedBox(height: 16),
                _buildErrorBanner(),
              ],
              if (_latestResult != null) ...[
                const SizedBox(height: 16),
                buildResultBadge(_latestResult!),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.isSubmittingTelemetry ? null : _submit,
                  icon: provider.isSubmittingTelemetry
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    provider.isSubmittingTelemetry
                        ? 'Updating live map...'
                        : 'Send live update',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.occupancyHigh.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.occupancyHigh.withAlpha(90)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.occupancyHigh,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not send update. Please check that the server is running.',
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildResultBadge(VehicleReading r) {
    final color = r.isParked ? AppColors.stateParked : AppColors.stateMoving;
    final stateLabel = r.isParked ? 'Parked' : 'Driving by';
    final friendlyZone = r.zoneId != null
        ? ZoneNameHelper.getFriendlyName(r.zoneId!, null)
        : 'Outside mapped area';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(
            r.isParked
                ? Icons.local_parking_rounded
                : Icons.directions_car_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detected as: $stateLabel',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Area: $friendlyZone • Live spot counts updated',
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
      prefixIcon: Icon(icon, size: 16, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}

