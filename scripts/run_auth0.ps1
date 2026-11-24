# Run FirstStep Mobile against the configured Auth0 Native app.
# Usage:
#   .\scripts\run_auth0.ps1
#   .\scripts\run_auth0.ps1 -ApiBaseUrl http://192.168.1.10:5000
#   .\scripts\run_auth0.ps1 -ApiBaseUrl https://your-backend.onrender.com

param(
  [string]$ApiBaseUrl = "http://10.0.2.2:5000",
  [string]$DeviceId = ""
)

$domain = "dev-0yrs1pb6s37h8s6u.us.auth0.com"
$clientId = "GqPHk4oOClQaMdxwMeLOc15awKEhknkS"
$scheme = "firststep"

$flutterArgs = @(
  "run",
  "-Pauth0Domain=$domain",
  "-Pauth0Scheme=$scheme",
  "--dart-define=AUTH0_DOMAIN=$domain",
  "--dart-define=AUTH0_CLIENT_ID=$clientId",
  "--dart-define=AUTH0_SCHEME=$scheme",
  "--dart-define=API_BASE_URL=$ApiBaseUrl",
  "--dart-define=WEB_APP_URL=https://app.firststepjob.com",
  "--dart-define=AUTH0_GITHUB=false"
)

if ($DeviceId) {
  $flutterArgs += @("-d", $DeviceId)
}

Set-Location (Split-Path $PSScriptRoot -Parent)
flutter @flutterArgs
