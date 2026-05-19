import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:smirror_frontend/src/systems/pokemon_data_service.dart';
import 'package:smirror_frontend/src/widget_system/constans.dart';
import 'package:smirror_frontend/src/widget_system/helpers.dart';
import 'package:smirror_frontend/src/widgets/entertain/pokemon_card.dart';
import 'package:smirror_frontend/src/widgets/base_widget.dart';

class PokemonOfTheDayWidget extends SmirrorStatelessWidget {
  const PokemonOfTheDayWidget({super.key, required super.widgetData});

  @override
  Widget buildContent(BuildContext context) {
    final service = GetIt.I<PokemonDataService>();
    return FutureBuilder<PokemonData>(
      future: service.fetchPokemon(dailyRandomNumber(1, numberOfPokemons)),
      builder: (context, snapshot) {
        if (snapshot.hasData) return PokemonCard(pokemon: snapshot.data!);
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
