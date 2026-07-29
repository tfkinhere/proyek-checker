<?php

namespace Tests\Feature;

use App\Http\Controllers\HomeController;
use App\Models\Game;
use App\Models\User;
use App\Models\UserSpec;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Tests\TestCase;

class CompatibilityStatusTest extends TestCase
{
    use RefreshDatabase;

    public function test_high_storage_does_not_make_weak_cpu_gpu_game_pasti_lancar(): void
    {
        $user = User::factory()->create([
            'firebase_uid' => 'uid-compatibility',
            'email' => 'compatibility@example.com',
        ]);

        UserSpec::create([
            'user_id' => $user->id,
            'os' => 'Windows 11 64-bit',
            'cpu' => 'AMD Ryzen 3 3100',
            'gpu' => 'AMD Radeon Vega',
            'ram' => 16,
            'storage' => 420,
            'is_active' => true,
        ]);

        $game = Game::create([
            'steam_app_id' => '999999',
            'title' => 'Storage Heavy Test Game',
            'banner_url' => 'https://example.com/banner.jpg',
            'min_specs' => ['ram' => 8, 'storage' => 200],
            'rec_specs' => ['ram' => 16, 'storage' => 200],
            'min_os' => 'Windows 10 64-bit',
            'min_cpu' => 'AMD Ryzen 3 1200',
            'min_gpu' => 'AMD Radeon RX 560',
            'rec_os' => 'Windows 10 64-bit',
            'rec_cpu' => 'AMD Ryzen 5 3600',
            'rec_gpu' => 'AMD Radeon RX 580',
        ]);

        $request = Request::create('/api/home', 'GET');
        $request->attributes->set('auth_user', $user);
        $request->merge(['auth_user' => $user]);
        $response = (new HomeController())->index($request);

        $this->assertSame(200, $response->getStatusCode());

        $payload = json_decode($response->getContent(), true);
        $this->assertIsArray($payload);
        $this->assertSame('success', $payload['status']);

        $games = $payload['data']['playable_games'];
        $matchedGame = collect($games)->firstWhere('id', $game->id);

        $this->assertNotNull($matchedGame);
        $this->assertSame('playable', $matchedGame['status_key']);
        $this->assertSame('Bisa Dicoba', $matchedGame['status']);
    }
}