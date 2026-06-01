import 'package:flutter/material.dart';
import '../../canvas/particle_burst.dart';

/// Global particle burst service. Provides access to the burst controller
/// from any widget in the tree, similar to PC's provide/inject pattern.
class BurstService extends InheritedWidget {
  final ParticleBurstController controller;
  final GlobalKey<ParticleBurstOverlayState> overlayKey;

  const BurstService({
    super.key,
    required this.controller,
    required this.overlayKey,
    required super.child,
  });

  static BurstService? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BurstService>();
  }

  static BurstService of(BuildContext context) {
    final service = maybeOf(context);
    assert(service != null, 'BurstService not found in widget tree');
    return service!;
  }

  /// Trigger a particle burst at the given screen coordinates.
  void triggerBurst(double x, double y, {Color? color}) {
    overlayKey.currentState?.triggerBurst(x, y, color: color);
  }

  @override
  bool updateShouldNotify(covariant BurstService oldWidget) => false;
}
