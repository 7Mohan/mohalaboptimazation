import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mohalab_optimization/core/theme/app_theme.dart';
import 'package:mohalab_optimization/core/theme/tokens/app_sizes.dart';
import 'package:mohalab_optimization/shared/widgets/shared_widgets.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Moha Lab Design System - Component Tests', () {
    testWidgets('MohaStatusBadge renders with label and semantics', (tester) async {
      await tester.pumpWidget(
        _wrap(const MohaStatusBadge(type: MohaStatusType.safe)),
      );

      expect(find.text('Safe'), findsOneWidget);
      expect(find.byType(MohaStatusBadge), findsOneWidget);
    });

    testWidgets('MohaStatusBadge renders Shizuku tier badge', (tester) async {
      await tester.pumpWidget(
        _wrap(const MohaStatusBadge(type: MohaStatusType.shizuku)),
      );

      expect(find.text('Shizuku'), findsOneWidget);
    });

    testWidgets('MohaActionButton meets minimum touch target and handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(
          MohaActionButton(
            label: 'Optimize Memory',
            onPressed: () => tapped = true,
          ),
        ),
      );

      final buttonFinder = find.byType(MohaActionButton);
      expect(buttonFinder, findsOneWidget);

      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));

      await tester.tap(buttonFinder);
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('MohaSecondaryButton handles tap and displays label', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(
          MohaSecondaryButton(
            label: 'Cancel',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.byType(MohaSecondaryButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('MohaMetricCard renders value, label, and status badge', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MohaMetricCard(
            label: 'RAM Available',
            value: '3.8',
            unit: 'GB',
            statusType: MohaStatusType.optimal,
          ),
        ),
      );

      expect(find.text('RAM Available'), findsOneWidget);
      expect(find.text('3.8'), findsOneWidget);
      expect(find.text('GB'), findsOneWidget);
      expect(find.text('Optimal'), findsOneWidget);
    });

    testWidgets('MohaGameCard renders title, package name, and status', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MohaGameCard(
            title: 'Genshin Impact',
            packageName: 'com.miHoYo.GenshinImpact',
            statusLabel: 'Safe Profile',
          ),
        ),
      );

      expect(find.text('Genshin Impact'), findsOneWidget);
      expect(find.text('com.miHoYo.GenshinImpact'), findsOneWidget);
      expect(find.text('Safe Profile'), findsOneWidget);
    });

    testWidgets('MohaSettingsSwitchTile toggles value on tap', (tester) async {
      bool currentVal = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              MohaSettingsSwitchTile(
                title: 'Do Not Disturb',
                value: currentVal,
                onChanged: (newVal) => setState(() => currentVal = newVal),
              ),
            );
          },
        ),
      );

      expect(find.text('Do Not Disturb'), findsOneWidget);
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      await tester.tap(find.byType(MohaSettingsSwitchTile));
      await tester.pump();
      expect(currentVal, isTrue);
    });
  });
}
