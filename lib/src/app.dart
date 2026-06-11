import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smirror_wire/generated/back_front_back_front_generated.dart' as bfmsg;
import 'package:smirror_wire/generated/view_view_structure_generated.dart' as vstruct;
import 'package:smirror_frontend/l10n/app_localizations.dart';
import 'package:smirror_frontend/src/theme/app_theme.dart';
import 'package:smirror_frontend/src/systems/backend_socket.dart';
import 'package:smirror_frontend/src/systems/injection.dart';
import 'package:smirror_frontend/src/widget_system/widget_registry.dart' show WidgetRegistry;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'bloc/view_cubit.dart';
import 'bloc/view_state.dart';
import 'info_overlay.dart';

const welcomeAnimationTime = 1000;
const infoDuration = 4000; // Auto-dismiss info after 4 seconds

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  List<vstruct.Page> currentPages = [];
  final PageController _pageController = PageController();
  bool _isStandby = true;
  bool _isWakingUp = false;
  bool _isIdentifyingUser = false;
  bool _showOverlay = false;
  String _userName = '';
  Locale _currentLocale = const Locale('en');

  // Info overlay state
  bool _showInfo = false;
  bfmsg.InfoType _infoType = bfmsg.InfoType.CAN_UPDATE;
  int _infoTime = 0;
  String _infoText = '';
  Timer? _infoTimer;
  int _infoMessageId = 0;

  StreamSubscription? _wakeUpSub;
  StreamSubscription? _displayInfoSub;

  @override
  void initState() {
    super.initState();
    _wakeUpSub = getIt<BackendSocket>().wakeUpStream.listen(
      (wakeUpMsg) {
        final name = wakeUpMsg.userName ?? '';
        final lang = wakeUpMsg.language ?? 'en';
        setState(() {
          _currentLocale = Locale(lang);
        });
        _startWakeUp(name == 'admin' ? '' : name);
      },
      onError: (err) {
        _startWakeUp('');
      },
    );

    // Subscribe to display info from backend
    _displayInfoSub = getIt<BackendSocket>().displayStream.listen(
      (bfmsg.DisplayInfo info) {
        if (!mounted) return;

        _infoTimer?.cancel();

        setState(() {
          // Stop any pending welcome animation
          _isWakingUp = false;
          _showOverlay = false;
          
          // Update locale from message
          final lang = info.language ?? 'en';
          _currentLocale = Locale(lang);
          
          // Update info state
          _infoType = info.type;
          _infoTime = info.time;
          _infoText = ''; // Use empty string to let InfoOverlay show translated text
          _showInfo = true;
          _infoMessageId++;
        });

        final duration = _getInfoDuration(info.type, info.time);
        if (duration != null) {
          _infoTimer = Timer(duration, () {
            if (mounted) {
              setState(() => _showInfo = false);
            }
          });
        }
      },
    );
  }

  Duration? _getInfoDuration(bfmsg.InfoType type, int time) {
    if (time > 0) {
      return Duration(seconds: time);
    }
    if (type == bfmsg.InfoType.FACE_TRAINING_STARTED) {
      return null;
    }
    return const Duration(seconds: 30);
  }

  @override
  void dispose() {
    _wakeUpSub?.cancel();
    _displayInfoSub?.cancel();
    _infoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startWakeUp(String userName) {
    setState(() {
      _userName = userName;
      _isStandby = false;
      _isIdentifyingUser = false;
      _isWakingUp = true;
      _showOverlay = true;
    });

    Future.delayed(
      const Duration(milliseconds: welcomeAnimationTime + 100),
      () {
        if (mounted) setState(() => _isWakingUp = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewCubit, ViewState>(
      buildWhen: (prev, curr) =>
          curr is WebSocketViewState || curr is WebSocketThemeToggledState,
      builder: (context, viewState) {
        int themeId = 0;
        if (viewState is WebSocketViewState) {
          themeId = viewState.theme;
        } else if (viewState is WebSocketThemeToggledState) {
          themeId = viewState.theme;
        }

        final appTheme = AppTheme.getTheme(themeId);

        return MaterialApp(
          theme: appTheme,
          locale: _currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            backgroundColor: _isStandby ? Colors.black : null,
            body: BlocConsumer<ViewCubit, ViewState>(
              listenWhen: (prev, curr) => curr is WebSocketSimpleCommandState ||
                  curr is WebSocketViewState,
              listener: (context, state) {
                if (state is WebSocketViewState) {
                  setState(() => currentPages = state.view);
                }
                if (state is WebSocketSimpleCommandState) {
                  final current = _pageController.hasClients
                      ? (_pageController.page ?? 0).round()
                      : 0;
                  switch (state.command.type) {
                    case bfmsg.SimpleCommandType.RIGHT:
                      _goToPage(current - 1);
                      break;
                    case bfmsg.SimpleCommandType.LEFT:
                      _goToPage(current + 1);
                      break;
                    case bfmsg.SimpleCommandType.STANDBY:
                      setState(() {
                        _isStandby = true;
                        _isIdentifyingUser = false;
                        _showOverlay = false;
                        _showInfo = false; // Also dismiss info on standby
                      });
                      break;
                    case bfmsg.SimpleCommandType.IDENTIFY_USER:
                      setState(() {
                        _isStandby = false;
                        _isIdentifyingUser = true;
                        _isWakingUp = false;
                        _showOverlay = true;
                      });
                      break;
                    default:
                      break;
                  }
                }
              },
              buildWhen: (prev, curr) => curr is WebSocketViewState,
              builder: (context, state) {
                return Stack(
                  children: [
                    // Base: Black screen for standby, or the actual page view
                    if (_isStandby)
                      const ColoredBox(color: Colors.black)
                    else if (currentPages.isNotEmpty)
                      _buildPageView(),

                    // Welcome overlay on top while waking up or identifying user
                    if (_showOverlay)
                      AnimatedOpacity(
                        opacity: (_isWakingUp || _isIdentifyingUser) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        onEnd: () {
                          if (!_isIdentifyingUser) {
                            setState(() => _showOverlay = false);
                          }
                        },
                        child: IgnorePointer(
                          child: _WelcomeOverlay(
                            userName: _userName,
                            isIdentifyingUser: _isIdentifyingUser,
                          ),
                        ),
                      ),

                    // Info overlay for system notifications
                    if (_showInfo)
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: IgnorePointer(
                          child: InfoOverlay(
                            key: ValueKey(_infoMessageId),
                            message: _infoText,
                            type: _infoType,
                            duration: _getInfoDuration(_infoType, _infoTime),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageView() {
    if (currentPages.isEmpty) {
      return const Center(child: Text("Waiting for View..."));
    }

    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentPages.length,
      itemBuilder: (context, index) => _KeepAlivePage(
        key: ValueKey('page_$index'),
        child: _buildPage(currentPages[index]),
      ),
    );
  }

  Widget _buildPage(vstruct.Page page) {
    return ColoredBox(
        color: Colors.black, child:
    Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        for (final w in page.widgets ?? const [])
          Positioned(
            left: w.xPos.toDouble(),
            top: w.yPos.toDouble(),
            width: w.width.toDouble(),
            height: w.height.toDouble(),
            child: RepaintBoundary(
              child: WidgetRegistry.create(w.widgetId, w),
            ),
          ),
      ],
    )
    );
  }

  void _goToPage(int index) {
    if (!_pageController.hasClients) return;
    final max = currentPages.isEmpty ? 0 : currentPages.length - 1;
    final target = index.clamp(0, max);
    final current = (_pageController.page ?? 0).round();
    if (target == current) return;

    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }
}

class _WelcomeOverlay extends StatefulWidget {
  final String userName;
  final bool isIdentifyingUser;

  const _WelcomeOverlay({
    required this.userName,
    required this.isIdentifyingUser,
  });

  @override
  State<_WelcomeOverlay> createState() => _WelcomeOverlayState();
}

class _WelcomeOverlayState extends State<_WelcomeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: welcomeAnimationTime),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isIdentifyingUser) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_WelcomeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isIdentifyingUser != widget.isIdentifyingUser ||
        oldWidget.userName != widget.userName) {
      if (widget.isIdentifyingUser) {
        _controller.repeat();
      } else {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.isIdentifyingUser
        ? (AppLocalizations.of(context)?.identifyUser ?? 'Identify User')
        : 'Welcome ${widget.userName}';
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          // child is cached — Text is never rebuilt, only the shader changes
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 64),
          ),
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Colors.white24,
                  Colors.white,
                  Colors.white24,
                ],
                stops: [
                  (_controller.value - 0.3).clamp(0.0, 1.0),
                  _controller.value.clamp(0.0, 1.0),
                  (_controller.value + 0.3).clamp(0.0, 1.0),
                ],
              ).createShader(bounds),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({super.key, required this.child});
  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState
    extends State<_KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}