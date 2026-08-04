<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Game;
use App\Models\UserSpec;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class HomeController extends Controller
{
    public function index(Request $request)
    {
        try {
            // 1. Ambil data user dari middleware satpam Firebase
            $user = $request->auth_user;
            if (!$user) {
                throw new \Exception("User Firebase tidak ditemukan di middleware.");
            }

            // 2. Tarik spek user yang statusnya AKTIF (is_active = 1 atau true)
            $activeSpec = \App\Models\UserSpec::where('user_id', $user->id)
                ->where('is_active', true)
                ->latest('id')
                ->first();

            // 3. Jika belum punya spek, tampilkan nilai awal tanpa menyimpannya.
            if (!$activeSpec) {
                $activeSpec = (object) [
                    'os' => 'Windows 11 64-bit',
                    'cpu' => 'Intel Core i5-12400F',
                    'gpu' => 'NVIDIA GTX 1650',
                    'ram' => 8,
                    'storage' => 256
                ];
            }

            $games = \App\Models\Game::all();
            $playableGames = [];
            $trendingGames = [];

            foreach ($games as $game) {
                $evaluation = $this->evaluateCompatibility($activeSpec, $game);
                if ($evaluation['status'] !== 'not_compatible') {
                    $playableGames[] = [
                        'id' => $game->id,
                        'title' => $game->title,
                        'banner_url' => $game->banner_url,
                        'steam_app_id' => $game->steam_app_id,
                        'status' => $evaluation['status_label'],
                        'status_key' => $evaluation['status'],
                        'reason' => $evaluation['reason'],
                        'score' => $evaluation['score'],
                        'min_specs' => $game->min_specs,
                        'rec_specs' => $game->rec_specs,
                        'min_os' => $game->min_os,
                        'min_cpu' => $game->min_cpu,
                        'min_gpu' => $game->min_gpu,
                        'rec_os' => $game->rec_os,
                        'rec_cpu' => $game->rec_cpu,
                        'rec_gpu' => $game->rec_gpu,
                    ];
                }

                $trendingGames[] = [
                    'id' => $game->id,
                    'title' => $game->title,
                    'banner_url' => $game->banner_url,
                    'steam_app_id' => $game->steam_app_id,
                    'current_players' => $this->getSteamCurrentPlayers((string) $game->steam_app_id),
                    'trending_score' => 0,
                    'min_specs' => $game->min_specs,
                    'rec_specs' => $game->rec_specs,
                    'min_os' => $game->min_os,
                    'min_cpu' => $game->min_cpu,
                    'min_gpu' => $game->min_gpu,
                    'rec_os' => $game->rec_os,
                    'rec_cpu' => $game->rec_cpu,
                    'rec_gpu' => $game->rec_gpu,
                ];
            }

            usort($playableGames, fn ($a, $b) => $b['score'] <=> $a['score']);
            usort($trendingGames, fn ($a, $b) => $b['current_players'] <=> $a['current_players']);

            $trendingGames = array_values(array_filter($trendingGames, fn ($game) => (int) ($game['current_players'] ?? 0) > 0));

            // 5. Kirim respons sukses ke Flutter
            return response()->json([
                'status' => 'success',
                'data' => [
                    'user_active_specs' => [
                        'os' => $activeSpec->os,
                        'cpu' => $activeSpec->cpu,
                        'gpu' => $activeSpec->gpu,
                        'ram' => (int) $activeSpec->ram,
                        'storage' => (int) $activeSpec->storage,
                    ],
                    'playable_games' => $playableGames,
                    'trending_games' => array_slice($trendingGames, 0, 10),
                ]
            ], 200);

        } catch (\Throwable $e) {
            Log::error('Gagal memuat beranda.', [
                'user_id' => $request->auth_user?->id,
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Gagal memuat beranda.',
            ], 500);
        }
    }

    // Tambah game ke wishlist
public function addWishlist(Request $request)
{
    try {
        $user = $request->auth_user;
        if (!$user) throw new \Exception("User tidak ditemukan.");

        $validated = $request->validate([
            'game_id' => ['required', 'integer', 'exists:games,id'],
        ]);

        $gameId = (int) $validated['game_id'];
        $game = \App\Models\Game::find($gameId);
        if (!$game) {
            return response()->json(['status' => 'error', 'message' => 'Game tidak ditemukan.'], 404);
        }

        // Cek apakah sudah ada, kalau sudah skip
        $exists = \DB::table('wishlist_histories')
            ->where('user_id', $user->id)
            ->where('game_id', $gameId)
            ->first();

        if ($exists) {
            return response()->json(['status' => 'exists', 'message' => 'Game sudah ada di wishlist.'], 200);
        }

        DB::table('wishlist_histories')->insert([
            'user_id'    => $user->id,
            'game_id'    => $gameId,
            'status'     => 'wishlist',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Log::info('Wishlist ditambahkan.', [
            'user_id' => $user->id,
            'game_id' => $gameId,
        ]);

        return response()->json(['status' => 'success', 'message' => 'Game berhasil disimpan!'], 201);

    } catch (\Throwable $e) {
        Log::error('Gagal menambah wishlist.', [
            'user_id' => $request->auth_user?->id,
            'message' => $e->getMessage(),
        ]);

        return response()->json(['status' => 'error', 'message' => 'Gagal menyimpan game ke wishlist.'], 500);
    }
}

// Ambil semua game yang sudah di-wishlist user
public function getWishlist(Request $request)
{
    try {
        $user = $request->auth_user;
        if (!$user) throw new \Exception("User tidak ditemukan.");

        $wishlist = \DB::table('wishlist_histories')
            ->join('games', 'wishlist_histories.game_id', '=', 'games.id')
            ->where('wishlist_histories.user_id', $user->id)
            ->select(
                'games.id',
                'games.title',
                'games.banner_url',
                'games.steam_app_id',
                'games.min_specs',
                'games.rec_specs',
                'games.min_os',
                'games.min_cpu',
                'games.min_gpu',
                'games.rec_os',
                'games.rec_cpu',
                'games.rec_gpu',
                'wishlist_histories.status',
                'wishlist_histories.created_at as saved_at'
            )
            ->orderBy('wishlist_histories.created_at', 'desc')
            ->get()
            ->map(function ($game) {
                // Konsisten dengan format respons Steam/Flutter.
                $game->app_id = $game->steam_app_id;
                $game->name = $game->title;
                $game->min_specs = json_decode($game->min_specs ?? '{}', true) ?: [];
                $game->rec_specs = json_decode($game->rec_specs ?? '{}', true) ?: [];
                return $game;
            })
            ->values();

        Log::info('Wishlist diambil.', [
            'user_id' => $user->id,
            'total_games' => $wishlist->count(),
        ]);

        return response()->json(['status' => 'success', 'data' => $wishlist], 200);

    } catch (\Throwable $e) {
        Log::error('Gagal mengambil wishlist.', [
            'user_id' => $request->auth_user?->id,
            'message' => $e->getMessage(),
        ]);

        return response()->json(['status' => 'error', 'message' => 'Gagal mengambil Saved Content.'], 500);
    }
}

public function removeWishlist(Request $request)
{
    try {
        $user = $request->auth_user;
        if (!$user) throw new \Exception("User tidak ditemukan.");

        $validated = $request->validate([
            'game_id' => ['required', 'integer', 'exists:games,id'],
        ]);

        $gameId = (int) $validated['game_id'];

        DB::table('wishlist_histories')
            ->where('user_id', $user->id)
            ->where('game_id', $gameId)
            ->delete();

        Log::info('Wishlist dihapus.', [
            'user_id' => $user->id,
            'game_id' => $gameId,
        ]);

        return response()->json(['status' => 'success', 'message' => 'Game dihapus dari wishlist.'], 200);
    } catch (\Throwable $e) {
        Log::error('Gagal menghapus wishlist.', [
            'user_id' => $request->auth_user?->id,
            'message' => $e->getMessage(),
        ]);

        return response()->json(['status' => 'error', 'message' => 'Gagal menghapus game dari wishlist.'], 500);
    }
}


    public function allGames()
{
    $games = \App\Models\Game::all()->map(function ($game) {
        return [
            'id'           => $game->id,
            'title'        => $game->title,
            'banner_url'   => $game->banner_url,
            'steam_app_id' => $game->steam_app_id,
            'min_specs'    => $game->min_specs,
            'rec_specs'    => $game->rec_specs,
            'min_os'       => $game->min_os,
            'min_cpu'      => $game->min_cpu,
            'min_gpu'      => $game->min_gpu,
            'rec_os'       => $game->rec_os,
            'rec_cpu'      => $game->rec_cpu,
            'rec_gpu'      => $game->rec_gpu,
        ];
    });

    return response()->json([
        'status' => 'success',
        'data'   => $games,
    ], 200);
}

    public function activeSpec(Request $request)
    {
        $user = $request->auth_user;
        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'User tidak ditemukan.',
            ], 401);
        }

        $activeSpec = UserSpec::where('user_id', $user->id)
            ->where('is_active', true)
            ->latest('id')
            ->first();

        if (!$activeSpec) {
            return response()->json([
                'status' => 'success',
                'data' => null,
                'message' => 'Belum ada spesifikasi aktif di server.',
            ], 200);
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'os' => $activeSpec->os,
                'cpu' => $activeSpec->cpu,
                'gpu' => $activeSpec->gpu,
                'ram' => (int) $activeSpec->ram,
                'storage' => (int) $activeSpec->storage,
                'is_active' => (bool) $activeSpec->is_active,
                'updated_at' => $activeSpec->updated_at?->toIso8601String(),
            ],
        ], 200);
    }

    public function updateSpec(Request $request)
    {
        $validated = $request->validate([
            'os' => ['required', 'string', 'max:150'],
            'cpu' => ['required', 'string', 'max:150'],
            'gpu' => ['required', 'string', 'max:150'],
            'ram' => ['required', 'integer', 'min:1', 'max:512'],
            'storage' => ['required', 'integer', 'min:1', 'max:100000'],
        ]);

        try {
            $user = $request->auth_user;
            if (!$user) {
                throw new \Exception("User Firebase tidak terdeteksi saat simpan spek.");
            }

            // Nonaktifkan semua spek lama milik user ini
            \App\Models\UserSpec::where('user_id', $user->id)
                ->update(['is_active' => false]);

            // Simpan spek baru dari inputan Flutter
            $spec = \App\Models\UserSpec::create([
                'user_id' => $user->id,
                'os' => $validated['os'],
                'cpu' => $validated['cpu'],
                'gpu' => $validated['gpu'],
                'ram' => $validated['ram'],
                'storage' => $validated['storage'],
                'is_active' => true, // Set langsung aktif
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Spesifikasi berhasil disimpan!',
                'data' => $spec
            ], 200);

        } catch (\Throwable $e) {
            Log::error('Gagal menyimpan spesifikasi.', [
                'user_id' => $request->auth_user?->id,
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Gagal menyimpan spesifikasi.',
            ], 500);
}
    }

    private function evaluateCompatibility(object $spec, Game $game): array
    {
        $minimum = $game->min_specs ?? [];
        $recommended = $game->rec_specs ?? [];
        $reasons = [];
        $cpuScore = $this->cpuScore($spec->cpu);
        $cpuMin = $this->cpuScore($game->min_cpu);
        $cpuRec = $this->cpuScore($game->rec_cpu);
        $gpuScore = $this->gpuScore($spec->gpu);
        $gpuMin = $this->gpuScore($game->min_gpu);
        $gpuRec = $this->gpuScore($game->rec_gpu);

        if (!is_array($minimum) || !isset($minimum['ram'], $minimum['storage'])) {
            return [
                'status' => 'not_compatible',
                'status_label' => 'Tidak Kompatibel',
                'reason' => 'Data minimum game belum lengkap.',
                'score' => 0,
            ];
        }

        if ((int) $spec->ram < (int) $minimum['ram']) {
            $reasons[] = 'RAM belum cukup untuk minimum game.';
        }

        if ((int) $spec->storage < (int) $minimum['storage']) {
            $reasons[] = 'Storage belum cukup untuk minimum game.';
        }

        $osMatch = str_contains(strtolower($game->min_os ?? ''), 'windows')
            ? str_contains(strtolower($spec->os ?? ''), 'windows')
            : true;
        if (!$osMatch) {
            $reasons[] = 'Sistem operasi belum sesuai.';
        }

        $meetsMinimum = (int) $spec->ram >= (int) $minimum['ram']
            && (int) $spec->storage >= (int) $minimum['storage']
            && $osMatch
            && $cpuScore >= $cpuMin
            && $gpuScore >= $gpuMin;

        if (!$meetsMinimum) {
            $status = 'not_compatible';
            $statusLabel = 'Tidak Kompatibel';

            if (empty($reasons)) {
                $reasons[] = 'Spesifikasi minimum belum terpenuhi.';
            }

            return [
                'status' => $status,
                'status_label' => $statusLabel,
                'reason' => 'Alasan: '.implode(' ', $reasons),
                'score' => 0,
            ];
        }

        if ($cpuScore < $cpuMin) {
            $reasons[] = 'CPU belum memenuhi kebutuhan minimum.';
        } elseif ($cpuScore < $cpuRec) {
            $reasons[] = 'CPU sudah cukup, tetapi masih belum sampai level rekomendasi.';
        }

        if ($gpuScore < $gpuMin) {
            $reasons[] = 'GPU belum memenuhi kebutuhan minimum.';
        } elseif ($gpuScore < $gpuRec) {
            $reasons[] = 'GPU sudah cukup, tetapi masih belum sampai level rekomendasi.';
        }

        $status = 'not_compatible';
        $statusLabel = 'Tidak Kompatibel';
        $score = 60;

        $cpuAboveRecommendation = $cpuScore >= $cpuRec;
        $gpuAboveRecommendation = $gpuScore >= $gpuRec;

        if ($cpuAboveRecommendation && $gpuAboveRecommendation) {
            $status = 'perfect';
            $statusLabel = 'Pasti Lancar';
            $score = 100;
        } elseif ($cpuScore >= $cpuMin && $gpuScore >= $gpuMin) {
            $status = 'playable';
            $statusLabel = 'Bisa Dicoba';
            $score = 75;
        }

        $reason = empty($reasons)
            ? 'Spesifikasi Anda memenuhi kebutuhan game.'
            : 'Alasan: '.implode(' ', $reasons);

        return [
            'status' => $status,
            'status_label' => $statusLabel,
            'reason' => $reason,
            'score' => max(0, $score),
        ];
    }

    private function cpuScore(?string $cpu): int
    {
        $value = strtolower($cpu ?? '');
        $scores = [
            'pentium 4' => 10, 'i3-560' => 30, 'i5-750' => 40, 'i3-3250' => 45,
            'i3-6300' => 55, 'i5-3470' => 65, 'i5-3570' => 68, 'i5-4460' => 72,
            'i7-3770' => 75, 'i7-4770' => 85, 'i5-8400' => 88, 'i7-6700' => 92,
            'i7-8700' => 105, 'ryzen 3 3300' => 88, 'ryzen 5 1500' => 75,
            'ryzen 5 1600' => 82, 'ryzen 5 3600' => 105, 'ryzen 7 3700' => 115,
            'ryzen 5 5600' => 130, 'ryzen 7 5700' => 140, 'ryzen 7 5800' => 145,
            'ryzen 5 7600' => 155, 'ryzen 7 7700' => 170, 'ryzen 7 7800' => 185,
            'ryzen 9' => 190, 'i3-10100' => 78, 'i3-12100' => 100, 'i3-13100' => 105,
            'i5-10400' => 95, 'i5-11400' => 105, 'i5-12400' => 115, 'i5-13600' => 160,
            'i5-14600' => 170, 'i7-10700' => 120, 'i7-11700' => 130, 'i7-12700' => 160,
            'i7-13700' => 185, 'i7-14700' => 195, 'i9' => 210,
            'i9-14900hx' => 200, 'i9-13980hx' => 195, 'i9-12900hx' => 185,
            'i7-14700hx' => 185, 'i7-13700hx' => 180, 'i7-12700h' => 170,
            'i7-11800h' => 150, 'i7-10870h' => 140, 'i7-13620h' => 165,
            'i7-1260p' => 130, 'i5-13500h' => 140, 'i5-13420h' => 135,
            'i5-12500h' => 130, 'i5-1240p' => 120, 'i5-11400h' => 112,
            'i5-10300h' => 95, 'i3-1125g4' => 72, 'i3-1115g4' => 68,
            'core ultra 7 155h' => 175, 'core ultra 5 125h' => 160,
            'ryzen 9 7945hx' => 200, 'ryzen 9 7940hx' => 195, 'ryzen 9 7940hs' => 190,
            'ryzen 9 6900hx' => 175, 'ryzen 7 8845hs' => 185, 'ryzen 7 7840hs' => 180,
            'ryzen 7 7735hs' => 170, 'ryzen 7 6800h' => 165, 'ryzen 7 5800h' => 150,
            'ryzen 7 7730u' => 145, 'ryzen 7 5700u' => 130, 'ryzen 5 7640hs' => 170,
            'ryzen 5 7535hs' => 160, 'ryzen 5 6600h' => 150, 'ryzen 5 5600h' => 140,
            'ryzen 5 5625u' => 132, 'ryzen 5 5500u' => 120, 'ryzen 5 7520u' => 95,
            'ryzen 5 7430u' => 110, 'ryzen 3 7320u' => 78, 'ryzen 3 5300u' => 85,
            'ryzen 3 3200u' => 60, 'ryzen 7 5800u' => 140,
            'intel core i3' => 78, 'intel core i5' => 110, 'intel core i7' => 140, 'intel core i9' => 190,
            'amd ryzen 3' => 85, 'amd ryzen 5' => 115, 'amd ryzen 7' => 145, 'amd ryzen 9' => 190,
        ];

        return $this->lookupScore($value, $scores);
    }

    private function gpuScore(?string $gpu): int
    {
        $value = strtolower($gpu ?? '');
        $scores = [
            'directx 8' => 5, 'gt 640' => 20, 'gtx 460' => 25, 'gtx 660' => 35,
            'gtx 970' => 50, 'gtx 1060' => 60, 'gtx 1070' => 68, 'gtx 1080' => 78,
            'gtx 1650' => 48, 'gtx 1660' => 58, 'rtx 2060' => 75, 'rtx 2070' => 85,
            'rtx 2080' => 95, 'rtx 3050' => 65, 'rtx 3060' => 82, 'rtx 3070' => 100,
            'rtx 3080' => 115, 'rtx 3090' => 125, 'rtx 4060' => 90, 'rtx 4070' => 115,
            'rtx 4080' => 140, 'rtx 4090' => 160, 'rx 470' => 45, 'rx 480' => 50,
            'rx 570' => 48, 'rx 580' => 55, 'rx 590' => 58, 'rx 5500' => 62,
            'rx 5600' => 72, 'rx 5700' => 80, 'rx 6600' => 88, 'rx 6700' => 105,
            'rx 6800' => 118, 'rx 6900' => 125, 'rx 6950' => 130, 'rx 7600' => 92,
            'rx 7700' => 108, 'rx 7800' => 120, 'rx 7900' => 145, 'arc a380' => 40,
            'arc a580' => 65, 'arc a750' => 82, 'arc a770' => 90, 'integrated' => 10,
            'iris xe' => 15, 'vega integrated' => 15,
            'gtx 1650 super' => 55, 'gtx 1660 super' => 70, 'rtx 3060 ti' => 90,
            'rtx 4070 super' => 125, 'rx 6650 xt' => 95, 'rx 6750 xt' => 110,
            'rtx 4090 laptop' => 155, 'rtx 4080 laptop' => 148, 'rtx 4070 laptop' => 125,
            'rtx 4060 laptop' => 102, 'rtx 4050 laptop' => 82, 'rtx 3080 ti laptop' => 130,
            'rtx 3080 laptop' => 126, 'rtx 3070 ti laptop' => 118, 'rtx 3070 laptop' => 110,
            'rtx 3060 laptop' => 95, 'rtx 3050 ti laptop' => 72, 'rtx 3050 laptop' => 62,
            'gtx 1650 laptop' => 42, 'gtx 1660 ti laptop' => 60, 'gtx 1050 ti laptop' => 32,
            'mx550' => 22, 'mx450' => 18, 'mx350' => 15, 'mx250' => 12,
            'rx 7900m' => 145, 'rx 7800m' => 138, 'rx 7700s' => 126, 'rx 7600s' => 108,
            'rx 6850m' => 132, 'rx 6800m' => 126, 'rx 6700m' => 118, 'rx 6650m' => 112,
            'rx 6600m' => 105, 'rx 6500m' => 70, 'rx 5600m' => 75, 'rx 5500m' => 60,
            'vega 8' => 20, 'vega 7' => 18, 'vega 6' => 14, 'iris xe graphics' => 18,
            'arc a770m' => 98, 'arc a730m' => 90, 'arc a570m' => 80, 'arc a550m' => 70,
            'arc a370m' => 55,
        ];

        return $this->lookupScore($value, $scores);
    }

    private function lookupScore(string $value, array $scores): int
    {
        uksort($scores, fn ($left, $right) => strlen($right) <=> strlen($left));

        foreach ($scores as $needle => $score) {
            if (str_contains($value, $needle)) {
                return $score;
            }
        }

        return 0;
    }

    private function getSteamCurrentPlayers(string $steamAppId): int
    {
        return Cache::remember("steam-current-players:{$steamAppId}", now()->addMinutes(30), function () use ($steamAppId) {
            try {
                $response = Http::acceptJson()
                    ->timeout(10)
                    ->get("https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/", [
                        'appid' => $steamAppId,
                    ]);

                if (!$response->successful()) {
                    return 0;
                }

                $playerCount = $response->json('response.player_count');
                return is_numeric($playerCount) ? (int) $playerCount : 0;
            } catch (\Throwable) {
                return 0;
            }
        });
    }
}
