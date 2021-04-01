import 'dart:io';

String getEnvVar(String key, [Map<String, String>? env]) {
  // First check the specified environment (which likely came from the dotenv
  // package and is specified in a local gitignored file)
  if (env != null) {
    final value = env[key];
    if (value != null) {
      return value;
    }
  } else {
    // If an environment wasn't specified, check the platform's environment
    final value = Platform.environment[key];
    if (value != null) {
      return value;
    }
  }

  throw 'Environment variable not set: $key. Make sure you\'re passing the "env" parameter loaded from the dotenv package if you expect this value to come from a local .env file.';
}
