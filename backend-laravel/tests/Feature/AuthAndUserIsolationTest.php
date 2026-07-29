<?php

namespace Tests\Feature;

use App\Http\Controllers\HomeController;
use App\Models\Game;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AuthAndUserIsolationTest extends TestCase
{
    use RefreshDatabase;

    public function test_firebase_token_creates_user_using_firebase_uid(): void
    {
        Http::fake([
            'https://identitytoolkit.googleapis.com/v1/accounts:lookup*' => Http::response([
                'users' => [[
                    'localId' => 'firebase-123',
                    'email' => 'alice@example.com',
                    'displayName' => 'Alice',
                    'photoUrl' => 'https://example.com/avatar.png',
                ]],
            ], 200),
        ]);

        config(['services.firebase.api_key' => 'test-key']);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer test-token',
        ])->getJson('/api/home');

        $response->assertStatus(200);
        $this->assertDatabaseHas('users', [
            'firebase_uid' => 'firebase-123',
            'email' => 'alice@example.com',
            'name' => 'Alice',
        ]);
    }

    public function test_wishlist_is_scoped_per_authenticated_user(): void
    {
        $game = Game::create([
            'steam_app_id' => '123456',
            'title' => 'Test Game',
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

        $firstUser = User::factory()->create([
            'firebase_uid' => 'uid-1',
            'email' => 'first@example.com',
        ]);
        $secondUser = User::factory()->create([
            'firebase_uid' => 'uid-2',
            'email' => 'second@example.com',
        ]);

        $controller = new HomeController();

        $addRequest = Request::create('/api/wishlist/add', 'POST', ['game_id' => $game->id]);
        $addRequest->attributes->set('auth_user', $firstUser);
        $addRequest->merge(['auth_user' => $firstUser]);
        $addResponse = $controller->addWishlist($addRequest);
        $this->assertSame(201, $addResponse->getStatusCode());

        $listRequest = Request::create('/api/wishlist', 'GET');
        $listRequest->attributes->set('auth_user', $secondUser);
        $listRequest->merge(['auth_user' => $secondUser]);
        $listResponse = $controller->getWishlist($listRequest);

        $this->assertSame(200, $listResponse->getStatusCode());
        $payload = json_decode($listResponse->getContent(), true);
        $this->assertSame([], $payload['data']);
    }
}
