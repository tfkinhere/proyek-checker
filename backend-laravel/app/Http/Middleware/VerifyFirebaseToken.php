<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Models\User;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Exception\Auth\FailedToVerifyToken;
use Illuminate\Support\Facades\Http;

class VerifyFirebaseToken
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $header = $request->header('Authorization');

        if (!$header || !str_starts_with($header, 'Bearer ')) {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthorized: Token Firebase tidak ditemukan!'
            ], 401);
        }

        try {
            $idToken = substr($header, 7);
            $identity = $this->verifyToken($idToken);
            $firebaseUid = $identity['uid'];
            $email = $identity['email'];

            if (!$email) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Token Firebase tidak memuat email pengguna.',
                ], 422);
            }

            $user = User::updateOrCreate(
                ['firebase_uid' => $firebaseUid],
                [
                    'name' => $identity['name'] ?? strtok($email, '@'),
                    'email' => $email,
                    'avatar_url' => $identity['picture'] ?? null,
                    'email_verified_at' => now(),
                ],
            );
        } catch (FailedToVerifyToken) {
            // FailedToVerifyToken extends RuntimeException, jadi HARUS ditangkap
            // sebelum blok \RuntimeException di bawah — kalau tidak, token
            // invalid/kedaluwarsa ikut jadi 503 (server error), bukan 401.
            return response()->json([
                'status' => 'error',
                'message' => 'Token Firebase tidak valid atau sudah kedaluwarsa.',
            ], 401);
        } catch (\RuntimeException $exception) {
            return response()->json([
                'status' => 'error',
                'message' => $exception->getMessage(),
            ], 503);
        } catch (\Throwable $exception) {
            report($exception);
            return response()->json([
                'status' => 'error',
                'message' => 'Token Firebase tidak dapat diverifikasi.',
            ], 401);
        }

        $request->attributes->set('auth_user', $user);
        $request->merge(['auth_user' => $user]);

        return $next($request);
    }

    /**
     * Production uses the Admin SDK. The Firebase Auth REST fallback makes
     * local Laravel usable before a service-account JSON has been installed.
     */
    private function verifyToken(string $idToken): array
    {
        $credentials = config('services.firebase.credentials');
        if ($credentials && is_file($credentials)) {
            $auth = (new Factory)->withServiceAccount($credentials)->createAuth();
            $token = $auth->verifyIdToken($idToken);
            $claims = $token->claims()->all();

            return [
                'uid' => $token->claims()->get('sub'),
                'email' => $claims['email'] ?? null,
                'name' => $claims['name'] ?? null,
                'picture' => $claims['picture'] ?? null,
            ];
        }

        $apiKey = config('services.firebase.api_key');
        if (!$apiKey) {
            throw new \RuntimeException('Firebase Admin atau FIREBASE_API_KEY belum dikonfigurasi di server.');
        }

        $response = Http::acceptJson()
            ->timeout(15)
            ->post('https://identitytoolkit.googleapis.com/v1/accounts:lookup?key='.urlencode($apiKey), [
                'idToken' => $idToken,
            ]);
        $firebaseUser = $response->json('users.0');
        if (!$response->successful() || !is_array($firebaseUser)) {
            throw new FailedToVerifyToken('Token Firebase tidak valid.');
        }

        return [
            'uid' => $firebaseUser['localId'] ?? null,
            'email' => $firebaseUser['email'] ?? null,
            'name' => $firebaseUser['displayName'] ?? null,
            'picture' => $firebaseUser['photoUrl'] ?? null,
        ];
    }
}
