import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:smirror_frontend/flatbufs/back_front_back_front_generated.dart' as b;
import 'package:smirror_frontend/flatbufs/front_back_front_back_generated.dart' as f;
import 'package:smirror_frontend/src/systems/backend_socket.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class SystemUsageWidget extends SmirrorStatefulWidget {
  const SystemUsageWidget({super.key, required super.widgetData});

  @override
  State<SystemUsageWidget> createState() => _SystemUsageWidgetState();
}

class _SystemUsageWidgetState extends SmirrorState<SystemUsageWidget> {
  final _socket = GetIt.I<BackendSocket>();
  Timer? _timer;
  StreamSubscription<b.SystemInfo>? _sub;

  double _cpu = 0.0;
  double _ram = 0.0;
  double _storage = 0.0;

  @override
  void initState() {
    super.initState();
    _sub = _socket.systemInfoStream.listen((info) {
      if (mounted) {
        setState(() {
          _cpu = info.cpu;
          _ram = info.ram;
          _storage = info.storage;
        });
      }
    });

    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _requestSystemInfo();
    });
    // Request immediately on startup
    _requestSystemInfo();
  }

  void _requestSystemInfo() {
    if (!_socket.isConnected) return;

    final bld = fb.Builder(initialSize: 64);
    final fsBuilder = f.FrontSignalBuilder(bld);
    fsBuilder.begin();
    fsBuilder.addSignal(f.FrontendSignal.GET_SYSTEM_INFO);
    final fsOff = fsBuilder.finish();

    final fbm = f.FrontBackMessageBuilder(bld);
    fbm.begin();
    fbm.addPayloadType(f.FrontBackPayloadTypeId.FrontSignal);
    fbm.addPayloadOffset(fsOff);
    final root = fbm.finish();

    bld.finish(root);
    _socket.send(bld.buffer);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Color _getColorForValue(double percentage) {
    if (percentage < 50) return Colors.greenAccent;
    if (percentage < 85) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Widget _buildMetric(String label, double value) {
    final color = _getColorForValue(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '${value.toStringAsFixed(1)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100.0,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Usage',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetric('CPU', _cpu),
          _buildMetric('RAM', _ram),
          _buildMetric('Storage', _storage),
        ],
      ),
    );
  }
}
