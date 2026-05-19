import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:smirror_frontend/src/systems/pokemon_data_service.dart';
import 'package:smirror_frontend/src/widgets/entertain/pokemon_card.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class RandomPokemonWidget extends SmirrorStatefulWidget {
  const RandomPokemonWidget({super.key, required super.widgetData});

  @override
  State<RandomPokemonWidget> createState() => _RandomPokemonWidgetState();
}

class _RandomPokemonWidgetState extends SmirrorState<RandomPokemonWidget> {
  late Future<PokemonData> _future;

  @override
  void initState() {
    super.initState();
    final id = math.Random().nextInt(1025) + 1;
    _future = GetIt.I<PokemonDataService>().fetchPokemon(id);
  }

  @override
  Widget buildContent(BuildContext context) {
    return FutureBuilder<PokemonData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) return PokemonCard(pokemon: snapshot.data!);
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
