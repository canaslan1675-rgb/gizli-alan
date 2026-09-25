import '../flavor.dart';
import 'settings_service.dart';

/// Single place that answers "is GizliAlan Pro active?".
///
/// There is no billing yet (#15). In builds with the Pro UI stub
/// ([Flavor.hasProStub], i.e. `full` test builds) the entitlement is a
/// local test switch on the Pro screen ("Pro'yu simüle et"). In `play`
/// (no Pro stub) Pro is never active, so Pro-only options stay locked
/// ("Pro yakında"). When real billing lands, replace [isActive]'s body
/// with the Play Billing purchase state; callers don't change.
class ProEntitlement {
  const ProEntitlement._();

  /// Whether Pro can be obtained in this build at all (Pro UI exists).
  static bool get available => Flavor.hasProStub;

  /// Whether Pro is active right now. Re-evaluated on every read, so a
  /// lapsed entitlement immediately switches Pro-only features back off.
  static bool isActive(SettingsService s) => available && s.proStubActive;

  /// The calculator's ⓘ button is hidden only while the user opted in AND
  /// Pro is active. If Pro lapses the icon reappears; the opt-in is kept.
  static bool hideCalculatorInfo(SettingsService s) =>
      s.hideCalcInfoIcon && isActive(s);
}
