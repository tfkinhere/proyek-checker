<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\GameScraperController;
use App\Http\Controllers\SteamController;
use App\Http\Controllers\HomeController;

Route::post('/games/scrape-v2', [GameScraperController::class, 'storeV2']);
Route::post('/games/check', [GameScraperController::class, 'checkGame']);
Route::get('/games/all', [HomeController::class, 'allGames']);
Route::get('/steam/callback', [SteamController::class, 'callback'])->middleware('throttle:10,1');
Route::middleware('firebase.auth')->group(function () {
    Route::get('/home', [HomeController::class, 'index']);
    Route::post('/specs/update', [HomeController::class, 'updateSpec']);
    Route::post('/wishlist/add', [HomeController::class, 'addWishlist']);
    Route::delete('/wishlist/remove', [HomeController::class, 'removeWishlist']);
    Route::get('/wishlist', [HomeController::class, 'getWishlist']);
    Route::post('/steam/link', [SteamController::class, 'startLink'])->middleware('throttle:5,1');
    Route::get('/steam/link/{token}', [SteamController::class, 'linkStatus'])->middleware('throttle:30,1');
    Route::get('/steam/status', [SteamController::class, 'status']);
    Route::post('/steam/unlink', [SteamController::class, 'unlink']);
    Route::post('/steam/wishlist', [SteamController::class, 'getWishlist'])->middleware('throttle:3,1');
});
