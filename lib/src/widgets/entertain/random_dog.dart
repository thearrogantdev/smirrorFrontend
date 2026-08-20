import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:smirror_frontend/src/systems/backend_socket.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

const _randomDogEndpoint = 'https://dog.ceo/api/breeds/image/random';

class RandomDogWidget extends SmirrorStatefulWidget {
  const RandomDogWidget({super.key, required super.widgetData});

  @override
  State<RandomDogWidget> createState() => _RandomDogWidgetState();
}

class _RandomDogWidgetState extends SmirrorState<RandomDogWidget> {
  String? _imageUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDogImage();
  }

  Future<void> _fetchDogImage() async {
    if (GetIt.I<BackendSocket>().isStandby) {
      return;
    }
    try {
      final response = await http.get(Uri.parse(_randomDogEndpoint));
      if (response.statusCode != 200) {
        throw Exception('Dog API request failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final imageUrl = data is Map<String, dynamic> ? data['message'] : null;
      final status = data is Map<String, dynamic> ? data['status'] : null;
      if (status != 'success' || imageUrl is! String || imageUrl.isEmpty) {
        throw Exception('Dog API returned invalid data');
      }

      if (!mounted) return;
      setState(() {
        _imageUrl = imageUrl;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _imageUrl == null
          ? const Center(
              child: Icon(Icons.pets, color: Colors.white54, size: 40),
            )
          : Image.network(
              _imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.pets, color: Colors.white54, size: 40),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
    );
  }
}
