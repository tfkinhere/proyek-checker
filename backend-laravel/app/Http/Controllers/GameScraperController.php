<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class GameScraperController extends Controller
{
    public function storeV2(Request $request)
    {
        // 1. Validasi input dasar untuk memastikan JSON tidak kosong
        $request->validate([
            'minimum' => 'required|array',
            'recommended' => 'required|array'
        ]);

        // Tangkap data spesifikasi dari request
        $minimum = $request->input('minimum');
        $recommended = $request->input('recommended');
        
        // Kita gunakan dummy data dulu untuk nama game atau bisa menangkap app_id jika dikirim
        $gameName = $request->input('game_name', 'Unknown Game');

        DB::beginTransaction();
        try {
            // 2. Simpan atau Update data ke tabel 'games'
            // Catatan: Sesuaikan nama kolom dengan migrasi yang kamu buat di Minggu 1
            DB::table('games')->insert([
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
}