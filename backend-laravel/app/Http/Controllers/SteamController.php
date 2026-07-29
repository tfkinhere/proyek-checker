<?php

namespace App\Http\Controllers;

use App\Models\Game;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class SteamController extends Controller
{
    private const LINK_TTL_SECONDS = 600;
    private const OPENID_ENDPOINT = 'https://steamcommunity.com/openid/login';

    /** Create a one-time Steam OpenID link for the currently signed-in Firebase user. */
    public function startLink(Request $request)
    {
        $publicUrl = rtrim((string) config('services.steam.public_url'), '/');
        if (!str_starts_with($publicUrl, 'https://')) {
            return response()->json([
                'status' => 'error',
                'message' => 'STEAM_PUBLIC_URL harus berupa URL HTTPS publik sebelum Steam dapat dihubungkan.',
            ], 503);
        }

        $token = Str::random(64);
        Cache::put($this->linkCacheKey($token), ['user_id' => $request->auth_user->id], self::LINK_TTL_SECONDS);

        $callbackUrl = $publicUrl.'/api/steam/callback?link_token='.urlencode($token);
        $query = http_build_query([
            'openid.ns' => 'http://specs.openid.net/auth/2.0',
            'openid.mode' => 'checkid_setup',
            'openid.return_to' => $callbackUrl,
            'openid.realm' => $publicUrl.'/',
            'openid.identity' => 'http://specs.openid.net/auth/2.0/identifier_select',
            'openid.claimed_id' => 'http://specs.openid.net/auth/2.0/identifier_select',
        ]);

        return response()->json([
            'status' => 'success',
            'link_token' => $token,
            'authorization_url' => self::OPENID_ENDPOINT.'?'.$query,
            'expires_in' => self::LINK_TTL_SECONDS,
        ]);
    }

    /** Steam redirects here after the user approves (or cancels) sign-in. */
    public function callback(Request $request)
    {
        $token = (string) $request->query('link_token');
        $link = Cache::get($this->linkCacheKey($token));
        if (!$link) {
            return $this->callbackPage('Callback Steam sudah kedaluwarsa. Kembali ke aplikasi dan buat koneksi baru.', false);
        }

        if (($request->query('openid_mode') ?? null) === 'cancel') {
            Cache::forget($this->linkCacheKey($token));
            return $this->callbackPage('Login Steam dibatalkan dari halaman Steam. Silakan coba lagi dari aplikasi.', false);
        }

        $claimedId = (string) $request->query('openid_claimed_id');
        if (!$claimedId || !$this->isValidOpenIdResponse($request) || !preg_match('#^https://steamcommunity\.com/openid/id/(\d{17})$#', $claimedId, $matches)) {
            Cache::forget($this->linkCacheKey($token));
            return $this->callbackPage('Steam tidak dapat memverifikasi koneksi akun. Silakan kembali ke aplikasi dan coba lagi.', false);
        }

        $user = User::find($link['user_id']);
        if (!$user) {
            Cache::forget($this->linkCacheKey($token));
            return $this->callbackPage('Akun aplikasi tidak ditemukan. Silakan login kembali.', false);
        }

        $steamId = $matches[1];
        $alreadyLinked = User::where('steam_id', $steamId)->whereKeyNot($user->id)->exists();
        if ($alreadyLinked) {
            Cache::forget($this->linkCacheKey($token));
            return $this->callbackPage('Akun Steam ini sudah terhubung ke akun aplikasi lain.', false);
        }

        $user->update(['steam_id' => $steamId]);
        Cache::put($this->linkCacheKey($token), ['user_id' => $user->id, 'connected' => true], 120);

        return $this->callbackPage('Akun Steam berhasil dihubungkan. Anda dapat kembali ke aplikasi ini.', true);
    }

    /** Flutter polls this endpoint after opening the system browser. */
    public function linkStatus(Request $request, string $token)
    {
        $link = Cache::get($this->linkCacheKey($token));
        if (!$link || $link['user_id'] !== $request->auth_user->id) {
            return response()->json(['status' => 'expired', 'connected' => false], 404);
        }

        return response()->json([
            'status' => 'success',
            'connected' => (bool) ($link['connected'] ?? false),
            'steam_connected' => (bool) $request->auth_user->fresh()->steam_id,
        ]);
    }

    public function status(Request $request)
    {
        return response()->json([
            'status' => 'success',
            'connected' => (bool) $request->auth_user->steam_id,
        ]);
    }

    public function unlink(Request $request)
    {
        $request->auth_user->update(['steam_id' => null]);

        return response()->json(['status' => 'success', 'message' => 'Koneksi Steam diputuskan.']);
    }

    /** Sync a linked account's public Steam wishlist into Saved Content. */
    public function getWishlist(Request $request)
    {
        $user = $request->auth_user;
        $steamId = $user->steam_id;
        if (!$steamId) {
            return response()->json(['status' => 'error', 'message' => 'Hubungkan akun Steam terlebih dahulu.'], 422);
        }

        $url = "https://store.steampowered.com/wishlist/profiles/{$steamId}/wishlistdata/?p=0";

        try {
            $response = Http::acceptJson()->timeout(20)->get($url);
            if ($response->status() === 403) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Profil Steam atau wishlist masih privat. Ubah ke Public lalu sinkronkan ulang.',
                ], 422);
            }

            if ($response->status() === 429) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Permintaan ke Steam dibatasi sementara. Tunggu sebentar lalu coba lagi.',
                ], 429);
            }

            $steamGames = $response->json();
            if (!$response->successful() || !is_array($steamGames)) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Wishlist Steam tidak dapat diambil. Pastikan profil dan wishlist Steam bersifat Public.',
                ], 422);
            }

            $savedGames = [];
            DB::transaction(function () use ($steamGames, $user, &$savedGames) {
                foreach ($steamGames as $appId => $steamGame) {
                    if (!is_array($steamGame) || empty($steamGame['name'])) {
                        continue;
                    }

                    $game = Game::updateOrCreate(
                        ['steam_app_id' => (string) $appId],
                        ['title' => $steamGame['name'], 'banner_url' => $steamGame['capsule'] ?? $steamGame['header'] ?? "https://cdn.akamai.steamstatic.com/steam/apps/{$appId}/header.jpg"],
                    );
                    DB::table('wishlist_histories')->updateOrInsert(
                        ['user_id' => $user->id, 'game_id' => $game->id],
                        ['status' => 'wishlist', 'updated_at' => now(), 'created_at' => now()],
                    );
                    $savedGames[] = $this->gamePayload($game);
                }
            });

            return response()->json(['status' => 'success', 'mode' => 'Saved', 'total_games' => count($savedGames), 'data' => $savedGames]);
        } catch (\Throwable $exception) {
            report($exception);
            $message = str_contains(strtolower($exception->getMessage()), 'timed out')
                ? 'Callback atau sinkronisasi Steam kedaluwarsa. Coba lagi dari awal.'
                : 'Gagal menyinkronkan wishlist Steam. Coba lagi beberapa saat lagi.';

            return response()->json(['status' => 'error', 'message' => $message], 500);
        }
    }

    private function isValidOpenIdResponse(Request $request): bool
    {
        $parameters = [];
        foreach ($request->query() as $key => $value) {
            if ($key === 'link_token') {
                continue;
            }
            // PHP replaces dots in query-string keys with underscores. Steam's
            // OpenID endpoint requires the original dotted parameter names.
            $parameters[str_starts_with($key, 'openid_') ? str_replace('_', '.', $key) : $key] = $value;
        }
        $parameters['openid.mode'] = 'check_authentication';

        try {
            return trim(Http::asForm()->timeout(15)->post(self::OPENID_ENDPOINT, $parameters)->body()) === 'is_valid:true';
        } catch (\Throwable) {
            return false;
        }
    }

    private function linkCacheKey(string $token): string
    {
        return 'steam-link:'.$token;
    }

    private function callbackPage(string $message, bool $success)
    {
        $color = $success ? '#128a60' : '#b42318';
        $safeMessage = e($message);
        return response("<!doctype html><html><head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><title>Steam Connection</title></head><body style=\"font-family:system-ui;max-width:560px;margin:64px auto;padding:24px;line-height:1.5\"><h1 style=\"color:{$color}\">{$safeMessage}</h1><p>Jendela ini boleh ditutup.</p></body></html>");
    }

    private function gamePayload(Game $game): array
    {
        return [
            'id' => $game->id, 'title' => $game->title, 'name' => $game->title,
            'steam_app_id' => $game->steam_app_id, 'app_id' => $game->steam_app_id,
            'banner_url' => $game->banner_url, 'min_specs' => $game->min_specs ?? [], 'rec_specs' => $game->rec_specs ?? [],
            'min_os' => $game->min_os, 'min_cpu' => $game->min_cpu, 'min_gpu' => $game->min_gpu,
            'rec_os' => $game->rec_os, 'rec_cpu' => $game->rec_cpu, 'rec_gpu' => $game->rec_gpu,
            'status_kelayakan' => 'Siap Dicek',
        ];
    }
}
