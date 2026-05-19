import 'package:flat_buffers/flat_buffers.dart' as flat;
import 'package:injectable/injectable.dart';
import 'package:smirror_frontend/flatbufs/front_back_front_back_generated.dart' as fb;
import 'package:smirror_frontend/src/systems/backend_socket.dart';

@Singleton()
class Logger {
  final BackendSocket _socket;

  Logger(this._socket);

  void log(fb.VerboseLevel level, String message) {
    final bld = flat.Builder(initialSize: 256);

    final messageOff = bld.writeString(message);

    final logBuilder = fb.LogMessageBuilder(bld);
    logBuilder.begin();
    logBuilder.addLevel(level);
    logBuilder.addMessageOffset(messageOff);
    final logOff = logBuilder.finish();

    final msgBuilder = fb.FrontBackMessageBuilder(bld);
    msgBuilder.begin();
    msgBuilder.addPayloadType(fb.FrontBackPayloadTypeId.LogMessage);
    msgBuilder.addPayloadOffset(logOff);
    final root = msgBuilder.finish();

    bld.finish(root);
    _socket.send(bld.buffer);
  }

  void traceL3(String message) => log(fb.VerboseLevel.TraceL3, message);
  void traceL2(String message) => log(fb.VerboseLevel.TraceL2, message);
  void traceL1(String message) => log(fb.VerboseLevel.TraceL1, message);
  void debug  (String message) => log(fb.VerboseLevel.Debug,   message);
  void info   (String message) => log(fb.VerboseLevel.Info,    message);
  void notice (String message) => log(fb.VerboseLevel.Notice,  message);
  void warning(String message) => log(fb.VerboseLevel.Warning, message);
  void error  (String message) => log(fb.VerboseLevel.Error,   message);
  void critical(String message)=> log(fb.VerboseLevel.Critical, message);
}
