import 'dart:async';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:smirror_frontend/flatbufs/back_front_back_front_generated.dart' as b;
import 'package:smirror_frontend/flatbufs/front_back_front_back_generated.dart' as f;
import 'package:smirror_frontend/src/systems/backend_socket.dart';

@immutable
class Token {
  final String accessToken;
  final String? tokenType;
  final DateTime? expiresAt;
  final String? url;

  const Token({
    required this.accessToken,
    this.tokenType,
    this.expiresAt,
    this.url,
  });

  bool get isExpired => expiresAt == null || DateTime.now().isAfter(expiresAt!);
}

@LazySingleton()
class TokenService {
  final BackendSocket _socket;
  final Duration _timeout;

  final _cache = <String, Token>{};
  final _inFlight = <String, Completer<Token>>{};

  TokenService._(this._socket, this._timeout) {
    _socket.tokenStream.listen(_handleTokenResponse);
  }

  @factoryMethod
  factory TokenService(BackendSocket socket) =>
      TokenService._(socket, const Duration(seconds: 10));

  /// Central handler for all incoming tokens
  void _handleTokenResponse(b.GetToken gt) {
    final provider = gt.provider ?? '';
    final completer = _inFlight.remove(provider);

    if (completer != null && !completer.isCompleted) {
      final token = _mapToken(gt);
      _cache[provider] = token;
      completer.complete(token);
    }
  }

  Future<Token> getToken(String provider, {Duration? timeout}) async {
    // 1. Check Cache - if valid, return immediately
    final cached = _cache[provider];
    if (cached != null && !cached.isExpired) return cached;

    // 2. Handle Duplicate Requests
    final existing = _inFlight[provider];
    if (existing != null) return existing.future;

    // 4. Create the trap BEFORE sending the request
    final c = Completer<Token>();
    _inFlight[provider] = c;

    // 5. Send the request to backend
    _socket.send(_buildGetTokenRequest(provider));

    final t = timeout ?? _timeout;
    try {
      final token = await c.future.timeout(t);
      _cache[provider] = token; // Cache it
      return _cache[provider]!;
    } on TimeoutException {
      _inFlight.remove(provider);
      throw TimeoutException('Token request timed out for $provider', t);
    }
  }


  void setToken(String provider, Token token) => _cache[provider] = token;
  void invalidate(String provider) => _cache.remove(provider);
  void clear() => _cache.clear();

  List<int> _buildGetTokenRequest(String provider) {
    final bld = fb.Builder(initialSize: 128);

    final providerOff = bld.writeString(provider);
    final gtBuilder = f.GetTokenBuilder(bld);
    gtBuilder.begin();
    gtBuilder.addProviderOffset(providerOff);
    final getTokenOff = gtBuilder.finish();

    final fbm = f.FrontBackMessageBuilder(bld);
    fbm.begin();
    fbm.addPayloadType(f.FrontBackPayloadTypeId.GetToken);
    fbm.addPayloadOffset(getTokenOff);
    final root = fbm.finish();

    bld.finish(root);
    return bld.buffer;
  }


  Token _mapToken(b.GetToken gt) {
    final access = gt.accessToken ?? '';
    final type = gt.tokenType;
    final url = gt.url;

    return Token(
      accessToken: access,
      tokenType: type,
      url: url,
    );
  }
}
