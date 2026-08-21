import 'dart:math';
import 'package:flutter/material.dart';

class GameLayoutUtils {
  static List<Offset> scatterInZone({
    required int count,
    required Rect zone,
    required double itemSize,
    required double minSpacing,
    int maxAttempts = 100,
    int seed = 0,
  }) {
    final rng = Random(seed);
    List<Offset> positions = [];
    
    final double safeLeft = zone.left;
    final double safeTop = zone.top;
    final double safeRight = zone.right - itemSize;
    final double safeBottom = zone.bottom - itemSize;
    
    if (safeRight <= safeLeft || safeBottom <= safeTop) {
      // Zone too small, fallback
      return List.generate(count, (i) => Offset(safeLeft, safeTop + i * (itemSize + minSpacing)));
    }

    for (int i = 0; i < count; i++) {
      Offset? best;
      double bestMinDist = -1;

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        final x = safeLeft + rng.nextDouble() * (safeRight - safeLeft);
        final y = safeTop + rng.nextDouble() * (safeBottom - safeTop);
        final candidate = Offset(x, y);

        double minDist = double.infinity;
        bool tooClose = false;

        for (final placed in positions) {
          final dist = (candidate - placed).distance;
          if (dist < (itemSize + minSpacing)) {
            tooClose = true;
            break;
          }
          if (dist < minDist) minDist = dist;
        }

        if (!tooClose) {
          best = candidate;
          break;
        }

        if (best == null || (minDist > bestMinDist)) {
          best = candidate;
          bestMinDist = minDist;
        }
      }
      
      positions.add(best ?? Offset(safeLeft, safeTop + i * (itemSize + minSpacing)));
    }
    
    return positions;
  }
}
