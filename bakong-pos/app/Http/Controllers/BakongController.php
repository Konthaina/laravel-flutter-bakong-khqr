<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use GuzzleHttp\Client;
use Piseth\BakongKhqr\BakongKHQR;
use Piseth\BakongKhqr\Models\MerchantInfo;
use App\Models\BakongTransaction;
use App\Models\MerchantAccount;

class BakongController extends Controller
{
    public function getToken()
    {
        $merchant = MerchantAccount::first();
        if (!$merchant || !$merchant->bakong_token) {
            return response()->json(['message' => 'No merchant account or token found'], 404);
        }
        $token = $merchant->bakong_token;
        Cache::put('bakong_token', $token, now()->addMinutes(55));
        return response()->json(['token' => $token]);
    }

    public function generateQR(Request $request)
    {
        try {
            $request->validate([
                'amount' => 'required|numeric|min:0.01',
                'currency' => 'nullable|in:KHR,USD',
            ]);

            $merchant = MerchantAccount::first();
            if (!$merchant || !$merchant->bakong_token) {
                return response()->json([
                    'message' => 'QR generation error',
                    'error' => 'No merchant account or token found in the database.'
                ], 500);
            }

            $qrService = new BakongKHQR($merchant->bakong_token);
            $accountId = $merchant->account_id;

            $currencyInput = strtoupper($request->input('currency', 'KHR'));
            $currencyCode = $currencyInput === 'USD' ? 840 : 116;
            $billNumber = uniqid('txn_');

            $info = new MerchantInfo(
                $accountId,
                $merchant->merchant_name ?? 'Merchant POS',
                $merchant->location ?? 'Phnom Penh',
                $accountId,
                'CADIKHPP'
            );
            $info->amount = $request->amount;
            $info->currency = $currencyCode;
            $info->terminalLabel = 'POS-01';
            $info->storeLabel = $merchant->merchant_name ?? 'Merchant POS';
            $info->billNumber = $billNumber;

            $response = $qrService->generateMerchant($info);

            if (!isset($response->data['qr'])) {
                return response()->json([
                    'message' => 'QR Generation Failed',
                    'bakong_status' => $response->status ?? null
                ], 500);
            }

            $qrString = $response->data['qr'];
            $md5Hash = md5($qrString);

            BakongTransaction::create([
                'bill_number' => $billNumber,
                'user_id' => auth()->id(),
                'amount' => $request->amount,
                'currency' => $currencyInput,
                'merchant_account_id' => $merchant->id,
                'qr_string' => $qrString,
                'md5_hash' => $md5Hash,
                'status' => 'pending'
            ]);

            return response()->json([
                'qr_string' => $qrString,
                'md5' => $md5Hash,
                'bill_number' => $billNumber,
                'merchant_account' => $merchant->account_id
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'QR generation error',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function verifyTransactionByMd5()
    {
        try {
            $merchant = MerchantAccount::first();
            if (!$merchant || !$merchant->bakong_token) {
                return response()->json([
                    'message' => 'No merchant account or token found.',
                    'result' => null
                ]);
            }
            $token = $merchant->bakong_token;
            $client = new Client();

            $tx = BakongTransaction::with('merchantAccount')
                ->where('user_id', auth()->id())
                ->where('status', 'pending')
                ->whereNotNull('md5_hash')
                ->latest('created_at')
                ->first();

            if (!$tx) {
                return response()->json([
                    'message' => 'No pending transactions found.',
                    'result' => null
                ]);
            }

            try {
                $response = $client->post('https://api-bakong.nbc.gov.kh/v1/check_transaction_by_md5', [
                    'headers' => [
                        'Authorization' => 'Bearer ' . $token,
                        'Accept' => 'application/json',
                        'Content-Type' => 'application/json',
                    ],
                    'json' => [
                        'md5' => $tx->md5_hash
                    ]
                ]);

                $raw = $response->getBody()->getContents();
                $data = json_decode($raw, true);

                $result = [
                    'bill' => $tx->bill_number,
                    'md5' => $tx->md5_hash,
                    'raw_response' => $data,
                    'updated' => false,
                ];

                if (isset($data['responseCode']) && $data['responseCode'] === 0 && !empty($data['data'])) {
                    $tx->status = 'success';
                    $tx->completed_at = now();
                    $tx->send_from = $data['data']['fromAccountId'] ?? null;
                    $tx->receive_to = $data['data']['toAccountId'] ?? null;
                    $tx->save();
                    $result['updated'] = true;

                    $merchantInfo = $tx->merchantAccount;

                    $this->sendTelegramAlert(
                        "<b>Mechant POS Payment Success</b>\n"
                        . "Bill No: <code>{$tx->bill_number}</code>\n"
                        . "Merchant Name: <code>{$merchantInfo->merchant_name}</code>\n"
                        . "Account: <code>{$merchantInfo->account_id}</code>\n"
                        . "Amount: <b>{$tx->amount} {$tx->currency}</b>\n"
                        . "From: <code>{$tx->send_from}</code>\n"
                        . "To: <code>{$tx->receive_to}</code>\n"
                        . "MD5: <code>{$tx->md5_hash}</code>\n"
                        . "Date & Time: " . now()->format('d M Y g:i A')
                    );
                }

                return response()->json([
                    'message' => '✅ MD5 Verification Complete (latest only)',
                    'result' => $result
                ]);
            } catch (\Exception $ex) {
                return response()->json([
                    'message' => '❌ Error verifying latest transaction',
                    'bill' => $tx->bill_number,
                    'error' => $ex->getMessage(),
                ]);
            }

        } catch (\Exception $e) {
            return response()->json([
                'message' => '❌ MD5 verification failed',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function updateBakongToken(Request $request)
    {
        // Check if user is admin
        if (!auth()->check() || !auth()->user()->is_admin) {
            return response()->json([
                'message' => 'Unauthorized. Admin access required.',
                'error' => 'Only administrators can update the Bakong token.'
            ], 403);
        }

        $request->validate([
            'token' => 'required|string|min:10'
        ]);

        try {
            $merchant = MerchantAccount::first();
            if (!$merchant) {
                return response()->json([
                    'message' => 'Merchant account not found.',
                    'error' => 'Unable to update token. No merchant account exists.'
                ], 404);
            }

            $oldToken = $merchant->bakong_token;
            $merchant->update(['bakong_token' => $request->token]);

            Log::info("Bakong token updated by admin user ID: " . auth()->id(), [
                'old_token_prefix' => substr($oldToken ?? 'none', 0, 20),
                'new_token_prefix' => substr($request->token, 0, 20)
            ]);

            return response()->json([
                'message' => '✅ Bakong token updated successfully.',
                'merchant_id' => $merchant->id,
                'updated_at' => $merchant->updated_at
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to update Bakong token: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to update Bakong token.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function deleteBakongToken()
    {
        // Check if user is admin
        if (!auth()->check() || !auth()->user()->is_admin) {
            return response()->json([
                'message' => 'Unauthorized. Admin access required.',
                'error' => 'Only administrators can delete the Bakong token.'
            ], 403);
        }

        try {
            $merchant = MerchantAccount::first();
            if (!$merchant) {
                return response()->json([
                    'message' => 'Merchant account not found.',
                    'error' => 'Unable to delete token. No merchant account exists.'
                ], 404);
            }

            if (!$merchant->bakong_token) {
                return response()->json([
                    'message' => 'No token to delete.',
                    'error' => 'Merchant account does not have a Bakong token.'
                ], 404);
            }

            $oldToken = $merchant->bakong_token;
            $merchant->update(['bakong_token' => null]);

            Log::info("Bakong token deleted by admin user ID: " . auth()->id(), [
                'deleted_token_prefix' => substr($oldToken, 0, 20)
            ]);

            return response()->json([
                'message' => '✅ Bakong token deleted successfully.',
                'merchant_id' => $merchant->id
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to delete Bakong token: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to delete Bakong token.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    private function sendTelegramAlert($message, $merchant = null)
    {
        try {
            if (!$merchant) {
                $merchant = MerchantAccount::first(); // Or however you select the merchant
            }
            $botToken = $merchant->telegram_bot_token;
            $chatId = $merchant->telegram_chat_id;

            if (!$botToken || !$chatId) {
                Log::error("Missing Telegram credentials for merchant ID: " . $merchant->id);
                return;
            }

            $client = new \GuzzleHttp\Client();
            $client->post("https://api.telegram.org/bot{$botToken}/sendMessage", [
                'form_params' => [
                    'chat_id' => $chatId,
                    'text' => $message,
                    'parse_mode' => 'HTML'
                ]
            ]);
        } catch (\Exception $e) {
            Log::error("❌ Telegram alert failed: " . $e->getMessage());
        }
    }

}
