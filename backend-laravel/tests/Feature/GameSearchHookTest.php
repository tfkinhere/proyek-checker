<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GameSearchHookTest extends TestCase
{
    use RefreshDatabase;

    public function test_search_hook_imports_missing_game_from_steam_fallback(): void
    {
        Http::fake([
            'https://api.steampowered.com/ISteamApps/GetAppList/v2/' => Http::response([], 503),
            'https://steamcommunity.com/actions/SearchApps/*' => Http::response([
                ['appid' => 570, 'name' => 'Dota 2'],
                ['appid' => 730, 'name' => 'Counter-Strike 2'],
            ], 200),
        ]);

        $response = $this->getJson('/api/games/search?query=dota');

        $response->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('source', 'steam');

        $this->assertDatabaseHas('games', [
            'steam_app_id' => '570',
            'title' => 'Dota 2',
        ]);
    }
}
