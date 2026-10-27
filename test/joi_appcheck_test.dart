import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/joi_service.dart';

void main() {
  test('debug App Check token only in PRO_STUB builds', () {
    const proStub = bool.fromEnvironment('PRO_STUB');
    if (!proStub) {
      // Release / Play config: never a debug token, whatever is defined.
      expect(JoiOnlineConfig.buildDebugToken, isEmpty);
      expect(const JoiOnlineConfig().appCheckDebugToken, isEmpty);
    }
    expect(
      const JoiOnlineConfig(
        apiKey: 'k',
        appId: 'a',
        projectId: 'p',
        appCheckDebugToken: 't',
      ).toMap()['appCheckDebugToken'],
      't',
    );
  });
}
