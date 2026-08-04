<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class SpecSyncTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_save_and_read_active_spec(): void
    {
        Http::fake([
            'https://identitytoolkit.googleapis.com/v1/accounts:lookup*' => Http::response([
                'users' => [[
                    'localId' => 'firebase-spec-1',
                    'email' => 'spec@example.com',
                    'displayName' => 'Spec User',
                ]],
            ], 200),
        ]);

        config(['services.firebase.api_key' => 'test-key']);

        $headers = [
            'Authorization' => 'Bearer test-token',
            'Accept' => 'application/json',
        ];

        $save = $this->withHeaders($headers)->postJson('/api/specs/update', [
            'os' => 'Windows 11 64-bit',
            'cpu' => 'Intel Core i5-12400F',
            'gpu' => 'NVIDIA GTX 1650',
            'ram' => 16,
            'storage' => 512,
        ]);

        $save->assertStatus(200)->assertJsonPath('status', 'success');

        $active = $this->withHeaders($headers)->getJson('/api/specs/active');
        $active->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.cpu', 'Intel Core i5-12400F')
            ->assertJsonPath('data.gpu', 'NVIDIA GTX 1650')
            ->assertJsonPath('data.ram', 16)
            ->assertJsonPath('data.storage', 512)
            ->assertJsonPath('data.is_active', true);
    }
}
