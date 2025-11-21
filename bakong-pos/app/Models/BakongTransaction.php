<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BakongTransaction extends Model
{
    protected $fillable = [
        'bill_number',
        'user_id',
        'merchant_account_id',
        'amount',
        'currency',
        'qr_string',
        'md5_hash',
        'status',
        'send_from',
        'receive_to',
        'completed_at',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function merchantAccount(): BelongsTo
    {
        return $this->belongsTo(MerchantAccount::class, 'merchant_account_id');
    }
}
