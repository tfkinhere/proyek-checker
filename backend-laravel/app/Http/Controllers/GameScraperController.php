<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Game;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GameScraperController extends Controller
{
    // ========================================================
    // 1. PINTU INPUT: KHUSUS UNTUK PYTHON SCRAPER
    // ========================================================
    public function storeV2(Request $request)
    {
        // Lindungi endpoint ingest dengan shared secret bila SCRAPER_TOKEN diset.
        // Di lokal token boleh kosong; di production wajib diisi.
        $expectedToken = config('services.scraper.token');
        if ($expectedToken && !hash_equals($expectedToken, (string) $request->header('X-Scraper-Token'))) {
            return response()->json([
                'status' => 'error',
                'message' => 'Token scraper tidak valid.',
            ], 401);
        }

        $validated = $request->validate([
            'app_id' => 'required', // Validasi: Wajib kirim app_id
            'game_name' => 'nullable|string|max:255',
            'minimum' => 'required|array',
            'recommended' => 'required|array',
        ]);

        $appId = $validated['app_id'];
        $minimum = $validated['minimum'];
        $recommended = $validated['recommended'];
        $gameName = $validated['game_name'] ?? 'Unknown Game';

        try {
            // Eloquent + cast 'array' meng-encode min_specs/rec_specs otomatis,
            // konsisten dengan searchOrImport dan SteamWishlistSyncService.
            Game::updateOrCreate(
                ['steam_app_id' => (string) $appId],
                [
                    'title' => $gameName,
                    'banner_url' => "https://cdn.akamai.steamstatic.com/steam/apps/{$appId}/header.jpg",
                    'min_specs' => [
                        'ram' => $minimum['ram_gb'] ?? null,
                        'storage' => $minimum['storage_gb'] ?? null,
                    ],
                    'rec_specs' => [
                        'ram' => $recommended['ram_gb'] ?? null,
                        'storage' => $recommended['storage_gb'] ?? null,
                    ],
                    'min_os' => $minimum['os'] ?? null,
                    'min_cpu' => implode(', ', $minimum['cpu'] ?? []),
                    'min_gpu' => implode(', ', $minimum['gpu'] ?? []),
                    'rec_os' => $recommended['os'] ?? null,
                    'rec_cpu' => implode(', ', $recommended['cpu'] ?? []),
                    'rec_gpu' => implode(', ', $recommended['gpu'] ?? []),
                ],
            );

            return response()->json([
                'status' => 'success',
                'message' => 'Data spesifikasi game berhasil disimpan ke database MySQL!'
            ], 201);

        } catch (\Throwable $e) {
            Log::error('Gagal menyimpan data scraper: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal menyimpan ke database: ' . $e->getMessage()
            ], 500);
        }
    }

    // ========================================================
    // 2. PINTU OUTPUT: KHUSUS UNTUK APLIKASI FLUTTER
    // ========================================================
    public function checkGame(Request $request)
    {
        $request->validate([
            'app_id' => 'required'
        ]);

        $appId = $request->input('app_id');

        // MENCARI DATA SPESIFIK BERDASARKAN APP ID
        $game = DB::table('games')->where('steam_app_id', $appId)->first();

        if ($game) {
            $minSpecs = json_decode($game->min_specs ?? '{}', true) ?: [];
            $recSpecs = json_decode($game->rec_specs ?? '{}', true) ?: [];
            $game->app_id = $game->steam_app_id;
            $game->min_ram = $minSpecs['ram'] ?? 0;
            $game->min_storage = $minSpecs['storage'] ?? 0;
            $game->rec_ram = $recSpecs['ram'] ?? 0;
            $game->rec_storage = $recSpecs['storage'] ?? 0;

            return response()->json([
                'status' => 'success',
                'data' => (array) $game
            ], 200);
        }

        // Jika data App ID yang dicari tidak ditemukan
        return response()->json([
            'status' => 'error',
            'message' => 'Game dengan App ID ' . $appId . ' belum ada di database.'
        ], 404);
    }

    public function searchOrImport(Request $request)
    {
        $validated = $request->validate([
            'query' => ['required', 'string', 'min:2', 'max:120'],
        ]);

        $query = trim($validated['query']);

        $localResults = Game::query()
            ->where('title', 'like', "%{$query}%")
            ->orderBy('title')
            ->limit(30)
            ->get();

        if ($localResults->isNotEmpty()) {
            return response()->json([
                'status' => 'success',
                'source' => 'database',
                'data' => $localResults->map(fn (Game $game) => $this->formatGame($game))->values(),
            ]);
        }

        $steamApps = $this->searchSteamApps($query);

        if ($steamApps === []) {
            return response()->json([
                'status' => 'success',
                'source' => 'steam',
                'data' => [],
                'message' => 'Game tidak ditemukan di database lokal maupun Steam.',
            ]);
        }

        $imported = collect($steamApps)
            ->map(function (array $app) {
                $appId = (int) ($app['appid'] ?? 0);
                $name = trim((string) ($app['name'] ?? ''));
                if ($appId <= 0 || $name === '') {
                    return null;
                }

                $game = Game::updateOrCreate(
                    ['steam_app_id' => (string) $appId],
                    [
                        'title' => $name,
                        'banner_url' => "https://cdn.akamai.steamstatic.com/steam/apps/{$appId}/header.jpg",
                        'min_specs' => ['ram' => null, 'storage' => null],
                        'rec_specs' => ['ram' => null, 'storage' => null],
                    ],
                );

                return $this->formatGame($game);
            })
            ->filter()
            ->values();

        return response()->json([
            'status' => 'success',
            'source' => 'steam',
            'data' => $imported,
        ]);
    }

    private function searchSteamApps(string $query): array
    {
        $userAgent = config('app.name', 'GameChecker').'/1.0';

        $response = Http::acceptJson()
            ->timeout(60)
            ->retry(3, 1200, throw: false)
            ->withHeaders([
                'User-Agent' => $userAgent,
            ])
            ->get('https://api.steampowered.com/ISteamApps/GetAppList/v2/');

        if ($response->successful()) {
            $apps = $response->json('applist.apps');
            if (is_array($apps)) {
                return $this->filterSteamApps($apps, $query);
            }
        }

        Log::warning('Steam app list endpoint utama gagal saat hook pencarian, mencoba fallback.', [
            'query' => $query,
            'status' => $response->status(),
        ]);

        $fallback = Http::acceptJson()
            ->timeout(30)
            ->retry(2, 800)
            ->withHeaders([
                'User-Agent' => $userAgent,
            ])
            ->get('https://steamcommunity.com/actions/SearchApps/'.urlencode($query));

        if (! $fallback->successful()) {
            return [];
        }

        $apps = $fallback->json();
        if (! is_array($apps)) {
            return [];
        }

        return $this->filterSteamApps($apps, $query);
    }

    private function filterSteamApps(array $apps, string $query): array
    {
        $needle = mb_strtolower($query);

        $matches = [];
        foreach ($apps as $app) {
            $name = trim((string) ($app['name'] ?? ''));
            if ($name === '') {
                continue;
            }

            if (str_contains(mb_strtolower($name), $needle)) {
                $matches[] = $app;
            }

            if (count($matches) >= 20) {
                break;
            }
        }

        return $matches;
    }

    private function formatGame(Game $game): array
    {
        return [
            'id' => $game->id,
            'title' => $game->title,
            'steam_app_id' => $game->steam_app_id,
            'banner_url' => $game->banner_url,
            'min_specs' => $game->min_specs ?? [],
            'rec_specs' => $game->rec_specs ?? [],
            'min_os' => $game->min_os,
            'min_cpu' => $game->min_cpu,
            'min_gpu' => $game->min_gpu,
            'rec_os' => $game->rec_os,
            'rec_cpu' => $game->rec_cpu,
            'rec_gpu' => $game->rec_gpu,
        ];
    }
}

