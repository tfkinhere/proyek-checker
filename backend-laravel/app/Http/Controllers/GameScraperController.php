<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class GameScraperController extends Controller
{
    // ========================================================
    // 1. PINTU INPUT: KHUSUS UNTUK PYTHON SCRAPER
    // ========================================================
    public function storeV2(Request $request)
    {
        $request->validate([
            'app_id' => 'required', // Validasi: Wajib kirim app_id
            'minimum' => 'required|array',
            'recommended' => 'required|array'
        ]);

        $appId = $request->input('app_id');
        $minimum = $request->input('minimum');
        $recommended = $request->input('recommended');
        $gameName = $request->input('game_name', 'Unknown Game');

        DB::beginTransaction();
        try {
            DB::table('games')->updateOrInsert([
                'steam_app_id' => $appId,
            ], [
                'title' => $gameName,
                'banner_url' => "https://cdn.akamai.steamstatic.com/steam/apps/{$appId}/header.jpg",
                'min_specs' => json_encode([
                    'ram' => $minimum['ram_gb'] ?? null,
                    'storage' => $minimum['storage_gb'] ?? null,
                ]),
                'rec_specs' => json_encode([
                    'ram' => $recommended['ram_gb'] ?? null,
                    'storage' => $recommended['storage_gb'] ?? null,
                ]),
                'min_os' => $minimum['os'] ?? null,
                'min_cpu' => implode(', ', $minimum['cpu'] ?? []),
                'min_gpu' => implode(', ', $minimum['gpu'] ?? []),
                
                'rec_os' => $recommended['os'] ?? null,
                'rec_cpu' => implode(', ', $recommended['cpu'] ?? []),
                'rec_gpu' => implode(', ', $recommended['gpu'] ?? []),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::commit();
            return response()->json([
                'status' => 'success',
                'message' => 'Data spesifikasi game berhasil disimpan ke database MySQL!'
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
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
}
