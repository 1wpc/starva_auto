import 'package:envied/envied.dart';

part 'secrets.g.dart';

@Envied(path: '.env')
abstract class AppSecrets {
  @EnviedField(varName: 'STRAVA_CLIENT_ID', obfuscate: true)
  static final String clientId = _AppSecrets.clientId;

  @EnviedField(varName: 'STRAVA_CLIENT_SECRET', obfuscate: true)
  static final String clientSecret = _AppSecrets.clientSecret;
}
