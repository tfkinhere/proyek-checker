<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\GameScraperController;

Route::post('/games/scrape-v2', [GameScraperController::class, 'storeV2']);