import 'package:flutter/material.dart';
import 'package:smirror_frontend/src/systems/pokemon_data_service.dart';

class PokemonCard extends StatelessWidget {
  final PokemonData pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Image at the top
          Flexible(
            child: Image.network(
              pokemon.imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) =>
              progress == null ? child : const Center(child: CircularProgressIndicator()),
            ),
          ),
          const Divider(),

          // 2. Name and Number
          Row(
          children: [
              Text(textAlign: TextAlign.center,
                "#${pokemon.id.toString().padLeft(3, '0')}  ",
                style: TextStyle(color: theme.colorScheme.primary, fontSize: 10),
              ),
              Text(
                pokemon.name,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          // 3. Weight and Height
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(context, Icons.height, "${pokemon.height}m"),
              _buildStat(context, Icons.monitor_weight_outlined, "${pokemon.weight}kg"),
            ],
          ),
          // 4. Types at the bottom
          Wrap(
            spacing: 6,
            children: pokemon.types.map((t) => _buildTypeChip(t)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
