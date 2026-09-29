import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'clock_frame.dart';
import 'faces/digit_faces.dart';
import 'faces/gauge_faces.dart';
import 'faces/icon_faces.dart';
import 'faces/motion_faces.dart';
import 'faces/number_faces.dart';
import 'faces/progress_faces.dart';
import 'faces/wonder_faces.dart';

enum ClockCategory {
  progress(Icons.data_usage_rounded),
  numbers(Icons.pin_rounded),
  icons(Icons.emoji_objects_rounded),
  motion(Icons.animation_rounded);

  const ClockCategory(this.icon);
  final IconData icon;
}

/// Every selectable timer visual. Add a value here + a case in [face] and it
/// shows up in the picker automatically.
enum ClockStyle {
  ring(ClockCategory.progress),
  wavyRing(ClockCategory.progress),
  segments(ClockCategory.progress),
  orbit(ClockCategory.progress),
  pie(ClockCategory.progress),
  kitchen(ClockCategory.progress),
  dots(ClockCategory.progress),
  bar(ClockCategory.progress, aspectRatio: 1.3),
  wavyBar(ClockCategory.progress, aspectRatio: 1.3, animated: true),
  gauge(ClockCategory.progress, aspectRatio: 1.3),
  needle(ClockCategory.progress),
  analog(ClockCategory.progress),
  rings(ClockCategory.progress),
  squircle(ClockCategory.progress),
  columns(ClockCategory.progress, aspectRatio: 1.3),
  vertical(ClockCategory.progress, aspectRatio: 0.7),
  steps(ClockCategory.progress, aspectRatio: 1.6),
  blocks(ClockCategory.progress),
  spiral(ClockCategory.progress),
  slices(ClockCategory.progress),
  pills(ClockCategory.progress, aspectRatio: 1.5),
  hexagon(ClockCategory.progress),
  stairs(ClockCategory.progress, aspectRatio: 1.3),
  candle(ClockCategory.progress, aspectRatio: 0.8, animated: true),
  moon(ClockCategory.progress),
  ruler(ClockCategory.progress, aspectRatio: 1.5),

  digits(ClockCategory.numbers, aspectRatio: 1.5, animated: true),
  minutes(ClockCategory.numbers),
  tiles(ClockCategory.numbers, aspectRatio: 1.6),
  stack(ClockCategory.numbers),
  fill(ClockCategory.numbers, aspectRatio: 1.5),
  capsule(ClockCategory.numbers, aspectRatio: 1.8),
  rollers(ClockCategory.numbers, aspectRatio: 1.6),
  matrix(ClockCategory.numbers, aspectRatio: 1.9, animated: true),
  sevenSeg(ClockCategory.numbers, aspectRatio: 1.8, animated: true),
  flip(ClockCategory.numbers, aspectRatio: 1.7),
  fine(ClockCategory.numbers, aspectRatio: 1.5),
  superscript(ClockCategory.numbers, aspectRatio: 1.3),
  percent(ClockCategory.numbers, aspectRatio: 1.3),
  endTime(ClockCategory.numbers, aspectRatio: 1.4),
  seconds(ClockCategory.numbers, aspectRatio: 1.3),
  tall(ClockCategory.numbers, aspectRatio: 0.55),
  wobble(ClockCategory.numbers, aspectRatio: 1.6, animated: true),
  labeled(ClockCategory.numbers, aspectRatio: 1.7),

  tomato(ClockCategory.icons),
  hourglass(ClockCategory.icons),
  battery(ClockCategory.icons, aspectRatio: 1.8),
  icon(ClockCategory.icons),

  cookie(ClockCategory.motion, animated: true),
  liquid(ClockCategory.motion, animated: true),
  breathe(ClockCategory.motion, animated: true),
  equalizer(ClockCategory.motion, aspectRatio: 1.3, animated: true),
  ripple(ClockCategory.motion, animated: true),
  blob(ClockCategory.motion, animated: true),
  flower(ClockCategory.motion, animated: true),
  sun(ClockCategory.motion, animated: true),
  gears(ClockCategory.motion, animated: true),
  bubbles(ClockCategory.motion, animated: true),
  sunflower(ClockCategory.motion, animated: true),
  fireflies(ClockCategory.motion, animated: true),
  pendulum(ClockCategory.motion, aspectRatio: 1.3, animated: true),
  bounce(ClockCategory.motion, aspectRatio: 1.6, animated: true),
  morph(ClockCategory.motion, animated: true);

  const ClockStyle(
    this.category, {
    this.aspectRatio = 1.0,
    this.animated = false,
  });

  final ClockCategory category;

  /// Width / height of the face's preferred box.
  final double aspectRatio;

  /// Whether the face has ambient motion that needs a running ticker.
  /// Faces without it only repaint when the countdown itself advances.
  final bool animated;

