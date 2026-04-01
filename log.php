<?php
// bib usage logger — append-only JSON lines
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); exit; }

$data = json_decode(file_get_contents('php://input'), true);
if (!$data || !isset($data['ev'])) { http_response_code(400); exit; }

$log = [
    'ts' => (new DateTimeImmutable('now', new DateTimeZone('America/Sao_Paulo')))->format('c'),
    'ip' => hash('sha256', ($_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR']) . date('Y-m')), // hashed monthly for privacy
    'ua' => substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 200),
    'ev' => substr($data['ev'], 0, 50),
];
// Optional fields
foreach (['ref','tr','q','src'] as $k) {
    if (isset($data[$k])) $log[$k] = substr((string)$data[$k], 0, 100);
}

$dir = __DIR__ . '/logs';
if (!is_dir($dir)) mkdir($dir, 0755, true);
$file = $dir . '/' . date('Y-m-d') . '.jsonl';
file_put_contents($file, json_encode($log, JSON_UNESCAPED_UNICODE) . "\n", FILE_APPEND | LOCK_EX);

http_response_code(204);
