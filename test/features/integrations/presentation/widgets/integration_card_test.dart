import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/integrations/domain/models/integration.dart';
import 'package:pm_master_v2/features/integrations/presentation/widgets/integration_card.dart';

void main() {
  group('IntegrationCard', () {
    testWidgets('displays integration name and description', (tester) async {
      final integration = Integration(
        id: 'int-1',
        type: IntegrationType.fireflies,
        name: 'Fireflies.ai',
        description: 'Automatic meeting transcription',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Fireflies.ai'), findsOneWidget);
      expect(find.text('Automatic meeting transcription'), findsOneWidget);
    });

    testWidgets('displays "Not Connected" status badge for unconnected integration', (tester) async {
      final integration = Integration(
        id: 'int-2',
        type: IntegrationType.slack,
        name: 'Slack',
        description: 'Team communication',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Not Connected'), findsOneWidget);
      expect(find.byIcon(Icons.link_off_rounded), findsOneWidget);
    });

    testWidgets('displays "Connected" status badge for connected integration', (tester) async {
      final integration = Integration(
        id: 'int-3',
        type: IntegrationType.teams,
        name: 'Microsoft Teams',
        description: 'Video meetings',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
        lastSyncAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Connected'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('displays "Connecting" status badge for connecting integration', (tester) async {
      final integration = Integration(
        id: 'int-4',
        type: IntegrationType.zoom,
        name: 'Zoom',
        description: 'Video conferencing',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connecting,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Connecting'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('displays "Error" status badge for error integration', (tester) async {
      final integration = Integration(
        id: 'int-5',
        type: IntegrationType.fireflies,
        name: 'Fireflies',
        description: 'Transcription',
        iconUrl: 'icon.png',
        status: IntegrationStatus.error,
        errorMessage: 'Connection failed',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Error'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('displays "Connect" button for disconnected integration', (tester) async {
      final integration = Integration(
        id: 'int-6',
        type: IntegrationType.transcription,
        name: 'Transcription',
        description: 'Audio transcription',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Connect'), findsOneWidget);
      expect(find.byIcon(Icons.add_link_rounded), findsOneWidget);
    });

    testWidgets('displays "Configure" button for connected integration', (tester) async {
      final integration = Integration(
        id: 'int-7',
        type: IntegrationType.fireflies,
        name: 'Fireflies',
        description: 'Transcription',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
        lastSyncAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Configure'), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('displays sync time for connected integration', (tester) async {
      final lastSync = DateTime.now().subtract(const Duration(hours: 3));
      final integration = Integration(
        id: 'int-8',
        type: IntegrationType.slack,
        name: 'Slack',
        description: 'Communication',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
        lastSyncAt: lastSync,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
      expect(find.textContaining('Synced'), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      bool tapped = false;
      final integration = Integration(
        id: 'int-9',
        type: IntegrationType.teams,
        name: 'Teams',
        description: 'Video',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap the card itself by tapping on the integration name
      await tester.tap(find.text('Teams'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('calls onTap when "Connect" button is tapped', (tester) async {
      bool tapped = false;
      final integration = Integration(
        id: 'int-10',
        type: IntegrationType.zoom,
        name: 'Zoom',
        description: 'Video',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('calls onTap when "Configure" button is tapped', (tester) async {
      bool tapped = false;
      final integration = Integration(
        id: 'int-11',
        type: IntegrationType.fireflies,
        name: 'Fireflies',
        description: 'Transcription',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
        lastSyncAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Configure'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('displays options menu button for connected integration', (tester) async {
      final integration = Integration(
        id: 'int-12',
        type: IntegrationType.slack,
        name: 'Slack',
        description: 'Communication',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });

    testWidgets('shows options menu when options button is tapped', (tester) async {
      final integration = Integration(
        id: 'int-13',
        type: IntegrationType.teams,
        name: 'Teams',
        description: 'Video',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Configure'), findsAtLeastNWidgets(1));
      expect(find.text('Sync Now'), findsOneWidget);
      expect(find.text('Disconnect'), findsOneWidget);
    });

    testWidgets('displays correct icon for fireflies integration', (tester) async {
      final integration = Integration(
        id: 'int-14',
        type: IntegrationType.fireflies,
        name: 'Fireflies',
        description: 'Transcription',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('displays correct icon for slack integration', (tester) async {
      final integration = Integration(
        id: 'int-15',
        type: IntegrationType.slack,
        name: 'Slack',
        description: 'Communication',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
    });

    testWidgets('displays correct icon for teams integration', (tester) async {
      final integration = Integration(
        id: 'int-16',
        type: IntegrationType.teams,
        name: 'Teams',
        description: 'Video',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
    });

    testWidgets('displays correct icon for zoom integration', (tester) async {
      final integration = Integration(
        id: 'int-17',
        type: IntegrationType.zoom,
        name: 'Zoom',
        description: 'Video',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
    });

    testWidgets('displays correct icon for transcription integration', (tester) async {
      final integration = Integration(
        id: 'int-18',
        type: IntegrationType.transcription,
        name: 'Transcription',
        description: 'Audio',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.transcribe), findsOneWidget);
    });

    testWidgets('displays correct icon for aiBrain integration', (tester) async {
      final integration = Integration(
        id: 'int-19',
        type: IntegrationType.aiBrain,
        name: 'AI Brain',
        description: 'AI Processing',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });

    testWidgets('truncates long description text', (tester) async {
      final integration = Integration(
        id: 'int-20',
        type: IntegrationType.fireflies,
        name: 'Fireflies',
        description: 'This is a very long description that should be truncated to prevent overflow issues in the UI. It contains multiple sentences to test the ellipsis behavior.',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(
        find.text(integration.description),
      );
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('shows snackbar when "Sync Now" is tapped', (tester) async {
      final integration = Integration(
        id: 'int-21',
        type: IntegrationType.fireflies,
        name: 'Fireflies.ai',
        description: 'Transcription',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      // Open options menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Tap Sync Now
      await tester.tap(find.text('Sync Now'));
      await tester.pumpAndSettle();

      expect(find.text('Syncing Fireflies.ai...'), findsOneWidget);
    });

    testWidgets('shows disconnect dialog when "Disconnect" is tapped', (tester) async {
      final integration = Integration(
        id: 'int-22',
        type: IntegrationType.slack,
        name: 'Slack',
        description: 'Communication',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      // Open options menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Tap Disconnect
      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();

      expect(find.text('Disconnect Slack?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Disconnect'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows snackbar when disconnect is confirmed', (tester) async {
      final integration = Integration(
        id: 'int-23',
        type: IntegrationType.teams,
        name: 'Microsoft Teams',
        description: 'Video',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      // Open options menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Tap Disconnect
      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();

      // Confirm disconnect (find the FilledButton with Disconnect text)
      await tester.tap(find.widgetWithText(FilledButton, 'Disconnect'));
      await tester.pumpAndSettle();

      expect(find.text('Disconnected from Microsoft Teams'), findsOneWidget);
    });

    testWidgets('does not show options button for disconnected integration', (tester) async {
      final integration = Integration(
        id: 'int-24',
        type: IntegrationType.zoom,
        name: 'Zoom',
        description: 'Video',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntegrationCard(
              integration: integration,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    });
  });

  group('IntegrationCard - Mobile Layout', () {
    Widget createMobileTestWidget(Integration integration) {
      return MediaQuery(
        data: const MediaQueryData(
          size: Size(375, 812), // iPhone X dimensions
        ),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: IntegrationCard(
                integration: integration,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
    }

    Widget createDesktopTestWidget(Integration integration) {
      return MediaQuery(
        data: const MediaQueryData(
          size: Size(1920, 1080),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: IntegrationCard(
                integration: integration,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('displays correctly on mobile screen without overflow', (tester) async {
      final integration = Integration(
        id: 'mobile-1',
        type: IntegrationType.fireflies,
        name: 'Fireflies.ai Integration',
        description: 'Automatic meeting transcription and note-taking service that records calls',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
        lastSyncAt: DateTime.now(),
      );

      await tester.pumpWidget(createMobileTestWidget(integration));
      await tester.pumpAndSettle();

      // Verify card renders without overflow
      expect(tester.takeException(), isNull);

      // Verify content is displayed
      expect(find.text('Fireflies.ai Integration'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('truncates long text on mobile to prevent overflow', (tester) async {
      final integration = Integration(
        id: 'mobile-2',
        type: IntegrationType.slack,
        name: 'Slack Integration with Very Long Name That Could Overflow',
        description: 'This is an extremely long description that contains multiple sentences and should be truncated to prevent any overflow issues on mobile devices. It has even more text to ensure truncation happens.',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(createMobileTestWidget(integration));
      await tester.pumpAndSettle();

      // Verify no overflow
      expect(tester.takeException(), isNull);

      // Verify name is truncated
      final nameText = tester.widget<Text>(
        find.text('Slack Integration with Very Long Name That Could Overflow'),
      );
      expect(nameText.maxLines, 1);
      expect(nameText.overflow, TextOverflow.ellipsis);

      // Verify description is truncated
      final descriptionFinder = find.textContaining('This is an extremely long description');
      expect(descriptionFinder, findsOneWidget);

      final descriptionText = tester.widget<Text>(descriptionFinder);
      expect(descriptionText.maxLines, 2);
      expect(descriptionText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('uses mobile spacing on small screens', (tester) async {
      final integration = Integration(
        id: 'mobile-3',
        type: IntegrationType.teams,
        name: 'Teams',
        description: 'Video meetings',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
        lastSyncAt: DateTime.now(),
      );

      await tester.pumpWidget(createMobileTestWidget(integration));
      await tester.pumpAndSettle();

      // Find the SizedBox that adjusts spacing based on screen size
      // Mobile should have smaller spacing
      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsAtLeastNWidgets(1));

      // Verify no rendering issues
      expect(tester.takeException(), isNull);
    });

    testWidgets('footer buttons fit properly on mobile', (tester) async {
      final integration = Integration(
        id: 'mobile-4',
        type: IntegrationType.fireflies,
        name: 'Fireflies',
        description: 'Transcription',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
        lastSyncAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      await tester.pumpWidget(createMobileTestWidget(integration));
      await tester.pumpAndSettle();

      // Verify Configure button is present and properly sized
      expect(find.text('Configure'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Synced'), findsOneWidget);

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('connect button displays properly on mobile', (tester) async {
      final integration = Integration(
        id: 'mobile-5',
        type: IntegrationType.zoom,
        name: 'Zoom',
        description: 'Video conferencing',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(createMobileTestWidget(integration));
      await tester.pumpAndSettle();

      // Verify Connect button is present
      expect(find.text('Connect'), findsOneWidget);
      expect(find.byIcon(Icons.add_link_rounded), findsOneWidget);

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles different screen widths responsively', (tester) async {
      final integration = Integration(
        id: 'mobile-6',
        type: IntegrationType.transcription,
        name: 'Transcription Service',
        description: 'Audio transcription',
        iconUrl: 'icon.png',
        status: IntegrationStatus.connected,
      );

      // Test on very small mobile (320px)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(320, 568)),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: IntegrationCard(
                  integration: integration,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Test on tablet (768px)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(768, 1024)),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: IntegrationCard(
                  integration: integration,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Test on desktop (1920px)
      await tester.pumpWidget(createDesktopTestWidget(integration));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('card height is constrained and uses Spacer correctly', (tester) async {
      final integration = Integration(
        id: 'mobile-7',
        type: IntegrationType.aiBrain,
        name: 'AI Brain',
        description: 'Short description',
        iconUrl: 'icon.png',
        status: IntegrationStatus.notConnected,
      );

      await tester.pumpWidget(createMobileTestWidget(integration));
      await tester.pumpAndSettle();

      // Verify Spacer is used to push footer to bottom
      expect(find.byType(Spacer), findsAtLeastNWidgets(1));

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('icon and badge do not overflow on mobile', (tester) async {
      final integration = Integration(
        id: 'mobile-8',
        type: IntegrationType.fireflies,
        name: 'Very Long Integration Name That Should Truncate',
        description: 'Description text',
        iconUrl: 'icon.png',
        status: IntegrationStatus.error,
        errorMessage: 'Connection timeout error message that is quite long',
      );

      await tester.pumpWidget(createMobileTestWidget(integration));
      await tester.pumpAndSettle();

      // Verify icon is present
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

      // Verify status badge is present
      expect(find.text('Error'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);

      // Verify no overflow despite long content
      expect(tester.takeException(), isNull);
    });

    testWidgets('multiple cards in grid do not overflow on mobile', (tester) async {
      final integrations = [
        Integration(
          id: 'grid-1',
          type: IntegrationType.fireflies,
          name: 'Fireflies.ai',
          description: 'Automatic meeting transcription',
          iconUrl: 'icon.png',
          status: IntegrationStatus.connected,
        ),
        Integration(
          id: 'grid-2',
          type: IntegrationType.slack,
          name: 'Slack',
          description: 'Team communication platform',
          iconUrl: 'icon.png',
          status: IntegrationStatus.notConnected,
        ),
      ];

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(375, 812)),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: integrations
                      .map((integration) => SizedBox(
                            height: 200,
                            child: IntegrationCard(
                              integration: integration,
                              onTap: () {},
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all cards are rendered
      expect(find.text('Fireflies.ai'), findsOneWidget);
      expect(find.text('Slack'), findsOneWidget);

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });
  });
}
