import 'dart:async';
import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:smirror_frontend/flatbufs/dashboard_dashboard_structure_generated.dart' as d;
import 'package:smirror_frontend/flatbufs/view_view_structure_generated.dart' as v_struct;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:smirror_frontend/flatbufs/back_front_back_front_generated.dart' as b;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:smirror_frontend/flatbufs/front_back_front_back_generated.dart' as fb_front;


@Singleton()
class BackendSocket {
  static const String _url = 'ws://localhost:9001/flutter';
  static const Map<String, String> _headers = {'version': '0.1'};

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  bool _connected = false;
  bool get isConnected => _connected;

  bool _isConnecting = false;
  Timer? _reconnectTimer;
  Duration _retryDelay = const Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 10);

  // --- Typed Data Streams ---
  final _tokenCtrl = StreamController<b.GetToken>.broadcast();
  final _viewCtrl = StreamController<v_struct.View>.broadcast();
  final _dashboardCtrl = StreamController<d.Dashboard>.broadcast();
  final _commandCtrl = StreamController<b.SimpleCommand>.broadcast();
  final _wakeUpStreamCtrl = StreamController<b.WakeUpMessage>.broadcast();
  final _displayCtrl = StreamController<b.DisplayInfo>.broadcast();
  final _systemInfoCtrl = StreamController<b.SystemInfo>.broadcast();

  Stream<b.GetToken> get tokenStream => _tokenCtrl.stream;
  Stream<v_struct.View> get viewStream => _viewCtrl.stream;
  Stream<d.Dashboard> get dashboardStream => _dashboardCtrl.stream;
  Stream<b.SimpleCommand> get simpleCommandStream => _commandCtrl.stream;
  Stream<b.WakeUpMessage> get wakeUpStream => _wakeUpStreamCtrl.stream;
  Stream<b.DisplayInfo> get displayStream => _displayCtrl.stream;
  Stream<b.SystemInfo> get systemInfoStream => _systemInfoCtrl.stream;

  BackendSocket() {
    connect();
  }

  Future<void> connect() async {
    if (_connected || _isConnecting) return;
    _isConnecting = true;

    try {
      final socket = await WebSocket.connect(_url, headers: _headers).timeout(const Duration(seconds: 5));
      _channel = IOWebSocketChannel(socket);
      _connected = true;
      _isConnecting = false;
      _retryDelay = const Duration(seconds: 1); // Reset backoff on success
      _reconnectTimer?.cancel();

      _sendVersionInfo();

      _sub = _channel!.stream.listen(
        _handleIncomingFrame,
        onError: (err, st) {
          _connected = false;
          _scheduleReconnect();
        },
        onDone: () {
          _connected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _connected = false;
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_connected) return;

    _reconnectTimer = Timer(_retryDelay, () {
      _retryDelay = Duration(seconds: (_retryDelay.inSeconds * 2).clamp(2, _maxDelay.inSeconds));
      connect();
    });
  }

  /// Parse the FlatBuffer root ONCE and dispatch the payloads.
  void _handleIncomingFrame(dynamic data) {
    if (data is! List<int>) return;

    try {
      // Single Root Parse
      final msg = b.BackFrontMessage(data);
      final payload = msg.payload;

      switch (msg.payloadType) {
        case b.BackFrontPayloadTypeId.GetToken:
          _tokenCtrl.add(payload as b.GetToken);
          break;
        case b.BackFrontPayloadTypeId.SimpleCommand:
          final command = payload as b.SimpleCommand;
          _commandCtrl.add(command);
          break;
        case b.BackFrontPayloadTypeId.viewStructure_View:
          _viewCtrl.add(payload as v_struct.View);
          break;
        case b.BackFrontPayloadTypeId.dashboardStructure_Dashboard:
          _dashboardCtrl.add(payload as d.Dashboard);
          break;
        case b.BackFrontPayloadTypeId.WakeUpMessage:
          _wakeUpStreamCtrl.add(payload as b.WakeUpMessage);
          break;
        case b.BackFrontPayloadTypeId.DisplayInfo:
          _displayCtrl.add(payload as b.DisplayInfo);
          break;
        case b.BackFrontPayloadTypeId.SystemInfo:
          _systemInfoCtrl.add(payload as b.SystemInfo);
          break;
        default:
          // Ignore or log unknown types
          break;
      }
    } catch (e) {
      // Malformed frame handling
    }
  }

  /// Sends a raw FlatBuffer message
  void send(List<int> bytes) => _channel?.sink.add(bytes);

  Future<void> _sendVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;

      final builder = fb_front.FrontBackMessageObjectBuilder(
        payloadType: fb_front.FrontBackPayloadTypeId.VersionInfo,
        payload: fb_front.VersionInfoObjectBuilder(version: version),
      );

      send(builder.toBytes());
    } catch (e) {
      // Ignore errors in version info sending
    }
  }

  @disposeMethod
  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    await _tokenCtrl.close();
    await _viewCtrl.close();
    await _dashboardCtrl.close();
    await _commandCtrl.close();
    await _wakeUpStreamCtrl.close();
    await _displayCtrl.close();
    await _systemInfoCtrl.close();
  }
}
