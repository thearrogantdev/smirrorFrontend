import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smirror_frontend/flatbufs/back_front_back_front_generated.dart' as bfmsg;
import 'package:smirror_frontend/l10n/app_localizations.dart';

class InfoOverlay extends StatefulWidget {
  final String message;
  final bfmsg.InfoType type;
  final Duration duration;

  const InfoOverlay({
    super.key,
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<InfoOverlay> createState() => _InfoOverlayState();
}

class _InfoOverlayState extends State<InfoOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..reverse(from: 1.0); // Count down from 1.0 to 0.0
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    switch (widget.type) {
      case bfmsg.InfoType.CAN_UPDATE:
        return Icons.system_update_outlined;
      case bfmsg.InfoType.MUST_UPDATE:
        return Icons.warning_amber_outlined;
      case bfmsg.InfoType.FACE_TRAINING:
        return Icons.face_retouching_natural_outlined;
    }
  }

  Color _getColor() {
    switch (widget.type) {
      case bfmsg.InfoType.CAN_UPDATE:
        return Colors.cyan;
      case bfmsg.InfoType.MUST_UPDATE:
        return Colors.orangeAccent;
      case bfmsg.InfoType.FACE_TRAINING:
        return Colors.purpleAccent;
    }
  }

  String _getText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.message.isNotEmpty && widget.message != 'System notification') {
      return widget.message;
    }
    switch (widget.type) {
      case bfmsg.InfoType.CAN_UPDATE:
        return l10n.updateAvailable;
      case bfmsg.InfoType.MUST_UPDATE:
        return l10n.criticalUpdateRequired;
      case bfmsg.InfoType.FACE_TRAINING:
        return l10n.inFaceTraining;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
        ),
        // Centered popup
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: _getColor().withValues(alpha: 0.6),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getColor().withValues(alpha: 0.3),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  // Circular timer in top right
                  Positioned(
                    top: 24,
                    right: 24,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: _controller.value,
                            strokeWidth: 3,
                            color: _getColor(),
                            backgroundColor: _getColor().withValues(alpha: 0.2),
                          ),
                        );
                      },
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 48,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _getColor().withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(),
                            size: 80.0,
                            color: _getColor(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          _getText(context),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.type == bfmsg.InfoType.FACE_TRAINING) ...[
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.pleaseWaitAMoment,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 16.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}