<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\SteamWishlistSyncService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class SyncSteamWishlistJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public function __construct(
        public int $userId,
        public string $syncToken,
    ) {
    }

    public function handle(SteamWishlistSyncService $service): void
    {
        $cacheKey = $this->cacheKey();
        Cache::put($cacheKey, array_merge(Cache::get($cacheKey, []), [
            'status' => 'processing',
            'started_at' => now()->toIso8601String(),
        ]), now()->addMinutes(15));

        $user = User::find($this->userId);
        if (!$user) {
            $message = 'Akun tidak ditemukan saat sinkronisasi wishlist Steam.';
            Cache::put($cacheKey, [
                'status' => 'failed',
                'message' => $message,
                'finished_at' => now()->toIso8601String(),
            ], now()->addMinutes(15));
            Log::warning($message, ['user_id' => $this->userId, 'sync_token' => $this->syncToken]);
            return;
        }

        try {
            $result = $service->sync($user);
            Cache::put($cacheKey, [
                'status' => 'completed',
                'mode' => $result['mode'] ?? 'Saved',
                'total_games' => $result['total_games'] ?? 0,
                'finished_at' => now()->toIso8601String(),
            ], now()->addMinutes(15));
        } catch (\Throwable $exception) {
            Cache::put($cacheKey, [
                'status' => 'failed',
                'message' => $exception->getMessage(),
                'finished_at' => now()->toIso8601String(),
            ], now()->addMinutes(15));
            Log::error('Sync wishlist Steam gagal.', [
                'user_id' => $this->userId,
                'sync_token' => $this->syncToken,
                'message' => $exception->getMessage(),
            ]);
            throw $exception;
        }
    }

    private function cacheKey(): string
    {
        return 'steam-wishlist-sync:'.$this->syncToken;
    }
}