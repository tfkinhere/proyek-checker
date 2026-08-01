<?php

namespace App\Services;

use App\Models\Game;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SteamWishlistSyncService
{
    public function sync(User $user): array
    {
        $steamId = $user->steam_id;

        if (!$steamId) {
            throw new \RuntimeException('Hubungkan akun Steam terlebih dahulu.');
        }

        $url = "https://store.steampowered.com/wishlist/profiles/{$steamId}/wishlistdata/?p=0";
        $response = Http::acceptJson()->timeout(20)->get($url);

        if ($response->status() === 403) {
            throw new \RuntimeException('Profil Steam atau wishlist masih privat. Ubah ke Public lalu sinkronkan ulang.');
        }

        if ($response->status() === 429) {
            throw new \RuntimeException('Permintaan ke Steam dibatasi sementara. Tunggu sebentar lalu coba lagi.');
        }

        $steamGames = $response->json();
        if (!$response->successful() || !is_array($steamGames)) {
            throw new \RuntimeException('Wishlist Steam tidak dapat diambil. Pastikan profil dan wishlist Steam bersifat Public.');
        }

        $savedGames = [];

        DB::transaction(function () use ($steamGames, $user, &$savedGames) {
            foreach ($steamGames as $appId => $steamGame) {
                if (!is_array($steamGame) || empty($steamGame['name'])) {
                    continue;
                }

                $game = Game::updateOrCreate(
                    ['steam_app_id' => (string) $appId],
                    [
                        'title' => $steamGame['name'],
                        'banner_url' => $steamGame['capsule'] ?? $steamGame['header'] ?? "https://cdn.akamai.steamstatic.com/steam/apps/{$appId}/header.jpg",
                    ],
                );

                DB::table('wishlist_histories')->updateOrInsert(
                    ['user_id' => $user->id, 'game_id' => $game->id],
                    ['status' => 'wishlist', 'updated_at' => now(), 'created_at' => now()],
                );

                $savedGames[] = [
                    'id' => $game->id,
                    'steam_app_id' => $game->steam_app_id,
                    'title' => $game->title,
                ];
            }
        });

        Log::info('Wishlist Steam tersinkron.', [
            'user_id' => $user->id,
            'steam_id' => $steamId,
            'total_games' => count($savedGames),
        ]);

        return [
            'mode' => 'Saved',
            'total_games' => count($savedGames),
        ];
    }
}