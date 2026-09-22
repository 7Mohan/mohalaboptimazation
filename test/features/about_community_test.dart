import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohalab_optimization/core/config/about_config.dart';
import 'package:mohalab_optimization/core/services/url_launcher_service.dart';
import 'package:mohalab_optimization/core/theme/app_theme.dart';
import 'package:mohalab_optimization/domain/entities/app_info.dart';
import 'package:mohalab_optimization/features/about/presentation/providers/about_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mohalab_optimization/features/about/presentation/screens/about_screen.dart';
import 'package:mohalab_optimization/features/about/presentation/widgets/acknowledgements_sheet.dart';
import 'package:mohalab_optimization/features/about/presentation/widgets/community_card.dart';
import 'package:mohalab_optimization/features/about/presentation/widgets/legal_document_dialog.dart';
import 'package:mohalab_optimization/features/about/presentation/widgets/ownership_notice_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  const testAppInfo = AppInfo(
    appName: 'Moha Lab Optimization',
    packageName: 'com.mohalab.optimization',
    version: '1.2.0',
    buildNumber: '42',
  );

  Widget buildTestApp(
    Widget child, {
    AboutConfig config = const AboutConfig(),
  }) {
    return ProviderScope(
      overrides: [
        aboutConfigProvider.overrideWithValue(config),
        appInfoProvider.overrideWith((ref) => Future.value(testAppInfo)),
        urlLauncherServiceProvider.overrideWithValue(
          const UrlLauncherService(enablePlatformChannel: false),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: child,
      ),
    );
  }

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.mohalab.optimization/device_info'),
      (call) async {
        if (call.method == 'openUrl') return false; // Trigger clipboard fallback
        return null;
      },
    );
  });

  group('AboutConfig model & validation', () {
    test('default configuration has valid URLs and non-empty metadata', () {
      const config = AboutConfig();

      expect(config.brandName, equals('MOHA LAB'));
      expect(config.appName, equals('Moha Lab Optimization'));
      expect(config.developerName, isNotEmpty);
      expect(config.contactEmail, contains('@'));
      expect(config.copyrightDisplay, contains('Moha Lab'));
      expect(config.ownershipNotice, contains('intellectual property'));

      // Validate default URLs
      expect(AboutConfig.isValidUrl(config.websiteUrl), isTrue);
      expect(AboutConfig.isValidUrl(config.telegramCommunityUrl), isTrue);
      expect(AboutConfig.isValidUrl(config.privacyPolicyUrl), isTrue);
      expect(AboutConfig.isValidUrl(config.termsOfServiceUrl), isTrue);
    });

    test('isValidUrl correctly handles null, blank, and malformed strings', () {
      expect(AboutConfig.isValidUrl(null), isFalse);
      expect(AboutConfig.isValidUrl(''), isFalse);
      expect(AboutConfig.isValidUrl('   '), isFalse);
      expect(AboutConfig.isValidUrl('not-a-url'), isFalse);
      expect(AboutConfig.isValidUrl('ftp://unsupported.domain'), isFalse);

      expect(AboutConfig.isValidUrl('https://t.me/mohalab'), isTrue);
      expect(AboutConfig.isValidUrl('http://mohalab.dev'), isTrue);
      expect(AboutConfig.isValidUrl('mailto:support@mohalab.dev'), isTrue);
      expect(AboutConfig.isValidUrl('tg://resolve?domain=mohalab'), isTrue);
    });

    test('copyWith properly updates specific configuration fields', () {
      const original = AboutConfig();
      final updated = original.copyWith(
        developerName: 'Custom Dev Team',
        telegramCommunityUrl: 'https://t.me/custom_community',
      );

      expect(updated.developerName, equals('Custom Dev Team'));
      expect(updated.telegramCommunityUrl, equals('https://t.me/custom_community'));
      // Unchanged fields remain intact
      expect(updated.brandName, equals(original.brandName));
      expect(updated.privacyPolicyUrl, equals(original.privacyPolicyUrl));
    });
  });

  group('UrlLauncherService tests', () {
    testWidgets('launchOrCopy handles invalid/missing URL without throwing', (tester) async {
      const service = UrlLauncherService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => service.launchOrCopy(
                  context,
                  '',
                  title: 'Missing Link',
                ),
                child: const Text('Launch Empty'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch Empty'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Missing Link is not currently configured.'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('launchOrCopy with valid URL copies to clipboard in test environment', (tester) async {
      const service = UrlLauncherService(enablePlatformChannel: false);
      late BuildContext buildContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                buildContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = await service.launchOrCopy(
        buildContext,
        'https://mohalab.dev',
        title: 'Website',
      );

      expect(result.isSuccessful, isTrue);
      expect(result.status, equals(UrlLaunchStatus.copiedToClipboard));
      await tester.pumpAndSettle();
    });
  });

  group('CommunityCard widget tests', () {
    testWidgets('renders community title, handle, badge, and action button', (tester) async {
      await tester.pumpWidget(buildTestApp(const Scaffold(body: CommunityCard())));
      await tester.pumpAndSettle();

      // New dual-tile card shows 'Official Communities' header + both platform tiles
      expect(find.text('Official Communities'), findsOneWidget);
      expect(find.text('Telegram Lab'), findsOneWidget);
      expect(find.text('TikTok Showcase'), findsOneWidget);
      // Verified badge replaces 'Official'
      expect(find.text('Verified'), findsOneWidget);
      // Short 'Join' button (Telegram) and 'Follow' button (TikTok)
      expect(find.text('Join'), findsOneWidget);
      expect(find.text('Follow'), findsOneWidget);
      // Two copy icons — one per platform
      expect(find.byIcon(Icons.copy_rounded), findsNWidgets(2));
    });

    testWidgets('tapping Join button executes launch or clipboard action', (tester) async {
      await tester.pumpWidget(buildTestApp(const Scaffold(body: CommunityCard())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();

      // The button should still be present after tapping
      expect(find.text('Join'), findsOneWidget);
    });

    testWidgets('tapping Telegram copy icon shows snackbar feedback', (tester) async {
      await tester.pumpWidget(buildTestApp(const Scaffold(body: CommunityCard())));
      await tester.pumpAndSettle();

      // Tap the first copy icon (Telegram row)
      await tester.tap(find.byIcon(Icons.copy_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Telegram link copied!'), findsOneWidget);
    });

    testWidgets('missing Telegram URL does not crash the card', (tester) async {
      const emptyConfig = AboutConfig(
        telegramCommunityUrl: '',
        telegramCommunityHandle: '',
      );

      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(body: CommunityCard()),
          config: emptyConfig,
        ),
      );
      await tester.pumpAndSettle();

      // Card still renders header and Telegram tile
      expect(find.text('Official Communities'), findsOneWidget);
      expect(find.text('Telegram Lab'), findsOneWidget);
      // Join button is disabled (onPressed is null) — widget doesn't crash
    });
  });

  group('LegalDocumentDialog tests', () {
    testWidgets('renders Privacy Policy content with local-first guarantee', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(
            body: LegalDocumentDialog(type: LegalDocumentType.privacyPolicy),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('1. Local-Only Storage'), findsOneWidget);
      expect(find.text('2. Third-Party Analytics & Tracking'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('renders Terms of Service content with safe usage disclosures', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(
            body: LegalDocumentDialog(type: LegalDocumentType.termsOfService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('1. Acceptance of Terms'), findsOneWidget);
      expect(find.text('2. User Discretion and System Tweaks'), findsOneWidget);
      expect(find.text('3. Disclaimers and Limitations of Warranty'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('AcknowledgementsSheet & OwnershipNoticeCard tests', () {
    testWidgets('AcknowledgementsSheet displays open-source packages and licenses', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(body: AcknowledgementsSheet()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open-Source Licenses'), findsOneWidget);
      expect(find.text('Flutter SDK'), findsOneWidget);
      expect(find.text('Flutter Riverpod'), findsOneWidget);
      expect(find.text('GoRouter'), findsOneWidget);
      expect(find.text('View Full License Texts'), findsOneWidget);
    });

    testWidgets('OwnershipNoticeCard renders copyright and original content notice', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(body: OwnershipNoticeCard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OWNERSHIP & COPYRIGHT'), findsOneWidget);
      expect(find.textContaining('All rights reserved.'), findsWidgets);
      expect(find.textContaining('intellectual property of Moha Lab'), findsOneWidget);
    });
  });

  group('AboutScreen full integration tests', () {
    testWidgets('renders complete polished product About screen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(const AboutScreen()));
      await tester.pumpAndSettle();

      // Brand & Product Identity
      expect(find.text('About'), findsOneWidget);
      expect(find.text('MOHA LAB'), findsOneWidget);
      expect(find.text('Optimization'), findsOneWidget);
      expect(find.text('Android Utility Edition'), findsOneWidget);

      // Quick links
      expect(find.text('Website'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);

      // Community section — new dual-tile card
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Telegram Lab'), findsOneWidget);

      // App telemetry
      expect(find.text('APP INFO'), findsOneWidget);
      expect(find.text('1.2.0'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);

      // Developer
      expect(find.text('DEVELOPER & CONTACT'), findsOneWidget);
      expect(find.text('Moha Lab Team'), findsOneWidget);

      // Legal & Acknowledgements
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Open-Source Licenses'), findsOneWidget);
      expect(find.text('ACKNOWLEDGEMENTS'), findsOneWidget);
      expect(find.text('OWNERSHIP & COPYRIGHT'), findsOneWidget);
    });

    testWidgets('missing/empty configuration does not break the About screen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const emptyConfig = AboutConfig(
        websiteUrl: '',
        telegramCommunityUrl: '',
        telegramCommunityHandle: '',
        privacyPolicyUrl: '',
        termsOfServiceUrl: '',
        githubUrl: '',
      );

      await tester.pumpWidget(
        buildTestApp(
          const AboutScreen(),
          config: emptyConfig,
        ),
      );
      await tester.pumpAndSettle();

      // Screen renders without crashing even when URLs are empty
      expect(find.text('MOHA LAB'), findsOneWidget);
      expect(find.text('Optimization'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      // New dual-tile CommunityCard renders header and both platform tiles
      expect(find.text('Official Communities'), findsOneWidget);
      expect(find.text('Telegram Lab'), findsOneWidget);
    });

    testWidgets('tapping Privacy Policy opens in-app legal dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(const AboutScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.text('1. Local-Only Storage'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('1. Local-Only Storage'), findsNothing);
    });
  });
}
