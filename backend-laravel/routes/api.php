<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\GameScraperController;
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
        ],
    ]);
})->middleware('throttle:api-general');

Route::post('/games/scrape-v2', [GameScraperController::class, 'storeV2'])->middleware('throttle:api-general');
Route::post('/games/check', [GameScraperController::class, 'checkGame'])->middleware('throttle:api-general');
Route::get('/games/search', [GameScraperController::class, 'searchOrImport'])->middleware('throttle:api-general');
Route::get('/games/all', [HomeController::class, 'allGames'])->middleware('throttle:api-general');

Route::middleware(['firebase.auth', 'throttle:api-general'])->group(function () {
    Route::get('/home', [HomeController::class, 'index']);
    Route::get('/specs/active', [HomeController::class, 'activeSpec']);
    Route::post('/specs/update', [HomeController::class, 'updateSpec'])->middleware('throttle:wishlist-write');
    Route::post('/wishlist/add', [HomeController::class, 'addWishlist'])->middleware('throttle:wishlist-write');
    Route::delete('/wishlist/remove', [HomeController::class, 'removeWishlist'])->middleware('throttle:wishlist-write');
    Route::get('/wishlist', [HomeController::class, 'getWishlist']);
});
