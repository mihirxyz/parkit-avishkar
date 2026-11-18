import 'package:flutter/foundation.dart';
import '../models/parking_zone.dart';
import '../models/vehicle_reading.dart';
import '../services/api_service.dart';

enum ParkingStateStatus { initial, loading, success, error }

/// State provider for live spatial parking zones and vehicle telemetry.
class ParkingProvider extends ChangeNotifier {
  final ApiService _apiService;

  ParkingStateStatus _status = ParkingStateStatus.initial;
  List<ParkingZone> _zones = [];
  ParkingZone? _selectedZone;
  String? _errorMessage;
  bool _isSubmittingTelemetry = false;
  bool _isLoadingDetail = false;
  String? _detailErrorMessage;
  DateTime? _lastUpdatedAt;

  // Selected filter (all, structured, unstructured)
  String _filterType = 'all';

  ParkingProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  ParkingStateStatus get status => _status;
  List<ParkingZone> get zones => _zones;
  ParkingZone? get selectedZone => _selectedZone;
  String? get errorMessage => _errorMessage;
  bool get isSubmittingTelemetry => _isSubmittingTelemetry;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailErrorMessage => _detailErrorMessage;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;
  String get filterType => _filterType;

  bool get isLoading => _status == ParkingStateStatus.loading;
  bool get hasError => _status == ParkingStateStatus.error;

  /// Zone with the most free spots (tie-broken by lowest occupancy rate).
  /// Returns null if no zones are loaded or all zones have 0 available spots.
  ParkingZone? get bestZone {
    if (_zones.isEmpty) return null;
    final candidates = _zones.where((z) => z.availableSpots > 0).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final bySpots = b.availableSpots.compareTo(a.availableSpots);
      if (bySpots != 0) return bySpots;
      return a.occupancyRate.compareTo(b.occupancyRate);
    });
    return candidates.first;
  }

  /// Best zone within the currently filtered list (for Zone Map "Best pick" badge).
  ParkingZone? get bestFilteredZone {
    final list = filteredZones;
    if (list.isEmpty) return null;
    final candidates = list.where((z) => z.availableSpots > 0).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final bySpots = b.availableSpots.compareTo(a.availableSpots);
      if (bySpots != 0) return bySpots;
      return a.occupancyRate.compareTo(b.occupancyRate);
    });
    return candidates.first;
  }

  /// Human-friendly relative timestamp label for the Home hero
  String get updatedTimestampLabel {
    if (_lastUpdatedAt == null) return 'Updated just now';
    final diff = DateTime.now().difference(_lastUpdatedAt!);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes == 1) return 'Updated 1 min ago';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} mins ago';
    return 'Updated recently';
  }

  /// Filtered list based on current filter type
  List<ParkingZone> get filteredZones {
    if (_filterType == 'structured') {
      return _zones.where((z) => z.isStructured).toList();
    } else if (_filterType == 'unstructured') {
      return _zones.where((z) => !z.isStructured).toList();
    }
    return _zones;
  }

  // Summary Metrics across all zones
  int get totalParked => _zones.fold(0, (sum, z) => sum + z.parkedVehicles);
  int get totalMoving => _zones.fold(0, (sum, z) => sum + z.movingVehicles);
  int get totalCapacity => _zones.fold(0, (sum, z) => sum + z.totalCapacity);
  int get totalAvailable => (totalCapacity - totalParked).clamp(0, totalCapacity);
  double get overallOccupancyRate =>
      totalCapacity > 0 ? (totalParked / totalCapacity).clamp(0.0, 1.0) : 0.0;

  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  void selectZone(ParkingZone? zone) {
    _selectedZone = zone;
    notifyListeners();
  }

  /// Initial load or manual refresh of all grid zones
  Future<void> fetchZones({bool silent = false}) async {
    if (!silent) {
      _status = ParkingStateStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final fetchedZones = await _apiService.fetchGridZones();
      _zones = fetchedZones;
      _status = ParkingStateStatus.success;
      _errorMessage = null;
      _lastUpdatedAt = DateTime.now();

      // Update selectedZone if it is currently open
      if (_selectedZone != null) {
        final match = _zones.where((z) => z.zoneId == _selectedZone!.zoneId);
        if (match.isNotEmpty) {
          _selectedZone = match.first;
        }
      }
    } catch (e) {
      _status = ParkingStateStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Load detail for a single zone (including telemetry history)
  Future<void> loadZoneDetail(String zoneId) async {
    _isLoadingDetail = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final detail = await _apiService.fetchZoneDetail(zoneId);
      _selectedZone = detail;
      _detailErrorMessage = null;
    } catch (e) {
      _detailErrorMessage = e.toString();
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Submit a simulated or real vehicle telemetry reading
  Future<VehicleReading?> submitTelemetry(VehicleReading reading) async {
    _isSubmittingTelemetry = true;
    notifyListeners();

    try {
      final result = await _apiService.submitVehicleReading(reading);
      // Immediately refresh zones to reflect updated occupancy
      await fetchZones(silent: true);
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isSubmittingTelemetry = false;
      notifyListeners();
    }
  }
}
