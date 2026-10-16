import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

/// Width and height of the glass lens, and the height of its track.
const double kLensSize = 44;

/// How long the lens takes to travel to a new progress value.
const Duration kLensDuration = Duration(milliseconds: 350);

/// A plain translucent track with a glass lens that travels along it to show
/// [progress], a fraction clamped to 0 through 1.
class ProgressLens extends StatelessWidget {
  const ProgressLens({required this.progress, super.key});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final double fraction = progress.clamp(0.0, 1.0);
    final Color trackColor =
        (IconTheme.of(context).color ??
                DefaultTextStyle.of(context).style.color ??
                Colors.white)
            .withValues(alpha: 0.18);
    return Semantics(
      label: '${(fraction * 100).round()}% complete',
      child: ExcludeSemantics(
        child: GlassTravel(
          child: SizedBox(
            height: kLensSize,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double travel = constraints.maxWidth - kLensSize;
                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: DecoratedBox(
                          key: const ValueKey<String>('progress-track'),
                          decoration: BoxDecoration(
                            color: trackColor,
                            borderRadius: BorderRadius.circular(kLensSize / 2),
                          ),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: kLensDuration,
                      curve: Curves.easeOutCubic,
                      left: travel * fraction,
                      top: 0,
                      width: kLensSize,
                      height: kLensSize,
                      child: RepaintBoundary(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 400),
                          builder: (BuildContext context, double m, _) =>
                              SizedBox.square(
                                dimension: kLensSize,
                                child: GlassSurface(
                                  key: const ValueKey<String>('progress-lens'),
                                  borderRadius: kGlassCapsule,
                                  finish: GlassFinish.clear,
                                  labelled: false,
                                  materialize: m,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
