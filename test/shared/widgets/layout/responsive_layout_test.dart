import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/shared/widgets/layout/responsive_layout.dart';

void main() {
  group('ResponsiveLayout', () {
    const mobileWidget = Text('Mobile Layout');
    const tabletWidget = Text('Tablet Layout');
    const desktopWidget = Text('Desktop Layout');
    const largeWidget = Text('Large Screen Layout');

    group('Mobile Layout', () {
      testWidgets('displays mobile widget on mobile screen', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: mobileWidget,
                desktop: desktopWidget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mobile Layout'), findsOneWidget);
        expect(find.text('Desktop Layout'), findsNothing);
      });

      testWidgets('displays mobile widget on small mobile screen (320px)', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: mobileWidget,
                desktop: desktopWidget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mobile Layout'), findsOneWidget);
      });
    });

    group('Tablet Layout', () {
      testWidgets('displays tablet widget on tablet screen', (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: mobileWidget,
                tablet: tabletWidget,
                desktop: desktopWidget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tablet Layout'), findsOneWidget);
        expect(find.text('Mobile Layout'), findsNothing);
        expect(find.text('Desktop Layout'), findsNothing);
      });

      testWidgets('falls back to desktop widget when tablet is not provided', (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: mobileWidget,
                desktop: desktopWidget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Desktop Layout'), findsOneWidget);
        expect(find.text('Mobile Layout'), findsNothing);
      });
    });

    group('Desktop Layout', () {
      testWidgets('displays desktop widget on desktop screen', (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: mobileWidget,
                desktop: desktopWidget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Desktop Layout'), findsOneWidget);
        expect(find.text('Mobile Layout'), findsNothing);
      });

      testWidgets('displays desktop widget on standard HD screen (1920x1080)', (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: mobileWidget,
                desktop: desktopWidget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Desktop Layout'), findsOneWidget);
      });
    });

    group('Large Screen Layout', () {
      testWidgets('displays large widget on ultra-wide screen', (tester) async {
        tester.view.physicalSize = const Size(2560, 1440);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: mobileWidget,
                desktop: desktopWidget,
                large: largeWidget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Large Screen Layout'), findsOneWidget);
        expect(find.text('Desktop Layout'), findsNothing);
        expect(find.text('Mobile Layout'), findsNothing);
      });

      testWidgets('falls back to desktop when large is not provided', (tester) async {
        tester.view.physicalSize = const Size(2560, 1440);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: mobileWidget,
                desktop: desktopWidget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Desktop Layout'), findsOneWidget);
        expect(find.text('Mobile Layout'), findsNothing);
      });
    });

    group('Responsive Behavior', () {
      testWidgets('switches from mobile to tablet on resize', (tester) async {
        // Start with mobile size
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: mobileWidget,
                tablet: tabletWidget,
                desktop: desktopWidget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mobile Layout'), findsOneWidget);

        // Resize to tablet
        tester.view.physicalSize = const Size(800, 1200);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Tablet Layout'), findsOneWidget);
        expect(find.text('Mobile Layout'), findsNothing);

        // Clean up
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      testWidgets('switches from tablet to desktop on resize', (tester) async {
        // Start with tablet size
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: mobileWidget,
                tablet: tabletWidget,
                desktop: desktopWidget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tablet Layout'), findsOneWidget);

        // Resize to desktop
        tester.view.physicalSize = const Size(1280, 800);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Desktop Layout'), findsOneWidget);
        expect(find.text('Tablet Layout'), findsNothing);

        // Clean up
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      testWidgets('switches from desktop to large screen on resize', (tester) async {
        // Start with desktop size
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: mobileWidget,
                desktop: desktopWidget,
                large: largeWidget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Desktop Layout'), findsOneWidget);

        // Resize to large screen
        tester.view.physicalSize = const Size(2560, 1440);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Large Screen Layout'), findsOneWidget);
        expect(find.text('Desktop Layout'), findsNothing);

        // Clean up
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    group('Edge Cases', () {
      testWidgets('handles only required parameters', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: mobileWidget,
                desktop: desktopWidget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mobile Layout'), findsOneWidget);
      });

      testWidgets('handles complex widgets as children', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: Column(
                  children: const [
                    Text('Mobile'),
                    Icon(Icons.phone_android),
                  ],
                ),
                desktop: Row(
                  children: const [
                    Text('Desktop'),
                    Icon(Icons.computer),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mobile'), findsOneWidget);
        expect(find.byIcon(Icons.phone_android), findsOneWidget);
        expect(find.text('Desktop'), findsNothing);
        expect(find.byIcon(Icons.computer), findsNothing);
      });
    });
  });
}
