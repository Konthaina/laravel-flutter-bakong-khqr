<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bakong_transactions', function (Blueprint $table) {
            $table->id();
            $table->string('bill_number')->unique();
            $table->decimal('amount', 14, 2)->nullable();
            $table->string('currency', 3)->nullable(); // e.g., KHR, USD
            $table->unsignedBigInteger('merchant_account_id')->nullable();
            $table->foreign('merchant_account_id')->references('id')->on('merchant_accounts')->onDelete('set null');
            $table->text('qr_string')->nullable();
            $table->string('md5_hash')->nullable();
            $table->string('status')->default('pending'); // e.g., pending, success, failed
            $table->string('send_from')->nullable();
            $table->string('receive_to')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bakong_transactions');
    }
};
