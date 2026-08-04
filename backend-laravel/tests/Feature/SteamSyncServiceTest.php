<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\SteamWishlistSyncService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class SteamSyncServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_sync_wishlist_reads_multiple_pages_and_saves_all_games(): void
    {
        $user = User::factory()->create([
            'firebase_uid' => 'firebase-steam-sync',
            'email' => 'steam-sync@example.com',
            'steam_id' => '76561198000000000',
        ]);

        Http::fake([
            'https://store.steampowered.com/wishlist/profiles/*' => Http::sequence()
                ->push([
                    '570' => ['name' => 'Dota 2', 'capsule' => 'https://cdn.example/dota2.jpg'],
                    '730' => ['name' => 'Counter-Strike 2', 'capsule' => 'https://cdn.example/cs2.jpg'],
                ], 200)
                ->push([
                    '440' => ['name' => 'Team Fortress 2', 'capsule' => 'https://cdn.example/tf2.jpg'],
                ], 200)
                ->push([], 200),
        ]);

        config(['services.steam.wishlist_max_pages' => 8]);

        $result = app(SteamWishlistSyncService::class)->sync($user);

        $this->assertSame('Saved', $result['mode']);
        $this->assertSame(3, $result['total_games']);

        $this->assertDatabaseHas('games', ['steam_app_id' => '570', 'title' => 'Dota 2']);
        $this->assertDatabaseHas('games', ['steam_app_id' => '730', 'title' => 'Counter-Strike 2']);
        $this->assertDatabaseHas('games', ['steam_app_id' => '440', 'title' => 'Team Fortress 2']);

        $this->assertDatabaseCount('wishlist_histories', 3);
    }
}
