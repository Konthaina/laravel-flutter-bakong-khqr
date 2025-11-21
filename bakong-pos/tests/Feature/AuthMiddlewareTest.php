<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test accessing protected route without token
     */
    public function test_protected_route_without_token()
    {
        $response = $this->getJson('/api/users');

        $response->assertStatus(401)
            ->assertJson([
                'message' => 'Unauthenticated.',
            ]);
    }

    /**
     * Test accessing protected route with valid token
     */
    public function test_protected_route_with_valid_token()
    {
        $user = User::factory()->create();
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/users');

        $response->assertStatus(200);
    }

    /**
     * Test accessing protected route with invalid token
     */
    public function test_protected_route_with_invalid_token()
    {
        $response = $this->withHeader('Authorization', 'Bearer invalid-token')
            ->getJson('/api/users');

        $response->assertStatus(401);
    }

    /**
     * Test login endpoint is public
     */
    public function test_login_endpoint_is_public()
    {
        $response = $this->postJson('/api/auth/login', [
            'email' => 'test@example.com',
            'password' => 'wrongpassword',
        ]);

        // Should return 401 for invalid credentials, not 401 for missing auth
        $response->assertStatus(401)
            ->assertJson([
                'message' => 'Invalid credentials',
            ]);
    }

    /**
     * Test register endpoint is public
     */
    public function test_register_endpoint_is_public()
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'SecurePass@123456',
        ]);

        // Should accept request and validate input, not reject for missing auth
        $response->assertStatus(201);
    }

    /**
     * Test merchant accounts route requires authentication
     */
    public function test_merchant_accounts_requires_authentication()
    {
        $response = $this->getJson('/api/merchant-accounts');

        $response->assertStatus(401);
    }

    /**
     * Test merchant accounts route works with valid token
     */
    public function test_merchant_accounts_with_valid_token()
    {
        $user = User::factory()->create();
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/merchant-accounts');

        $response->assertStatus(200);
    }
}
