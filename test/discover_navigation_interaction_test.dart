import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/main.dart';
import 'package:zoology_app/screens/species_detail_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Tapping TODAY IN THE FIELD card navigates to SpeciesDetailPage', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const KashmirZoologyApp());
    await tester.pumpAndSettle();

    expect(find.text('TODAY IN THE FIELD'), findsOneWidget);

    final openBtn = find.text('Open field note  →');
    expect(openBtn, findsOneWidget);
    await tester.tap(openBtn);
    await tester.pumpAndSettle();

    expect(find.byType(SpeciesDetailPage), findsOneWidget);
  });

  testWidgets('Tapping FIELD GUIDE ENTRIES stat chip switches to Field Guide tab', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const KashmirZoologyApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bestiary-tab-0')), findsOneWidget);

    final fieldGuideStat = find.text('FIELD GUIDE ENTRIES');
    expect(fieldGuideStat, findsOneWidget);
    await tester.tap(fieldGuideStat);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bestiary-tab-2')), findsOneWidget);
    expect(find.text('Species guide'), findsOneWidget);
  });

  testWidgets('Tapping THREATENED FAUNA stat chip switches to Field Guide filtered to threatened species', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const KashmirZoologyApp());
    await tester.pumpAndSettle();

    final threatenedStat = find.text('THREATENED FAUNA');
    expect(threatenedStat, findsOneWidget);
    await tester.tap(threatenedStat);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bestiary-tab-2')), findsOneWidget);
    expect(find.text('Threatened only ✕'), findsOneWidget);

    // Tapping the clear button resets the filter
    await tester.tap(find.text('Threatened only ✕'));
    await tester.pumpAndSettle();
    expect(find.text('Threatened only ✕'), findsNothing);
  });

  testWidgets('Tapping YOUR OBSERVATIONS stat chip switches to Journal tab', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const KashmirZoologyApp());
    await tester.pumpAndSettle();

    final observationsStat = find.text('YOUR OBSERVATIONS');
    expect(observationsStat, findsOneWidget);
    await tester.tap(observationsStat);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bestiary-tab-1')), findsOneWidget);
  });
}
