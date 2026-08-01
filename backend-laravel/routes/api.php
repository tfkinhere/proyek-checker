<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\GameScraperController;
use App\Http\Controllers\SteamController;
use App\Http\Controllers\HomeController;

Route::get('/health', function () {
    return response()->json([
        'status' => 'success',
        'message' => 'API sehat dan siap digunakan.',
        'timestamp' => now()->toIso8601String(),
        'environment' => config('app.env'),
    ]);
})->middleware('throttle:api-general');

Route::get('/docs', function () {
    return response()->json([
        'status' => 'success',
        'message' => 'Dokumentasi endpoint API Game Checker.',
        'endpoints' => [
            ['method' => 'GET', 'path' => '/api/health', 'auth' => false, 'description' => 'Pengecekan kesehatan API.'],
            ['method' => 'GET', 'path' => '/up', 'auth' => false, 'description' => 'Health check bawaan Laravel untuk Azure App Service.'],
            ['method' => 'GET', 'path' => '/api/home', 'auth' => true, 'description' => 'Data beranda, spek aktif, playable games, dan trending games.'],
            ['method' => 'POST', 'path' => '/api/specs/update', 'auth' => true, 'description' => 'Menyimpan spesifikasi PC/Laptop aktif.'],
            ['method' => 'POST', 'path' => '/api/wishlist/add', 'auth' => true, 'description' => 'Menambahkan game ke Saved Content.'],
            ['method' => 'DELETE', 'path' => '/api/wishlist/remove', 'auth' => true, 'description' => 'Menghapus game dari Saved Content.'],
            ['method' => 'GET', 'path' => '/api/wishlist', 'auth' => true, 'description' => 'Mengambil Saved Content user aktif.'],
            ['method' => 'POST', 'path' => '/api/steam/link', 'auth' => true, 'description' => 'Memulai koneksi Steam OpenID.'],
            ['method' => 'GET', 'path' => '/api/steam/link/{token}', 'auth' => true, 'description' => 'Memeriksa status koneksi Steam.'],
            ['method' => 'GET', 'path' => '/api/steam/status', 'auth' => true, 'description' => 'Status Steam user saat ini.'],
            ['method' => 'POST', 'path' => '/api/steam/unlink', 'auth' => true, 'description' => 'Memutus koneksi Steam.'],
            ['method' => 'POST', 'path' => '/api/steam/wishlist', 'auth' => true, 'description' => 'Memulai sinkronisasi wishlist Steam melalui queue.'],
            ['method' => 'GET', 'path' => '/api/steam/wishlist/{token}', 'auth' => true, 'description' => 'Memeriksa status sinkronisasi wishlist Steam.'],
        ],
    ]);
})->middleware('throttle:api-general');

Route::post('/games/scrape-v2', [GameScraperController::class, 'storeV2'])->middleware('throttle:api-general');
Route::post('/games/check', [GameScraperController::class, 'checkGame'])->middleware('throttle:api-general');
Route::get('/games/all', [HomeController::class, 'allGames'])->middleware('throttle:api-general');
Route::get('/steam/callback', [SteamController::class, 'callback'])->middleware('throttle:steam-link');

Route::middleware(['firebase.auth', 'throttle:api-general'])->group(function () {
    Route::get('/home', [HomeController::class, 'index']);
    Route::post('/specs/update', [HomeController::class, 'updateSpec'])->middleware('throttle:wishlist-write');
    Route::post('/wishlist/add', [HomeController::class, 'addWishlist'])->middleware('throttle:wishlist-write');
    Route::delete('/wishlist/remove', [HomeController::class, 'removeWishlist'])->middleware('throttle:wishlist-write');
    Route::get('/wishlist', [HomeController::class, 'getWishlist']);
    Route::post('/steam/link', [SteamController::class, 'startLink'])->middleware('throttle:steam-link');
    Route::get('/steam/link/{token}', [SteamController::class, 'linkStatus'])->middleware('throttle:steam-link-status');
    Route::get('/steam/status', [SteamController::class, 'status']);
    Route::post('/steam/unlink', [SteamController::class, 'unlink']);
    Route::post('/steam/wishlist', [SteamController::class, 'getWishlist'])->middleware('throttle:steam-sync');
    Route::get('/steam/wishlist/{token}', [SteamController::class, 'wishlistStatus'])->middleware('throttle:steam-sync');
});
