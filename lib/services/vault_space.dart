/// Which vault a PIN opens.
///
/// * [real]  – the owner's actual vault.
/// * [decoy] – an optional, separate vault opened by the decoy PIN. It uses its
///   own encryption key and folder and starts empty. Disclosed in onboarding,
///   settings and the store listing ("decoy PIN / fake vault").
enum VaultSpace { real, decoy }
