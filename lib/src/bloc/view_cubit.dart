import 'dart:async';
import 'dart:typed_data';
import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smirror_wire/generated/back_front_back_front_generated.dart' as bfmsg;
import 'package:smirror_wire/generated/view_view_structure_generated.dart' as vstruct;
import 'package:smirror_frontend/src/systems/backend_socket.dart';
import 'package:smirror_frontend/src/theme/app_theme.dart';
import 'view_state.dart';

class ViewCubit extends Cubit<ViewState> {
  final BackendSocket _socket;
  int _currentTheme = 0;

  late final StreamSubscription _viewSub;
  late final StreamSubscription _commandSub;

  ViewCubit(this._socket) : super(WebSocketInitial()) {
    _viewSub = _socket.viewStream.listen(
      _onViewReceived,
      onError: (err) => emit(WebSocketDecodeErrorState(err.toString())),
    );

    _commandSub = _socket.simpleCommandStream.listen(
      (cmd) {
        if (cmd.type == bfmsg.SimpleCommandType.NEXT_THEME) {
          _currentTheme = (_currentTheme + 1) % AppTheme.themeCount;
          emit(WebSocketThemeToggledState(_currentTheme));
        } else {
          emit(WebSocketSimpleCommandState(cmd));
        }
      },
      onError: (err) => emit(WebSocketDecodeErrorState(err.toString())),
    );
  }

  void _onViewReceived(vstruct.View view) {
    _currentTheme = view.theme;
    final data = view.data;
    if (data == null || data.isEmpty) {
      emit(WebSocketViewState(const [], _currentTheme));
      return;
    }

    final buffer = data is Uint8List ? data : Uint8List.fromList(data);
    final bufferContext = fb.BufferContext.fromBytes(buffer);
    final pages = const fb.ListReader<vstruct.Page>(vstruct.Page.reader)
        .read(bufferContext, 0);

    emit(WebSocketViewState(List.unmodifiable(pages), _currentTheme));
  }

  void clearMessage() {
    emit(WebSocketClearMessageState());
  }

  void emitSystemMessage(WebSocketSystemMessageState state) {
    emit(state);
  }

  void updateTheme(int theme) {
    _currentTheme = theme;
    emit(WebSocketThemeToggledState(_currentTheme));
  }

  @override
  Future<void> close() {
    _viewSub.cancel();
    _commandSub.cancel();
    return super.close();
  }
}