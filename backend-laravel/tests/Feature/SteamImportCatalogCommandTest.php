<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class SteamImportCatalogCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_import_catalog_command_inserts_limited_games(): void
    {
        Http::fake([
            'https://api.steampowered.com/ISteamApps/GetAppList/v2/' => Http::response([
                'applist' => [
                    'apps' => [
                        ['appid' => 570, 'name' => 'Dota 2'],
                        ['appid' => 730, 'name' => 'Counter-Strike 2'],
                        ['appid' => 440, 'name' => 'Team Fortress 2'],
                        ['appid' => 10, 'name' => 'Counter-Strike'],
                    ],
                ],
            ], 200),
        ]);

        $this->artisan('steam:import-catalog --limit=3')
            ->expectsOutputToContain('Selesai. Total game terimpor/update: 3')
            ->assertExitCode(0);

        $this->assertDatabaseCount('games', 3);
        $this->assertDatabaseHas('games', ['steam_app_id' => '570', 'title' => 'Dota 2']);
        $this->assertDatabaseHas('games', ['steam_app_id' => '730', 'title' => 'Counter-Strike 2']);
        $this->assertDatabaseHas('games', ['steam_app_id' => '440', 'title' => 'Team Fortress 2']);
    }
}
