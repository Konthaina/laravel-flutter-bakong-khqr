<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BakongController;
use App\Http\Controllers\MerchantAccountController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\ProfileController;

// Auth routes (public)
Route::post('/auth/login', [UserController::class, 'login']);
Route::post('/auth/register', [UserController::class, 'register']);

// Protected routes (require authentication)
Route::middleware('auth:sanctum')->group(function () {
    // User routes (admin only)
    Route::middleware('admin')->group(function () {
        Route::get('/users',        [UserController::class, 'index']);
        Route::post('/users',       [UserController::class, 'store']);
        Route::get('/users/{id}',   [UserController::class, 'show']);
        Route::put('/users/{id}',   [UserController::class, 'update']);
        Route::patch('/users/{id}', [UserController::class, 'update']);
        Route::delete('/users/{id}',[UserController::class, 'destroy']);
    });

    // Profile routes
    Route::get('/users/{id}/profile',    [ProfileController::class, 'show']);
    Route::post('/users/{id}/profile',   [ProfileController::class, 'update']);
    Route::put('/users/{id}/profile',    [ProfileController::class, 'update']);
    Route::delete('/users/{id}/profile', [ProfileController::class, 'destroy']);

    // Merchant Account routes
    Route::get('/merchant-accounts', [MerchantAccountController::class, 'index']);
    Route::post('/merchant-accounts', [MerchantAccountController::class, 'store']);
    Route::get('/merchant-accounts/{id}', [MerchantAccountController::class, 'show']);
    Route::put('/merchant-accounts/{id}', [MerchantAccountController::class, 'update']);
    Route::patch('/merchant-accounts/{id}', [MerchantAccountController::class, 'update']);
    Route::delete('/merchant-accounts/{id}', [MerchantAccountController::class, 'destroy']);

    // Bakong QR/payment routes
    Route::prefix('bakong')->group(function () {
        Route::get('/token', [BakongController::class, 'getToken']);
        Route::post('/generate-qr', [BakongController::class, 'generateQR']);
        Route::get('/verify/md5', [BakongController::class, 'verifyTransactionByMd5']);
    });
});
