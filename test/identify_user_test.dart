import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:smirror_frontend/src/app.dart';
import 'package:smirror_frontend/src/bloc/view_cubit.dart';
import 'package:smirror_frontend/src/systems/backend_socket.dart';
import 'package:smirror_wire/generated/back_front_back_front_generated.dart' as b;
import 'package:smirror_wire/generated/view_view_structure_generated.dart' as v_struct;
import 'package:smirror_wire/generated/dashboard_dashboard_structure_generated.dart' as d;

class FakeBackendSocket implements BackendSocket {
  final tokenCtrl = StreamController<b.GetToken>.broadcast();
  final viewCtrl = StreamController<v_struct.View>.broadcast();
  final dashboardCtrl = StreamController<d.Dashboard>.broadcast();
  final commandCtrl = StreamController<b.SimpleCommand>.broadcast();
  final wakeUpStreamCtrl = StreamController<b.WakeUpMessage>.broadcast();
  final displayCtrl = StreamController<b.DisplayInfo>.broadcast();
  final systemInfoCtrl = StreamController<b.SystemInfo>.broadcast();

  @override
  bool get isConnected => true;

  @override
  bool isStandby = true;

  @override
  Stream<b.GetToken> get tokenStream => tokenCtrl.stream;
  @override
  Stream<v_struct.View> get viewStream => viewCtrl.stream;
  @override
  Stream<d.Dashboard> get dashboardStream => dashboardCtrl.stream;
  @override
  Stream<b.SimpleCommand> get simpleCommandStream => commandCtrl.stream;
  @override
  Stream<b.WakeUpMessage> get wakeUpStream => wakeUpStreamCtrl.stream;
  @override
  Stream<b.DisplayInfo> get displayStream => displayCtrl.stream;
  @override
  Stream<b.SystemInfo> get systemInfoStream => systemInfoCtrl.stream;

  @override
  Future<void> connect() async {}

  @override
  void send(List<int> bytes) {}

  @override
  Future<void> dispose() async {
    await tokenCtrl.close();
    await viewCtrl.close();
    await dashboardCtrl.close();
    await commandCtrl.close();
    await wakeUpStreamCtrl.close();
    await displayCtrl.close();
    await systemInfoCtrl.close();
  }
}

void main() {
  final getIt = GetIt.instance;

  late FakeBackendSocket fakeSocket;

  setUp(() {
    getIt.allowReassignment = true;
    fakeSocket = FakeBackendSocket();
    getIt.registerSingleton<BackendSocket>(fakeSocket);
  });

  tearDown(() async {
    await fakeSocket.dispose();
  });

  testWidgets('IDENTIFY_USER command shows identify user overlay and seamlessly switches to welcome', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => ViewCubit(fakeSocket),
          child: const App(),
        ),
      ),
    );

    // Initial state: standby (black screen)
    expect(find.byType(App), findsOneWidget);
    expect(find.text('Identify User'), findsNothing);

    // 1. Send IDENTIFY_USER command
    final cmdBytes = b.SimpleCommandObjectBuilder(type: b.SimpleCommandType.IDENTIFY_USER).toBytes();
    fakeSocket.commandCtrl.add(b.SimpleCommand(cmdBytes));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify "Identify User" is displayed
    expect(find.text('Identify User'), findsOneWidget);

    // 2. Send WakeUpMessage for "John"
    final wakeUpBytes = b.WakeUpMessageObjectBuilder(userName: 'John', language: 'en').toBytes();
    fakeSocket.wakeUpStreamCtrl.add(b.WakeUpMessage(wakeUpBytes));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify it switched to welcome message
    expect(find.text('Identify User'), findsNothing);
    expect(find.text('Welcome John'), findsOneWidget);

    // 3. Wait for the welcome message timer (1100ms) to fire
    await tester.pump(const Duration(milliseconds: 1200));
    // Pump 600ms to let the fade-out opacity animation (500ms) finish
    await tester.pump(const Duration(milliseconds: 600));
    // Final pump to rebuild after onEnd sets _showOverlay = false
    await tester.pump();

    // Welcome overlay should be gone
    expect(find.text('Welcome John'), findsNothing);
  });
}
