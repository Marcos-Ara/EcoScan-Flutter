/// Public client identifiers used by EcoScan.
///
/// These values belong to the same Firebase project used by Hosting and Auth:
/// `ecoscan-ai-e961f`. They are public application identifiers, not admin
/// secrets. Build-time values from `--dart-define-from-file` still override the
/// defaults below.
abstract final class BackendConfig {
  static const firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyAJ2-3rn_a05orGD5NinFZPvmdxF3duyEE',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'ecoscan-ai-e961f',
  );
  static const firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'ecoscan-ai-e961f.firebaseapp.com',
  );
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tekyqhtodsbeqbrvdtqs.supabase.co',
  );
  static const supabasePublicKey = String.fromEnvironment(
    'SUPABASE_PUBLIC_KEY',
    defaultValue: 'sb_publishable_ai4WJqrDkBS7rcebvaS7KA_hpf0hzOP',
  );

  /// OAuth client of type "Web application" from the same Google/Firebase
  /// project. Android uses it as `serverClientId`; Web reads the same client ID
  /// from `web/index.html` and this value is kept as a build-time validation /
  /// native configuration source.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '1403190965-t4i39s47ojq3p1jrolhbenq349tpph45.apps.googleusercontent.com',
  );

  // Backwards-compatible alias used by older code/docs.
  static const googleServerClientId = googleWebClientId;

  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
}
