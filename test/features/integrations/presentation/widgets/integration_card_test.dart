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
}
