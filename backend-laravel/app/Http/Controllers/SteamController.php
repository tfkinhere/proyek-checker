<?php

namespace App\Http\Controllers;

use App\Jobs\SyncSteamWishlistJob;
use App\Models\Game;
use App\Models\User;
use App\Services\SteamWishlistSyncService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
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
        Log::info('Steam link dimulai.', [
            'user_id' => $request->auth_user->id,
            'link_token' => $token,
        ]);

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
        Log::info('Steam berhasil dihubungkan.', [
            'user_id' => $user->id,
            'steam_id' => $steamId,
        ]);

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
        Log::info('Steam diputuskan.', ['user_id' => $request->auth_user->id]);

        return response()->json(['status' => 'success', 'message' => 'Koneksi Steam diputuskan.']);
    }

    /** Sync a linked account's public Steam wishlist into Saved Content. */
    public function getWishlist(Request $request, SteamWishlistSyncService $service)
    {
        $user = $request->auth_user;
        $steamId = $user->steam_id;
        if (!$steamId) {
            return response()->json(['status' => 'error', 'message' => 'Hubungkan akun Steam terlebih dahulu.'], 422);
        }

        $driver = (string) config('queue.default', 'sync');

        if ($driver === 'sync') {
            $result = $service->sync($user);

            return response()->json([
                'status' => 'success',
                'message' => 'Wishlist Steam berhasil disinkronkan.',
                'mode' => $result['mode'] ?? 'Saved',
                'data' => $result['games'] ?? [],
                'total_games' => $result['total_games'] ?? 0,
            ], 200);
        }

        $syncToken = Str::random(64);
        Cache::put($this->wishlistSyncCacheKey($syncToken), [
            'status' => 'queued',
            'user_id' => $user->id,
            'steam_id' => $steamId,
            'queued_at' => now()->toIso8601String(),
        ], self::LINK_TTL_SECONDS);

        SyncSteamWishlistJob::dispatch($user->id, $syncToken);

        Log::info('Sinkronisasi wishlist Steam dimasukkan ke queue.', [
            'user_id' => $user->id,
            'steam_id' => $steamId,
            'sync_token' => $syncToken,
            'queue_driver' => $driver,
        ]);

        return response()->json([
            'status' => 'queued',
            'message' => 'Sinkronisasi wishlist Steam sedang diproses di background.',
            'sync_token' => $syncToken,
            'poll_interval_seconds' => 3,
        ], 202);
    }

    public function wishlistStatus(Request $request, string $token)
    {
        $sync = Cache::get($this->wishlistSyncCacheKey($token));
        if (!$sync || (int) ($sync['user_id'] ?? 0) !== (int) $request->auth_user->id) {
            return response()->json([
                'status' => 'expired',
                'connected' => false,
                'message' => 'Status sinkronisasi wishlist Steam sudah kedaluwarsa.',
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $sync,
        ]);
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

    private function wishlistSyncCacheKey(string $token): string
    {
        return 'steam-wishlist-sync:'.$token;
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
