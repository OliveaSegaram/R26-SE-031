import 'package:flutter/material.dart';

import '../theme/play_theme.dart';

class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.title,
    required this.answered,
    required this.total,
    required this.level,
    required this.coins,
    this.onBack,
  });

  final String title;
  final int answered;
  final int total;
  final int level;
  final int coins;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PlayTheme.radius),
        boxShadow: [
          BoxShadow(
            color: PlayTheme.purple.withValues(alpha: .08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (onBack != null)
                Material(
                  color: PlayTheme.purple.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_back_rounded, color: PlayTheme.purple),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: PlayTheme.navy,
                    )),
              ),
              _CoinBadge(coins: coins),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(total.clamp(0, 9), (i) {
              final done = i < answered;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: done ? PlayTheme.teal : Colors.grey.shade200,
                    boxShadow: done
                        ? [
                            BoxShadow(
                              color: PlayTheme.teal.withValues(alpha: .4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: PlayTheme.sun),
              const SizedBox(width: 4),
              Text('ප්‍රශ්න $answered / $total',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PlayTheme.purple.withValues(alpha: .15),
                      PlayTheme.teal.withValues(alpha: .15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('මට්ටම $level',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: PlayTheme.purple)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: PlayTheme.sun.withValues(alpha: .45),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: Color(0xFFE65100), size: 22),
          const SizedBox(width: 4),
          Text('$coins',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF5D4037),
                fontSize: 16,
              )),
        ],
      ),
    );
  }
}
