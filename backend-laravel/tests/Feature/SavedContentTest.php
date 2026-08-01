<?php

namespace Tests\Feature;

use App\Models\Game;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class SavedContentTest extends TestCase
{
    use RefreshDatabase;

    public function test_saved_content_lifecycle_works_for_authenticated_user(): void
    {
        Http::fake([
            'https://identitytoolkit.googleapis.com/v1/accounts:lookup*' => Http::response([
                'users' => [[
                    'localId' => 'firebase-saved-1',
                    'email' => 'saved@example.com',
                    'displayName' => 'Saved User',
                ]],
            ], 200),
        ]);

        config(['services.firebase.api_key' => 'test-key']);

        $game = Game::create([
            'steam_app_id' => '654321',
            'title' => 'Saved Content Game',
            'banner_url' => 'https://example.com/banner.jpg',
            'min_specs' => ['ram' => 8, 'storage' => 256],
            'rec_specs' => ['ram' => 16, 'storage' => 512],
            'min_os' => 'Windows 10',
            'min_cpu' => 'Intel i5',
            'min_gpu' => 'GTX 1060',
            'rec_os' => 'Windows 11',
            'rec_cpu' => 'Intel i7',
            'rec_gpu' => 'RTX 3060',
        ]);

        $headers = ['Authorization' => 'Bearer test-token', 'Accept' => 'application/json'];

        $addResponse = $this->withHeaders($headers)->postJson('/api/wishlist/add', [
            'game_id' => $game->id,
        ]);
        $addResponse->assertStatus(201);

        $listResponse = $this->withHeaders($headers)->getJson('/api/wishlist');
        $listResponse->assertStatus(200);
        $this->assertCount(1, $listResponse->json('data'));

        $removeResponse = $this->withHeaders($headers)->deleteJson('/api/wishlist/remove', [
            'game_id' => $game->id,
        ]);
        $removeResponse->assertStatus(200);

        $emptyResponse = $this->withHeaders($headers)->getJson('/api/wishlist');
        $emptyResponse->assertStatus(200);
        $this->assertSame([], $emptyResponse->json('data'));
    }
}