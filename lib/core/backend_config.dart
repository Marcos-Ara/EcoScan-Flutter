/// Public application identifiers copied from the supplied website.
abstract final class BackendConfig {
  static const firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyBMXRb6XSMES6FRQD1INg0-JjU0SD61iGY',
  );
  static const firebaseProjectId = 'ecoscan-b8b02';
  static const firebaseAuthDomain = 'ecoscan-b8b02.firebaseapp.com';
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tekyqhtodsbeqbrvdtqs.supabase.co',
  );
  static const supabasePublicKey = String.fromEnvironment(
    'SUPABASE_PUBLIC_KEY',
    defaultValue: 'sb_publishable_ai4WJqrDkBS7rcebvaS7KA_hpf0hzOP',
  );
  // Native OAuth IDs were not included in the supplied web project.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
}
