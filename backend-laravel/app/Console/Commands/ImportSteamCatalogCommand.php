<?php

namespace App\Console\Commands;

use App\Models\Game;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

class ImportSteamCatalogCommand extends Command
{
    protected $signature = 'steam:import-catalog {--limit=300 : Jumlah game minimal yang diimpor}';

    protected $description = 'Impor katalog game dari Steam ke tabel games';

    public function handle(): int
    {
        $limit = max(1, (int) $this->option('limit'));

        $this->info("Mengambil daftar aplikasi Steam (target: {$limit} game)...");

        $response = Http::acceptJson()
            ->timeout(40)
            ->get('https://api.steampowered.com/ISteamApps/GetAppList/v2/');

        if (!$response->successful()) {
            $this->error('Gagal mengambil app list dari Steam API.');
            return self::FAILURE;
        }

        $apps = $response->json('applist.apps');
        if (!is_array($apps)) {
            $this->error('Format respons Steam API tidak valid.');
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
}
