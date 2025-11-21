<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Profile;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    // Show a user's profile (users can view their own, admins can view anyone's)
    public function show($id)
    {
        $user = User::with('profile')->findOrFail($id);
        
        // Check authorization: user can view own profile or admin can view any
        if (auth()->id() !== $user->id && !auth()->user()->isAdmin()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        
        return response()->json($user->profile);
    }

    // Update or create a user's profile (users can only update their own)
    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);
        
        // Check authorization: users can only update their own profile
        if (auth()->id() !== $user->id) {
            return response()->json(['message' => 'You can only update your own profile'], 403);
        }

        $validated = $request->validate([
            'name'     => 'nullable|string',
            'phone'    => 'nullable|string',
            'gender'   => 'nullable|string',
            'birthdate'=> 'nullable|date',
            'address'  => 'nullable|string',
            'avatar'   => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        // Update user name if provided
        if (isset($validated['name'])) {
            $user->name = $validated['name'];
            $user->save();
        }

        // Handle avatar upload
        if ($request->hasFile('avatar')) {
            $avatarPath = $request->file('avatar')->store('avatars', 'public');
            $validated['avatar'] = $avatarPath;
        }

        // Update profile data
        $profileData = array_diff_key($validated, ['name' => null]);
        if (!empty($profileData)) {
            $profile = $user->profile ?: new Profile(['user_id' => $user->id]);
            $profile->fill($profileData);
            $profile->save();
        }

        return response()->json([
            'message' => 'Profile saved successfully!',
            'user' => $user->load('profile')
        ]);
    }

    // Delete a user's profile (users can only delete their own)
    public function destroy($id)
    {
        $user = User::findOrFail($id);
        
        // Check authorization: users can only delete their own profile
        if (auth()->id() !== $user->id) {
            return response()->json(['message' => 'You can only delete your own profile'], 403);
        }

        if ($user->profile) {
            $user->profile->delete();
        }

        return response()->json(['message' => 'Profile deleted successfully!']);
    }
}
