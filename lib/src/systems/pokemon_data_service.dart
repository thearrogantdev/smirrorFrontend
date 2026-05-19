import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

class PokemonData {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final double height; // in meters
  final double weight; // in kg

  PokemonData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.height,
    required this.weight,
  });

  factory PokemonData.fromJson(Map<String, dynamic> json) {
    return PokemonData(
      id: json['id'],
      name: (json['name'] as String).toUpperCase(),
      imageUrl: json['sprites']['other']['official-artwork']['front_default'] ?? '',
      types: (json['types'] as List).map((t) => t['type']['name'].toString()).toList(),
      height: json['height'] / 10.0, // decimetres to meters
      weight: json['weight'] / 10.0, // hectograms to kg
    );
  }
}

@LazySingleton()
class PokemonDataService {
  final Map<int, PokemonData> _pokemonCache = {};

  Future<PokemonData> fetchPokemon(int id) async {
    if (_pokemonCache.containsKey(id)) return _pokemonCache[id]!;

    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$id'));
    if (response.statusCode == 200) {
      final data = PokemonData.fromJson(jsonDecode(response.body));
      _pokemonCache[id] = data;
      return data;
    }
    throw Exception('Failed to load Pokemon');
  }
}