  Widget face(ClockFrame frame, ClockPalette palette) => switch (this) {
        ClockStyle.ring => RingFace(frame: frame, palette: palette),
        ClockStyle.wavyRing => WavyRingFace(frame: frame, palette: palette),
        ClockStyle.segments => SegmentsFace(frame: frame, palette: palette),
        ClockStyle.orbit => OrbitFace(frame: frame, palette: palette),
        ClockStyle.pie => PieFace(frame: frame, palette: palette),
        ClockStyle.kitchen => KitchenFace(frame: frame, palette: palette),
        ClockStyle.dots => DotsFace(frame: frame, palette: palette),
        ClockStyle.bar => BarFace(frame: frame, palette: palette),
        ClockStyle.wavyBar =>
          BarFace(frame: frame, palette: palette, wavy: true),
        ClockStyle.gauge => GaugeFace(frame: frame, palette: palette),
        ClockStyle.needle => NeedleFace(frame: frame, palette: palette),
        ClockStyle.analog => AnalogFace(frame: frame, palette: palette),
        ClockStyle.rings => RingsFace(frame: frame, palette: palette),
        ClockStyle.squircle => SquircleFace(frame: frame, palette: palette),
        ClockStyle.columns => ColumnsFace(frame: frame, palette: palette),
        ClockStyle.vertical => VerticalFace(frame: frame, palette: palette),
        ClockStyle.steps => StepsFace(frame: frame, palette: palette),
        ClockStyle.blocks => BlocksFace(frame: frame, palette: palette),
        ClockStyle.spiral => SpiralFace(frame: frame, palette: palette),
        ClockStyle.slices => SlicesFace(frame: frame, palette: palette),
        ClockStyle.pills => PillsFace(frame: frame, palette: palette),
        ClockStyle.hexagon => HexagonFace(frame: frame, palette: palette),
        ClockStyle.stairs => StairsFace(frame: frame, palette: palette),
        ClockStyle.candle => CandleFace(frame: frame, palette: palette),
        ClockStyle.moon => MoonFace(frame: frame, palette: palette),
        ClockStyle.ruler => RulerFace(frame: frame, palette: palette),
        ClockStyle.digits => DigitsFace(frame: frame, palette: palette),
        ClockStyle.minutes => MinutesFace(frame: frame, palette: palette),
        ClockStyle.tiles => TilesFace(frame: frame, palette: palette),
        ClockStyle.stack => StackFace(frame: frame, palette: palette),
        ClockStyle.fill => FillFace(frame: frame, palette: palette),
        ClockStyle.capsule => CapsuleFace(frame: frame, palette: palette),
        ClockStyle.rollers => RollersFace(frame: frame, palette: palette),
        ClockStyle.matrix => MatrixFace(frame: frame, palette: palette),
        ClockStyle.sevenSeg => SevenSegFace(frame: frame, palette: palette),
        ClockStyle.flip => FlipFace(frame: frame, palette: palette),
        ClockStyle.fine => FineFace(frame: frame, palette: palette),
        ClockStyle.superscript =>
          SuperscriptFace(frame: frame, palette: palette),
        ClockStyle.percent => PercentFace(frame: frame, palette: palette),
        ClockStyle.endTime => EndTimeFace(frame: frame, palette: palette),
        ClockStyle.seconds => SecondsFace(frame: frame, palette: palette),
        ClockStyle.tall => TallFace(frame: frame, palette: palette),
        ClockStyle.wobble => WobbleFace(frame: frame, palette: palette),
        ClockStyle.labeled => LabeledFace(frame: frame, palette: palette),
        ClockStyle.tomato => TomatoFace(frame: frame, palette: palette),
        ClockStyle.hourglass => HourglassFace(frame: frame, palette: palette),
        ClockStyle.battery => BatteryFace(frame: frame, palette: palette),
        ClockStyle.icon => IconFace(frame: frame, palette: palette),
        ClockStyle.cookie => CookieFace(frame: frame, palette: palette),
        ClockStyle.liquid => LiquidFace(frame: frame, palette: palette),
        ClockStyle.breathe => BreatheFace(frame: frame, palette: palette),
        ClockStyle.equalizer => EqualizerFace(frame: frame, palette: palette),
        ClockStyle.ripple => RippleFace(frame: frame, palette: palette),
        ClockStyle.blob => BlobFace(frame: frame, palette: palette),
        ClockStyle.flower => FlowerFace(frame: frame, palette: palette),
        ClockStyle.sun => SunFace(frame: frame, palette: palette),
        ClockStyle.gears => GearsFace(frame: frame, palette: palette),
        ClockStyle.bubbles => BubblesFace(frame: frame, palette: palette),
        ClockStyle.sunflower => SunflowerFace(frame: frame, palette: palette),
        ClockStyle.fireflies => FirefliesFace(frame: frame, palette: palette),
        ClockStyle.pendulum => PendulumFace(frame: frame, palette: palette),
        ClockStyle.bounce => BounceFace(frame: frame, palette: palette),
        ClockStyle.morph => MorphFace(frame: frame, palette: palette),
      };

  /// Next/previous style in declaration order, wrapping around.
  ClockStyle step(int delta) =>
      ClockStyle.values[(index + delta) % ClockStyle.values.length];

  static const _prefsKey = 'clock_style';

  /// Bumped whenever the chosen style is saved, so things that mirror it
  /// (the home-screen widgets) can follow.
  static final changes = ValueNotifier<int>(0);

  static Future<ClockStyle> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_prefsKey);
    return ClockStyle.values.firstWhere(
      (s) => s.name == name,
      orElse: () => ClockStyle.ring,
    );
  }

  static Future<void> save(ClockStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, style.name);
    changes.value++;
  }
}
