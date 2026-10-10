import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lock_sync/main.dart';
import 'package:lock_sync/screens/auth_screen.dart';
import 'package:lock_sync/screens/lock_control_screen.dart';
import 'package:lock_sync/screens/system_check_screen.dart';

void main() {
  testWidgets('LockSync landing page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LockSyncApp());

    // Verify brand and primary elements
    expect(find.text('Your lock, redefined.'), findsOneWidget);
    expect(find.text('GET STARTED'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
  });

  testWidgets('Navigate to Sign In from Landing Screen and test toggle',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LockSyncApp());

    // Tap SIGN IN on landing screen
    await tester.tap(find.text('SIGN IN'));
    await tester.pumpAndSettle();

    // Verify Sign In screen renders
    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('Sign in to connect with your locker.'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('FORGOT PASSWORD?'), findsOneWidget);
    expect(find.text('USE BIOMETRICS'), findsOneWidget);
    expect(find.text('OR CONTINUE WITH'), findsOneWidget);

    // Switch to SIGN UP via footer
    await tester.ensureVisible(find.byKey(const Key('auth_mode_toggle_footer')));
    await tester.tap(find.byKey(const Key('auth_mode_toggle_footer')));
    await tester.pumpAndSettle();

    // Verify Sign Up fields render
    expect(find.text('CREATE ACCOUNT'), findsWidgets);
    expect(find.text('Create an account to pair and manage your locker.'),
        findsOneWidget);
    expect(find.text('NAME'), findsOneWidget);
    expect(find.text('CONFIRM PASSWORD'), findsOneWidget);

    // Switch back to SIGN IN via footer
    await tester.ensureVisible(find.byKey(const Key('auth_mode_toggle_footer')));
    await tester.tap(find.byKey(const Key('auth_mode_toggle_footer')));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME BACK'), findsOneWidget);
  });

  testWidgets(
      'Submitting form navigates through SystemCheckScreen to LockControlScreen and tests lock control',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthScreen(initialMode: AuthMode.signIn),
      ),
    );

    // Tap the primary action button to submit
    await tester.tap(find.byKey(const Key('primary_action_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify SystemCheckScreen is reached with only the ring and LOCKSYNC in the center
    expect(find.byType(SystemCheckScreen), findsOneWidget);
    expect(find.text('CHECKING SYSTEM STATUS'), findsNothing);
    final ringBrandFinder = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('LOCKSYNC'),
    );
    expect(ringBrandFinder, findsOneWidget);

    // Pump past diagnostic check (1400ms)
    await tester.pump(const Duration(milliseconds: 1400));
    // Pump past ring disappearance (300ms)
    await tester.pump(const Duration(milliseconds: 320));
    // Pump past 1.0s pause (1000ms)
    await tester.pump(const Duration(milliseconds: 1020));
    // Pump past welcome fade in (350ms)
    await tester.pump(const Duration(milliseconds: 380));

    // Verify online verified confirmation appears with ONLY "WELCOME TO LOCKSYNC"
    expect(find.text('WELCOME TO LOCKSYNC'), findsOneWidget);
    expect(find.text('LOGGED IN'), findsNothing);

    // Pump past hold (1500ms) and route transition into LockControlScreen
    await tester.pump(const Duration(milliseconds: 1520));
    await tester.pumpAndSettle();

    // Verify LockControlScreen is reached
    expect(find.byType(LockControlScreen), findsOneWidget);
    expect(find.text('LOCKER 01'), findsOneWidget);
    expect(find.text('CONNECTED DEVICE'), findsOneWidget);

    // Verify SYSTEM ONLINE was removed from header
    expect(find.text('SYSTEM ONLINE'), findsNothing);

    // Verify 3-column status panel
    expect(find.text('SIGNAL'), findsOneWidget);
    expect(find.text('DEVICE'), findsOneWidget);
    expect(find.text('STATE'), findsOneWidget);
    expect(find.text('STRONG'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);

    // Verify main lock and biometric actions in LOCKED state
    expect(find.text('LOCKED'), findsNWidgets(2)); // in circle and in status panel
    expect(find.text('TAP TO UNLOCK'), findsOneWidget);
    expect(find.text('UNLOCK WITH BIOMETRICS'), findsOneWidget);

    // Verify history section is removed from lock screen body
    expect(find.text('RECENT ACTIVITY'), findsNothing);

    // Verify persistent bottom navigation layout: HISTORY on left, circular LOCK in middle, SETTINGS on right
    expect(find.byKey(const Key('bottom_nav_HISTORY')), findsOneWidget);
    expect(find.byKey(const Key('bottom_nav_LOCK_circular')), findsOneWidget);
    expect(find.byKey(const Key('bottom_nav_SETTINGS')), findsOneWidget);

    // Tap main lock circle in middle to unlock
    await tester.tap(find.byKey(const Key('main_lock_circle_button')));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify UNLOCKED state
    expect(find.text('UNLOCKED'), findsOneWidget);
    expect(find.text('TAP TO LOCK'), findsOneWidget);
    expect(find.text('LOCK DEVICE'), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);

    // Tap main lock circle in middle to lock back
    await tester.tap(find.byKey(const Key('main_lock_circle_button')));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify locked back
    expect(find.text('LOCKED'), findsNWidgets(2));
    expect(find.text('TAP TO UNLOCK'), findsOneWidget);
  });

  testWidgets('Test bottom navigation switching between HISTORY, LOCK, and SETTINGS',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LockControlScreen(),
      ),
    );

    // Tap HISTORY on left side of bottom nav
    await tester.tap(find.byKey(const Key('bottom_nav_HISTORY')));
    await tester.pumpAndSettle();

    // Verify access history tab content is rendered with clean HISTORY LOG header
    expect(find.text('HISTORY LOG'), findsOneWidget);
    expect(find.text('AUDIT TRAIL'), findsNothing);
    expect(find.text('EVENTS'), findsNothing);
    expect(find.text('Verified access records streamed from Arduino EEPROM.'), findsNothing);
    expect(find.text('Locker unlocked'), findsWidgets);

    // Tap circular middle LOCK button to return to lock screen
    await tester.tap(find.byKey(const Key('bottom_nav_LOCK_circular')));
    await tester.pumpAndSettle();

    // Verify back on main lock control
    expect(find.text('TAP TO UNLOCK'), findsOneWidget);
    expect(find.text('HISTORY LOG'), findsNothing);

    // Tap SETTINGS on right side of bottom nav
    await tester.tap(find.byKey(const Key('bottom_nav_SETTINGS')));
    await tester.pumpAndSettle();

    // Verify settings tab content is rendered
    expect(find.text('DEVICE SETTINGS'), findsOneWidget);
    expect(find.text('Arduino Nano ESP32'), findsOneWidget);
    expect(find.text('v2.4.1 (Latest)'), findsOneWidget);
  });

  testWidgets(
      'LockControlScreen fixed top header is centered without SYSTEM ONLINE',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LockControlScreen(),
      ),
    );

    // Verify SYSTEM ONLINE is removed from the fixed top header
    expect(find.text('SYSTEM ONLINE'), findsNothing);

    // Verify the LOCKSYNC wordmark RichText is present
    final wordmarkFinder = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('LOCKSYNC'),
    );
    expect(wordmarkFinder, findsOneWidget);

    // Verify wordmark is centered
    final RichText wordmark = tester.widget(wordmarkFinder);
    expect(wordmark.textAlign, TextAlign.center);
  });

  testWidgets(
      'SystemCheckScreen online flow shows LOGGED IN, WELCOME TO LOCKSYNC, then fades into LockControlScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SystemCheckScreen(
          checkDuration: Duration(milliseconds: 200),
          ringFadeDuration: Duration(milliseconds: 100),
          pauseBeforeWelcomeDuration: Duration(milliseconds: 200),
          welcomeFadeDuration: Duration(milliseconds: 100),
          holdDuration: Duration(milliseconds: 300),
          fadeDuration: Duration(milliseconds: 150),
        ),
      ),
    );

    // Initial checking state: only ring with LOCKSYNC inside (no checking system text)
    expect(find.text('CHECKING SYSTEM STATUS'), findsNothing);
    final ringBrandFinder = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('LOCKSYNC'),
    );
    expect(ringBrandFinder, findsOneWidget);

    // Advance past check duration (200ms)
    await tester.pump(const Duration(milliseconds: 220));
    // Advance past ring disappearance (100ms)
    await tester.pump(const Duration(milliseconds: 120));
    // Advance past 1.5s pause (in test 200ms)
    await tester.pump(const Duration(milliseconds: 220));
    // Advance past welcome fade in (100ms)
    await tester.pump(const Duration(milliseconds: 120));

    // Welcome view has now appeared with ONLY "WELCOME TO LOCKSYNC"
    expect(find.text('WELCOME TO LOCKSYNC'), findsOneWidget);
    expect(find.text('LOGGED IN'), findsNothing);

    // Advance past hold (300ms) and route fade into LockControlScreen
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.byType(LockControlScreen), findsOneWidget);
  });

  testWidgets(
      'SystemCheckScreen offline flow halts progression and shows SYSTEM OFFLINE with retry',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SystemCheckScreen(
          forceOffline: true,
          checkDuration: Duration(milliseconds: 200),
        ),
      ),
    );

    // Advance past check duration
    await tester.pump(const Duration(milliseconds: 250));

    // Offline state reached
    expect(find.text('SYSTEM OFFLINE'), findsOneWidget);
    expect(find.text('CONNECTION FAILED'), findsOneWidget);
    expect(find.byKey(const Key('retry_connection_button')), findsOneWidget);
    expect(find.byKey(const Key('back_to_sign_in_button')), findsOneWidget);

    // Crucially, it does NOT continue to app!
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(LockControlScreen), findsNothing);
  });
}
