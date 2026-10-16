import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:g1455/g1455.dart';

/// The finish choices the Lab offers. [auto] leaves the host to pick one.
enum LabFinish {
  auto('Auto', null),
  dark('Dark', GlassFinish.regularDark),
  light('Light', GlassFinish.regularLight),
  clear('Clear', GlassFinish.clear),
  frosted('Frosted', GlassFinish.frosted);

  const LabFinish(this.label, this.glassFinish);

  final String label;

  /// The finish handed to `GlassHost`, or null to let the host choose.
  final GlassFinish? glassFinish;
}

/// Every knob the Lab page turns, and the host values they derive.
///
/// `App` listens to this and rebuilds the single `GlassHost` from it.
class LabSettings extends ChangeNotifier {
  static const double defaultDropStretch = 0.12;
  static const double maxDropStretch = 0.5;

  LabFinish _finish = LabFinish.auto;
  bool _reduceTransparency = false;
  bool _cheapCeiling = false;
  bool _ripple = false;
  double _dropStretch = defaultDropStretch;
  bool _press = true;
  bool _adaptive = true;
  bool _highContrast = false;
  bool _debugOutlines = false;
  bool _glassRows = false;

  LabFinish get finish => _finish;
  bool get reduceTransparency => _reduceTransparency;
  bool get cheapCeiling => _cheapCeiling;
  bool get ripple => _ripple;
  double get dropStretch => _dropStretch;
  bool get press => _press;
  bool get adaptive => _adaptive;
  bool get highContrast => _highContrast;
  bool get debugOutlines => _debugOutlines;
  bool get glassRows => _glassRows;

  void setFinish(LabFinish value) {
    if (_finish == value) return;
    _finish = value;
    notifyListeners();
  }

  void setReduceTransparency(bool value) {
    if (_reduceTransparency == value) return;
    _reduceTransparency = value;
    notifyListeners();
  }

  void setCheapCeiling(bool value) {
    if (_cheapCeiling == value) return;
    _cheapCeiling = value;
    notifyListeners();
  }

  void setRipple(bool value) {
    if (_ripple == value) return;
    _ripple = value;
    notifyListeners();
  }

  void setDropStretch(double value) {
    final double clamped = value.clamp(0, maxDropStretch).toDouble();
    if (_dropStretch == clamped) return;
    _dropStretch = clamped;
    notifyListeners();
  }

  void setPress(bool value) {
    if (_press == value) return;
    _press = value;
    notifyListeners();
  }

  void setAdaptive(bool value) {
    if (_adaptive == value) return;
    _adaptive = value;
    notifyListeners();
  }

  void setHighContrast(bool value) {
    if (_highContrast == value) return;
    _highContrast = value;
    notifyListeners();
  }

  /// Turns the package's surface outlines on or off.
  ///
  /// [debugPaintGlassSurfaces] is read at paint time, so already-built
  /// surfaces only pick it up after a repaint; in debug builds with a running
  /// app, a reassemble forces that. The reassemble is skipped when there is no
  /// root element yet (plain unit tests, or before `runApp`).
  void setDebugOutlines(bool value) {
    if (_debugOutlines == value) return;
    _debugOutlines = value;
    _applyDebugOutlines();
    notifyListeners();
  }

  void setGlassRows(bool value) {
    if (_glassRows == value) return;
    _glassRows = value;
    notifyListeners();
  }

  GlassTierChoice get tier => GlassTierPolicy(
    reduceTransparency: _reduceTransparency,
    ceiling: _cheapCeiling ? GlassTier.cheap : null,
  ).choose();

  GlassRipple? get glassRipple => _ripple ? const GlassRipple() : null;

  GlassDropMotion get dropMotion => _dropStretch == 0
      ? GlassDropMotion.none
      : GlassDropMotion(maxStretch: _dropStretch);

  GlassPress get glassPress => _press ? const GlassPress() : GlassPress.none;

  GlassAdaptive? get glassAdaptive => _adaptive ? const GlassAdaptive() : null;

  /// `true` to force high contrast, otherwise null so the OS setting applies.
  bool? get glassHighContrast => _highContrast ? true : null;

  bool get hasChanges =>
      _finish != LabFinish.auto ||
      _reduceTransparency ||
      _cheapCeiling ||
      _ripple ||
      _dropStretch != defaultDropStretch ||
      !_press ||
      !_adaptive ||
      _highContrast ||
      _debugOutlines ||
      _glassRows;

  void reset() {
    if (!hasChanges) return;
    final bool hadOutlines = _debugOutlines;
    _finish = LabFinish.auto;
    _reduceTransparency = false;
    _cheapCeiling = false;
    _ripple = false;
    _dropStretch = defaultDropStretch;
    _press = true;
    _adaptive = true;
    _highContrast = false;
    _debugOutlines = false;
    _glassRows = false;
    if (hadOutlines) _applyDebugOutlines();
    notifyListeners();
  }

  void _applyDebugOutlines() {
    debugPaintGlassSurfaces = _debugOutlines;
    if (!kDebugMode) return;
    final WidgetsBinding binding = WidgetsBinding.instance;
    if (binding.rootElement == null) return;
    // Not awaited: it completes after the next frame.
    binding.reassembleApplication();
  }
}
