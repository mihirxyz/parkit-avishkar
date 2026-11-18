import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkit_mobile/core/theme/app_colors.dart';
import 'package:parkit_mobile/main.dart';
import 'package:parkit_mobile/models/parking_zone.dart';
import 'package:parkit_mobile/utils/zone_name_helper.dart';
import 'package:parkit_mobile/widgets/cards/metric_stat_card.dart';
import 'package:parkit_mobile/widgets/cards/parking_option_card.dart';
import 'package:parkit_mobile/widgets/charts/occupancy_radial_gauge.dart';

void main() {
  testWidgets('ParkItApp loads with Home and Zone Map bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const ParkItApp());

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Zone Map'), findsOneWidget);
  });

  testWidgets('MetricStatCard renders title, value, and accent icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricStatCard(
            title: 'Free spots',
            value: '42',
            icon: Icons.local_parking_rounded,
          ),
        ),
      ),
    );

    expect(find.text('Free spots'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.byIcon(Icons.local_parking_rounded), findsOneWidget);
  });

  testWidgets('OccupancyRadialGauge renders occupancy percentage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OccupancyRadialGauge(
            occupancyRate: 0.75,
            parked: 15,
            total: 20,
          ),
        ),
      ),
    );

    expect(find.text('75%'), findsOneWidget);
    expect(find.text('15 / 20'), findsOneWidget);
    expect(find.text('Occupied'), findsOneWidget);
  });

  testWidgets('ParkingOptionCard renders Recommended badge, occupancy bar, and plain status word', (WidgetTester tester) async {
    const zone = ParkingZone(
      zoneId: 'zone_1_1',
      name: 'Central Lot',
      zoneType: 'structured',
      latMin: 18.519,
      latMax: 18.520,
      lonMin: 73.856,
      lonMax: 73.857,
      totalCapacity: 15,
      parkedVehicles: 0,
      movingVehicles: 0,
      totalVehicles: 0,
      occupancyRate: 0.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParkingOptionCard(
            zone: zone,
            isRecommended: true,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('Central Lot'), findsOneWidget);
    expect(find.text('15 free'), findsOneWidget);
    expect(find.text('Plenty free'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  test('AppColors.statusLabelForOccupancy matches thresholds and ZoneNameHelper provides short names', () {
    expect(AppColors.statusLabelForOccupancy(0.25), 'Plenty free');
    expect(AppColors.statusLabelForOccupancy(0.65), 'Filling up');
    expect(AppColors.statusLabelForOccupancy(0.85), 'Almost full');

    expect(ZoneNameHelper.getShortName('zone_1_1', 'Central Lot'), 'Central Lot');
    expect(ZoneNameHelper.getShortName('zone_0_1', 'North Curbside'), 'North Curb');
    expect(ZoneNameHelper.getShortName('zone_9_9', 'Unstructured South Roadside'), 'South Rd');
  });
}

