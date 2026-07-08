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
            DB::table('games')->insert([
                'app_id' => $appId, // Simpan app_id ke kolom baru
                'title' => $gameName,
                'min_os' => $minimum['os'] ?? null,
                'min_cpu' => json_encode($minimum['cpu'] ?? []),
                'min_ram' => $minimum['ram_gb'] ?? null,
                'min_gpu' => json_encode($minimum['gpu'] ?? []),
                'min_storage' => $minimum['storage_gb'] ?? null,
                
                'rec_os' => $recommended['os'] ?? null,
                'rec_cpu' => json_encode($recommended['cpu'] ?? []),
                'rec_ram' => $recommended['ram_gb'] ?? null,
                'rec_gpu' => json_encode($recommended['gpu'] ?? []),
                'rec_storage' => $recommended['storage_gb'] ?? null,
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
        $game = DB::table('games')->where('app_id', $appId)->first();

        if ($game) {
            $minCpu = json_decode($game->min_cpu, true);
            $game->min_cpu = is_array($minCpu) ? implode(', ', $minCpu) : $game->min_cpu;
            
            $minGpu = json_decode($game->min_gpu, true);
            $game->min_gpu = is_array($minGpu) ? implode(', ', $minGpu) : $game->min_gpu;

            $recCpu = json_decode($game->rec_cpu, true);
            $game->rec_cpu = is_array($recCpu) ? implode(', ', $recCpu) : $game->rec_cpu;

            $recGpu = json_decode($game->rec_gpu, true);
            $game->rec_gpu = is_array($recGpu) ? implode(', ', $recGpu) : $game->rec_gpu;

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