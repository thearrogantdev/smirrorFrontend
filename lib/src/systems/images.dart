import 'dart:async';
import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:smirror_frontend/src/systems/logger.dart';

class _ImgKey {
  final int id;
  final int? w, h;
  const _ImgKey(this.id, this.w, this.h);
  @override
  bool operator ==(Object o) => o is _ImgKey && o.id == id && o.w == w && o.h == h;
  @override
  int get hashCode => Object.hash(id, w, h);
}

@LazySingleton()
class ImageService {
  final int maxEntries;

  // (id,w,h) -> provider
  final _providers = <_ImgKey, ImageProvider>{};

  // single-flight prefetch
  final _prefetchInFlight = <_ImgKey, Future<void>>{};

  // simple LRU over ids
  final _lru = <int, void>{};

  ImageService._(this.maxEntries);

  // Injectable uses this factory: no external params -> no GetIt lookups for Duration/int
  @factoryMethod
  factory ImageService() => ImageService._(20);

  /// Return an ImageProvider for (id, path[, w, h]) and cache it locally.
  Future<ImageProvider> imageProvider(
      int binaryId,
      String path, {
        int? targetWidth,
        int? targetHeight,
      }) async {
    final key = _ImgKey(binaryId, targetWidth, targetHeight);
    final cached = _providers[key];
    if (cached != null) return cached;

    final file = File(path);

    // Fail fast — do not cache a provider for a missing file
    if (!await file.exists()) {
      GetIt.I<Logger>().error("imageProvider file not found: $path");
      throw FileSystemException('Image file not found', path);
    }

    ImageProvider provider = FileImage(file);
    if (targetWidth != null || targetHeight != null) {
      provider = ResizeImage(provider, width: targetWidth, height: targetHeight);
    }

    _providers[key] = provider;
    _touch(binaryId);
    _evictIfNeeded();
    return provider;
  }

  /// Prefetch (decode) without holding a BuildContext across await.
  Future<void> prefetchWithConfig(
      ImageConfiguration config,
      int binaryId,
      String path, {
        int? targetWidth,
        int? targetHeight,
      }) async {
    final key = _ImgKey(binaryId, targetWidth, targetHeight);
    final existing = _prefetchInFlight[key];
    if (existing != null) {
      await existing;
      return;
    }

    final fut = () async {
      final provider = await imageProvider(
        binaryId,
        path,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      await _precacheWithConfig(provider, config);
    }();

    _prefetchInFlight[key] = fut;
    try {
      await fut;
    } finally {
      _prefetchInFlight.remove(key);
    }
  }

  /// Evict everything for one id (e.g., file replaced)
  void evictId(int id) {
    final entries = _providers.entries.where((e) => e.key.id == id).toList();
    for (final e in entries) {
      PaintingBinding.instance.imageCache.evict(e.value);
      _providers.remove(e.key);
    }
    _lru.remove(id);
  }

  // -------------------- internals --------------------

  void _touch(int id) {
    if (_lru.containsKey(id)) _lru.remove(id);
    _lru[id] = null;
  }

  void _evictIfNeeded() {
    while (_lru.length > maxEntries) {
      final oldest = _lru.keys.first;
      _lru.remove(oldest);

      // drop providers for that id and evict from Flutter cache
      final toRemove = _providers.entries.where((e) => e.key.id == oldest).toList();
      for (final e in toRemove) {
        PaintingBinding.instance.imageCache.evict(e.value);
        _providers.remove(e.key);
      }
    }
  }

  Future<void> _precacheWithConfig(ImageProvider provider, ImageConfiguration config) {
    final completer = Completer<void>();
    final stream = provider.resolve(config);

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
          (ImageInfo _, bool _) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
      onError: (Object e, StackTrace? st) {
        if (!completer.isCompleted) completer.completeError(e, st);
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    return completer.future;
  }
}
