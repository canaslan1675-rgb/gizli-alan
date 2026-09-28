import '../flavor.dart';
import 'settings_service.dart';

/// Single place that answers "is GizliAlan Pro active?".
///
/// * Builds with the Pro UI stub ([Flavor.hasProStub], i.e. `full` test
///   builds): a local test switch on the Pro screen ("Pro'yu simüle et").
/// * `play`: Google Play Billing subscription (`ProBilling`), cached in
///   [SettingsService.playProActive] and re-checked with Play on start.
class ProEntitlement {
  const ProEntitlement._();

  /// Whether Pro can be obtained in this build at all (Pro UI exists).
  static bool get available =>
      Flavor.hasProStub || Flavor.current == AppFlavor.play;

  /// Pro is sold through Google Play Billing (paywall) in this build.
  static bool get viaPlayBilling => !Flavor.hasProStub;

  /// Whether Pro is active right now. Re-evaluated on every read, so a
  /// lapsed entitlement immediately switches Pro-only features back off.
  static bool isActive(SettingsService s) =>
      viaPlayBilling ? s.playProActive : s.proStubActive;

  /// The calculator's ⓘ button is hidden only while the user opted in AND
  /// Pro is active. If Pro lapses the icon reappears; the opt-in is kept.
  static bool hideCalculatorInfo(SettingsService s) =>
      s.hideCalcInfoIcon && isActive(s);

  /// Delete originals after import: free in every flavor (play included),
  /// only while the user opted in. Uses the system delete confirmation
  /// (MediaStore.createDeleteRequest / SAF), no storage permission.
  static bool deleteOriginalAfterImport(SettingsService s) =>
      s.deleteOriginalAfterImport;
}
