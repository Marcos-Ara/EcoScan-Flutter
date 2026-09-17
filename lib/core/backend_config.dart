/// Public application identifiers used by the client.
///
/// Firebase Authentication in this codebase still points to the original
/// Auth project unless FIREBASE_API_KEY/FIREBASE_AUTH_DOMAIN are supplied at
/// build time. Firebase Hosting may be a different project.
abstract final class BackendConfig {
  static const firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyBMXRb6XSMES6FRQD1INg0-JjU0SD61iGY',
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

  /// OAuth client of type "Web application".
  ///
  /// Android uses it as serverClientId. Web uses it as clientId. This value is
  /// public, but it must belong to the same Google/Firebase Auth project used
  /// by [firebaseApiKey].
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  // Backwards-compatible alias used by older code/docs.
  static const googleServerClientId = googleWebClientId;

  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
}
