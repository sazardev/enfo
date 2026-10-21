import 'package:enfo/tv/tv_focus_hint.dart';
import 'package:enfo/tv/tv_mode.dart';
import 'package:enfo/ui/atoms/bouncy_tap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    TvMode.debugIsTv = null;
    TvFocusHint.reset();
  });

  test('TV safe padding keeps 5% / 3.5% away from the edges', () {
    TvMode.debugIsTv = true;
    final media = const MediaQueryData(
      size: Size(960, 540),
      padding: EdgeInsets.zero,
    );
    final safe = TvMode.mergeSafePadding(media);
    expect(safe.left, closeTo(48, 0.01));
    expect(safe.right, closeTo(48, 0.01));
    expect(safe.top, closeTo(18.9, 0.01));
    expect(safe.bottom, closeTo(18.9, 0.01));
  });

  test('safe padding never shrinks what the system already reserved', () {
    TvMode.debugIsTv = true;
    final media = const MediaQueryData(
      size: Size(960, 540),
      padding: EdgeInsets.fromLTRB(60, 2, 10, 40),
    );
    final safe = TvMode.mergeSafePadding(media);
    expect(safe.left, 60);
    expect(safe.top, closeTo(18.9, 0.01));
    expect(safe.right, closeTo(48, 0.01));
    expect(safe.bottom, 40);
  });

  testWidgets('a focused BouncyTap publishes its label and activates with OK',
      (tester) async {
    TvMode.debugIsTv = true;
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BouncyTap(
              autofocus: true,
              focusLabel: 'Play',
              onTap: () => taps++,
              child: const SizedBox(width: 80, height: 80),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(TvFocusHint.current.value, 'Play');
    expect(TvFocusHint.visible.value, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(taps, 1);
  });

  test('clearing an old hint cannot erase a newer focus label', () {
    TvFocusHint.show('Play');
    TvFocusHint.show('Settings');
    TvFocusHint.clear('Play');
    expect(TvFocusHint.current.value, 'Settings');
    TvFocusHint.clear('Settings');
    expect(TvFocusHint.current.value, isNull);
  });
}
