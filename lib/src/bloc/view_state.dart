import 'package:smirror_wire/generated/back_front_back_front_generated.dart' as bfmsg;
import 'package:smirror_wire/generated/view_view_structure_generated.dart' as vstruct;

abstract class ViewState {}

class WebSocketInitial extends ViewState {}

/// Generic system notification message state (for "update needed", etc.)
abstract class WebSocketSystemMessageState extends ViewState {}

/// Simple command responses from C++ side
class WebSocketSimpleCommandState extends WebSocketSystemMessageState {
    final bfmsg.SimpleCommand command;
    WebSocketSimpleCommandState(this.command);
}

/// View page list received from C++ side
class WebSocketViewState extends WebSocketSystemMessageState {
    final List<vstruct.Page> view;
    final int theme;
    WebSocketViewState(this.view, this.theme);
}

/// Clear pending message (for clearing notifications)
class WebSocketClearMessageState extends WebSocketSystemMessageState {}

/// Theme toggled notification
class WebSocketThemeToggledState extends ViewState {
    final int theme;
    WebSocketThemeToggledState(this.theme);
}

/// Decode error from FlatBuffers
class WebSocketDecodeErrorState extends WebSocketSystemMessageState {
    final String error;
    WebSocketDecodeErrorState(this.error);
}

class WebSocketBinaryPathReceived extends ViewState {
    final int binaryId;
    final String path;
    WebSocketBinaryPathReceived({required this.path, required this.binaryId});
}