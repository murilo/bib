<?php
// Gemini proxy — keeps API key server-side
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Gemini-Key');
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); echo '{"error":"POST only"}'; exit; }

// User key from header, else server .env
$apiKey = $_SERVER['HTTP_X_GEMINI_KEY'] ?? '';
if (!$apiKey) {
    $envFile = __DIR__ . '/.env';
    if (!file_exists($envFile)) { http_response_code(500); echo '{"error":"no env"}'; exit; }
    foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        if (str_starts_with($line, 'GEMINI_API_KEY=')) {
            $apiKey = trim(substr($line, strlen('GEMINI_API_KEY=')));
            break;
        }
    }
}
if (!$apiKey) { http_response_code(500); echo '{"error":"no key"}'; exit; }

$body = file_get_contents('php://input');
if (!$body) { http_response_code(400); echo '{"error":"empty body"}'; exit; }

// Rate limit: 30 req/min per IP
$ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];
$rateDir = '/tmp/bib-rate';
if (!is_dir($rateDir)) @mkdir($rateDir, 0755, true);
$rateFile = $rateDir . '/' . md5($ip) . '.txt';
$now = time();
$window = [];
if (file_exists($rateFile)) {
    $window = array_filter(explode("\n", file_get_contents($rateFile)), fn($t) => $t && ($now - (int)$t) < 60);
}
if (count($window) >= 30) { http_response_code(429); echo '{"error":"rate limit"}'; exit; }
$window[] = $now;
file_put_contents($rateFile, implode("\n", $window));

$url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=' . urlencode($apiKey);

$ctx = stream_context_create([
    'http' => [
        'method' => 'POST',
        'header' => "Content-Type: application/json\r\n",
        'content' => $body,
        'timeout' => 15,
        'ignore_errors' => true,
    ],
    'ssl' => ['verify_peer' => true, 'verify_peer_name' => true],
]);

$resp = @file_get_contents($url, false, $ctx);
// Extract HTTP status from $http_response_header
$code = 502;
if (isset($http_response_header[0]) && preg_match('/\d{3}/', $http_response_header[0], $m)) {
    $code = (int)$m[0];
}

http_response_code($code);
echo $resp ?: '{"error":"upstream fail"}';
