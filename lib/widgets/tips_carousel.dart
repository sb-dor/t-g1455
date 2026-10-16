import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

/// A short carousel of tips with a glass page control floating over it.
class TipsCarousel extends StatefulWidget {
  const TipsCarousel({super.key});

  @override
  State<TipsCarousel> createState() => _TipsCarouselState();
}

class _TipsCarouselState extends State<TipsCarousel> {
  static const List<String> _tips = <String>[
    'Tap + to add a task',
    'Pull the editor up for long notes',
    'Tune the glass in the Lab',
  ];

  final PageController _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 160,
    child: Stack(
      children: <Widget>[
        PageView(
          controller: _pages,
          children: <Widget>[
            for (final String tip in _tips)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlassCard(
                  child: Center(
                    child: Text(
                      tip,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Center(
            child: GlassAbove(
              child: GlassPageControl(
                count: _tips.length,
                controller: _pages,
                semanticLabel: 'Tips',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
