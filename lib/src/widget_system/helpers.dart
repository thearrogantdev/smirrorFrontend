import 'dart:math';

int dailyRandomNumber(int min, int max) {
  final now = DateTime.now().toUtc();

  // Create a stable daily seed
  final seed = now.year * 10000 + now.month * 100 + now.day;

  final random = Random(seed);

  return min + random.nextInt(max - min + 1);
}
