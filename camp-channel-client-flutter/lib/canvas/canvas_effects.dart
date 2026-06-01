/// Canvas effects library - ported from PC client's html-in-canvas technology.
///
/// Includes:
/// - FluidBackground: Animated fluid gradient background (Three.js WebGL → CustomPainter)
/// - ParticleSystem: Floating particles with connecting lines (Canvas2D → CustomPainter)
/// - ParticleBurst: Burst particle effect for like actions (Canvas2D → CustomPainter)
/// - Gallery3DCarousel: 3D rotating image carousel (Three.js → Transform3D)
/// - MoodShader: Breathing glass / glitch card effects (Three.js shader → CustomPainter)
library canvas_effects;

export 'fluid_background.dart';
export 'particle_system.dart';
export 'particle_burst.dart';
export 'gallery_3d_carousel.dart';
export 'mood_shader.dart';
export 'fog_shader.dart';
export 'scratch_card.dart';
export 'weather_effects.dart';
