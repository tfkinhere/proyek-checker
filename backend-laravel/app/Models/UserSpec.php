<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserSpec extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'os',
        'cpu',
        'gpu',
        'ram',
        'storage',
        'is_active',
    ];

    // Memastikan tipe data stabil saat dikirim ke Flutter
    protected $casts = [
        'ram' => 'integer',
        'storage' => 'integer',
        'is_active' => 'boolean',
    ];
}