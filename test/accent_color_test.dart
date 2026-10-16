import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/en.dart';
import 'package:gizlialan/l10n/tr.dart';
import 'package:gizlialan/theme.dart';

/// v0.5.2 tester feedback: accent colour presets.
void main() {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  test('unknown / missing value falls back to mint (old look)', () {
    expect(AccentPreset.parse(null), AccentPreset.mint);
    expect(AccentPreset.parse('nope'), AccentPreset.mint);
    expect(AccentPreset.parse('blue'), AccentPreset.blue);
  });

  test('mint preset keeps the v0.5.1 palettes unchanged', () {
    final d = GizliColors.dark.withAccent(AccentPreset.mint);
    final l = GizliColors.light.withAccent(AccentPreset.mint);
    expect(d.accent, GizliColors.dark.accent);
    expect(d.accentDim, GizliColors.dark.accentDim);
    expect(l.accent, GizliColors.light.accent);
    expect(l.calcOpKey, GizliColors.light.calcOpKey);
  });

  test('every preset is readable in light and dark (>= 4.5:1)', () {
    for (final p in AccentPreset.values) {
      final d = GizliColors.dark.withAccent(p);
      final l = GizliColors.light.withAccent(p);
      expect(
        contrast(d.accent, d.bg),
        greaterThanOrEqualTo(4.5),
        reason: '$p dark',
      );
      expect(
        contrast(d.onAccent, d.accent),
        greaterThanOrEqualTo(4.5),
        reason: '$p dark on',
      );
      expect(
        contrast(l.accent, l.bg),
        greaterThanOrEqualTo(4.5),
        reason: '$p light',
      );
      expect(
        contrast(l.onAccent, l.accent),
        greaterThanOrEqualTo(4.5),
        reason: '$p light on',
      );
      expect(GizliTheme.dark(p).colorScheme.primary, d.accent);
      expect(GizliTheme.light(p).colorScheme.primary, l.accent);
    }
  });

  test('labels exist in TR and EN', () {
    for (final m in [en, tr]) {
      expect(m['accentColor'], isNotNull);
      for (final p in AccentPreset.values) {
        expect(m['accent_${p.name}'], isNotNull);
      }
    }
  });
}
