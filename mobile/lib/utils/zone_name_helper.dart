import 'package:url_launcher/url_launcher.dart';

/// Helper to convert technical zone IDs and raw backend strings into
/// plain-language names, compact map labels (never truncated), and Google Maps links.
class ZoneNameHelper {
  const ZoneNameHelper._();

  /// Map of zone_id patterns to friendly display names (plain language)
  static const Map<String, String> _zoneDisplayNames = {
    'zone_0_0': 'North Lot',
    'zone_0_1': 'North Curbside',
    'zone_0_2': 'East Lot',
    'zone_1_0': 'West Roadside',
    'zone_1_1': 'Central Lot',
    'zone_1_2': 'East Roadside',
    'zone_2_0': 'South Road West',
    'zone_2_1': 'South Curbside',
    'zone_2_2': 'South Road East',
    'zone_1_3': 'West Market Street',
    'zone_2_3': 'Central Business District',
    'zone_3_1': 'East Riverside',
    'zone_3_2': 'North Parking Lot',
    'zone_3_3': 'East Commercial Area',
    'zone_4_1': 'South Residential',
    'zone_4_2': 'South Shopping Plaza',
    'zone_4_3': 'South Industrial Area',
  };

  /// Compact map cell labels guaranteed to fit without truncation
  static const Map<String, String> _shortZoneNames = {
    'zone_0_0': 'North Lot',
    'zone_0_1': 'North Curb',
    'zone_0_2': 'East Lot',
    'zone_1_0': 'West Rd',
    'zone_1_1': 'Central Lot',
    'zone_1_2': 'East Rd',
    'zone_2_0': 'South Rd W',
    'zone_2_1': 'South Curb',
    'zone_2_2': 'South Rd E',
    'zone_1_3': 'Market St',
    'zone_2_3': 'Central Biz',
    'zone_3_1': 'Riverside',
    'zone_3_2': 'North Lot',
    'zone_3_3': 'East Area',
    'zone_4_1': 'South Res',
    'zone_4_2': 'South Plaza',
    'zone_4_3': 'South Ind',
  };

  /// Strips technical words like "Structured" or "Unstructured" from a raw name.
  static String _cleanRawName(String raw) {
    return raw
        .replaceAll(RegExp(r'\bUnstructured\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bStructured\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Get a friendly plain-language name for cards, sheets, and headers.
  static String getFriendlyName(String zoneId, String? originalName) {
    if (_zoneDisplayNames.containsKey(zoneId)) {
      return _zoneDisplayNames[zoneId]!;
    }

    if (originalName != null && originalName.isNotEmpty) {
      final cleaned = _cleanRawName(originalName);
      if (cleaned.isNotEmpty) return cleaned;
    }

    if (zoneId.startsWith('zone_')) {
      final parts = zoneId.substring(5).split('_');
      if (parts.length == 2) {
        return 'Area ${parts[0]}-${parts[1]}';
      }
    }

    return zoneId;
  }

  /// Get a compact short name ("South Rd", "North Curb", "Central Lot") for map grid cells.
  static String getShortName(String zoneId, String? originalName) {
    if (_shortZoneNames.containsKey(zoneId)) {
      return _shortZoneNames[zoneId]!;
    }

    if (originalName != null && originalName.isNotEmpty) {
      var s = _cleanRawName(originalName);
      s = s
          .replaceAll('Roadside West', 'Rd W')
          .replaceAll('Roadside East', 'Rd E')
          .replaceAll('Roadside', 'Rd')
          .replaceAll('Road', 'Rd')
          .replaceAll('Curbside', 'Curb')
          .replaceAll('Parking Lot', 'Lot')
          .replaceAll('Street', 'St')
          .trim();
      if (s.isNotEmpty) return s;
    }

    return getFriendlyName(zoneId, originalName);
  }

  /// Plain-language zone type ("Parking lot" vs "Street side")
  static String getZoneTypeLabel(bool isStructured) {
    return isStructured ? 'Parking lot' : 'Street side';
  }

  /// Opens Google Maps directions to the given zone coordinates.
  static Future<bool> openGoogleMaps({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
