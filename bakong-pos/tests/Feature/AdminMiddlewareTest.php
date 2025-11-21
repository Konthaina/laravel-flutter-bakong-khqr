<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test accessing admin user routes without authentication
     */
    public function test_admin_user_routes_without_auth()
    {
        $response = $this->getJson('/api/users');

        $response->assertStatus(401)
            ->assertJson([
                'message' => 'Unauthenticated.',
            ]);
    }

    /**
     * Test accessing admin user routes as regular user
     */
    public function test_admin_user_routes_as_regular_user()
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/users');

        $response->assertStatus(403)
            ->assertJson([
                'message' => 'Unauthorized. Admin access required.',
            ]);
    }

    /**
     * Test accessing admin user routes as admin
     */
    public function test_admin_user_routes_as_admin()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $token = $admin->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/users');

        $response->assertStatus(200);
    }

    /**
     * Test posting new user as regular user fails
     */
    public function test_create_user_as_regular_user_fails()
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->postJson('/api/users', [
                'name' => 'New User',
                'email' => 'newuser@example.com',
                'password' => 'SecurePass@123456',
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'message' => 'Unauthorized. Admin access required.',
            ]);
    }

    /**
     * Test posting new user as admin succeeds
     */
    public function test_create_user_as_admin_succeeds()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $token = $admin->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->postJson('/api/users', [
                'name' => 'New User',
                'email' => 'newuser@example.com',
                'password' => 'SecurePass@123456',
            ]);

        $response->assertStatus(201);
    }

    /**
     * Test updating user as regular user fails
     */
    public function test_update_user_as_regular_user_fails()
    {
        $user = User::factory()->create(['role' => 'user']);
        $otherUser = User::factory()->create();
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->putJson("/api/users/{$otherUser->id}", [
                'name' => 'Updated Name',
            ]);

        $response->assertStatus(403);
    }

    /**
     * Test updating user as admin succeeds
     */
    public function test_update_user_as_admin_succeeds()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $token = $admin->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->putJson("/api/users/{$user->id}", [
                'name' => 'Updated Name',
                'email' => $user->email,
                'password' => 'UpdatedPass@123456',
            ]);

        $response->assertStatus(200);
    }

    /**
     * Test deleting user as regular user fails
     */
    public function test_delete_user_as_regular_user_fails()
    {
        $user = User::factory()->create(['role' => 'user']);
        $otherUser = User::factory()->create();
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->deleteJson("/api/users/{$otherUser->id}");

        $response->assertStatus(403);
    }

    /**
     * Test deleting user as admin succeeds
     */
    public function test_delete_user_as_admin_succeeds()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $token = $admin->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->deleteJson("/api/users/{$user->id}");

        $response->assertStatus(200);
    }

    /**
     * Test isAdmin helper method
     */
    public function test_is_admin_helper_method()
    {
        $adminUser = User::factory()->create(['role' => 'admin']);
        $regularUser = User::factory()->create(['role' => 'user']);

        $this->assertTrue($adminUser->isAdmin());
        $this->assertFalse($regularUser->isAdmin());
    }
}
