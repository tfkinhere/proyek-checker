<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Game extends Model
{
    use HasFactory;

    // Mengizinkan seeder untuk mengisi kolom-kolom ini
    protected $fillable = [
    'steam_app_id',
    'title',
    'banner_url',
    'min_specs',
    'rec_specs',
    'min_os',   // ✅ tambah
    'min_cpu',  // ✅ tambah
    'min_gpu',  // ✅ tambah
    'rec_os',   // ✅ tambah
    'rec_cpu',  // ✅ tambah
    'rec_gpu',  // ✅ tambah
    'spec_source', // sumber data spec: steam / igdb
];

protected $casts = [
    'min_specs' => 'array',
    'rec_specs' => 'array',
];
}