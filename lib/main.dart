import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/notes_repository.dart';
import 'services/settings_service.dart';
import 'services/vault_storage.dart';

/// GizliAlan — transparent personal vault (notes & files).
///
/// PLAY COMPLIANCE (honest):
/// - Not spyware / stalkerware.
/// - No SMS intercept, Accessibility Service, Device Admin, or
///   Notification Listener for stealth.
/// - Dual launcher: optional decoy calculator + "GizliAlan Kasa" activity.
/// - Default storage: hide-in-app-documents; AES optional.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final settings = await SettingsService.create();
  final auth = AuthService();
  final vault = VaultStorage();
  final notes = NotesRepository();

  // Intent extra from second launcher activity (Private Vault).
  const directVault =
      bool.fromEnvironment('DIRECT_VAULT', defaultValue: false);

  runApp(GizliAlanApp(
    settings: settings,
    auth: auth,
    vault: vault,
    notes: notes,
    preferDirectVault: directVault,
  ));
}
