<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\GameScraperController;

// Rute untuk Python (Input Data)
Route::post('/games/scrape-v2', [GameScraperController::class, 'storeV2']);

// Rute untuk Flutter (Ambil Data)
Route::post('/games/check', [GameScraperController::class, 'checkGame']);