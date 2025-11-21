<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\MerchantAccount;

class MerchantAccountController extends Controller
{
    // Store a new merchant account
    public function store(Request $request)
    {
        $validated = $request->validate([
            'account_id'    => 'required|string|unique:merchant_accounts,account_id',
            'merchant_name' => 'nullable|string|max:255',
            'location'      => 'nullable|string|max:255',
            'bakong_token'  => 'nullable|string|max:255',
            'user_id'       => 'required|exists:users,id',
        ]);

        $merchant = MerchantAccount::create($validated);

        return response()->json([
            'message' => '✅ Merchant account added successfully',
            'data'    => $merchant
        ], 201);
    }

    // List all merchant accounts
    public function index()
    {
        $merchants = MerchantAccount::all();

        return response()->json([
            'message' => '✅ Merchant accounts retrieved successfully',
            'data'    => $merchants
        ]);
    }

    // Update a merchant account
    public function update(Request $request, $id)
    {
        $merchant = MerchantAccount::findOrFail($id);

        $validated = $request->validate([
            'account_id'    => 'sometimes|required|string|unique:merchant_accounts,account_id,' . $merchant->id,
            'merchant_name' => 'nullable|string|max:255',
            'location'      => 'nullable|string|max:255',
            'bakong_token'  => 'nullable|string|max:255',
            'user_id'       => 'nullable|exists:users,id',
            'telegram_chat_id'   => 'nullable|string|max:255',
            'telegram_bot_token' => 'nullable|string|max:255',
        ]);

        $merchant->update($validated);

        return response()->json([
            'message' => '✅ Merchant account updated successfully',
            'data'    => $merchant
        ]);
    }

    // (Optional) Show single merchant account
    public function show($id)
    {
        $merchant = MerchantAccount::findOrFail($id);

        return response()->json([
            'message' => '✅ Merchant account retrieved successfully',
            'data'    => $merchant
        ]);
    }

    // (Optional) Delete a merchant account
    public function destroy($id)
    {
        $merchant = MerchantAccount::findOrFail($id);
        $merchant->delete();

        return response()->json([
            'message' => '✅ Merchant account deleted successfully'
        ]);
    }
}
