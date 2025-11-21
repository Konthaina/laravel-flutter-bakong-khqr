<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MerchantAccount extends Model
{
    protected $fillable = [
        'account_id',
        'merchant_name',
        'location',
        'bakong_token',
        'user_id', // Add this!
        'telegram_chat_id',
        'telegram_bot_token',
    ];

    // Add this method for the relationship:
    public function user()
    {
        return $this->belongsTo(\App\Models\User::class);
    }
}
