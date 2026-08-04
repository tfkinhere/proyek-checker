<?php

namespace App\Console\Commands;

use App\Models\Game;
use Illuminate\Console\Command;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Http;

class ImportSteamCatalogCommand extends Command
{
    protected $signature = 'steam:import-catalog {--limit=300 : Jumlah game minimal yang diimpor}';

    protected $description = 'Impor katalog game dari Steam ke tabel games';

    public function handle(): int
    {
        $limit = max(1, (int) $this->option('limit'));

        $this->info("Mengambil daftar aplikasi Steam (target: {$limit} game)...");

        $apps = $this->fetchSteamApps();
        if ($apps === null) {
            return self::FAILURE;
        }

        $imported = 0;
        foreach ($apps as $app) {
            if ($imported >= $limit) {
                break;
            }

            $appId = $app['appid'] ?? null;
            $name = isset($app['name']) ? trim((string) $app['name']) : '';

            if (!$appId || $name === '') {
                continue;
            }

            Game::updateOrCreate(
                ['steam_app_id' => (string) $appId],
                [
                    'title' => $name,
                    'banner_url' => "https://cdn.akamai.steamstatic.com/steam/apps/{$appId}/header.jpg",
                    'min_specs' => ['ram' => null, 'storage' => null],
                    'rec_specs' => ['ram' => null, 'storage' => null],
                ],
            );

            $imported++;

            if ($imported % 50 === 0) {
                $this->line("Progress impor: {$imported}/{$limit}");
            }
        }

        $this->info("Selesai. Total game terimpor/update: {$imported}");

        return self::SUCCESS;
    }

    private function fetchSteamApps(): ?Collection
    {
        $userAgent = (string) config('app.name', 'GameChecker').'/1.0';

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
                return collect($apps);
            }
        }

        $this->warn('Endpoint utama Steam API gagal, mencoba fallback endpoint search...');

        $seedQueries = ['a', 'e', 'i', 'o', 'u', 't', 's', 'r', 'n', 'm', 'c', 'd', 'l', 'p', 'g'];
        $fallbackApps = collect();

        foreach ($seedQueries as $seed) {
            $fallback = Http::acceptJson()
                ->timeout(30)
                ->retry(2, 800, throw: false)
                ->withHeaders([
                    'User-Agent' => $userAgent,
                ])
                ->get('https://steamcommunity.com/actions/SearchApps/'.urlencode($seed));

            if (! $fallback->successful()) {
                continue;
            }

            $apps = $fallback->json();
            if (! is_array($apps)) {
                continue;
            }

            $fallbackApps = $fallbackApps
                ->merge($apps)
                ->filter(fn (array $app) => !empty($app['appid']) && trim((string) ($app['name'] ?? '')) !== '')
                ->unique(fn (array $app) => (string) $app['appid'])
                ->values();

            if ($fallbackApps->count() >= 1200) {
                break;
            }
        }

        if ($fallbackApps->isNotEmpty()) {
            return $fallbackApps
                ->map(fn (array $app) => [
                    'appid' => $app['appid'] ?? null,
                    'name' => $app['name'] ?? '',
                ])
                ->values();
        }

        $status = $response->status();
        $this->error("Gagal mengambil app list dari Steam API. HTTP status: {$status}");

        return null;
    }
}

