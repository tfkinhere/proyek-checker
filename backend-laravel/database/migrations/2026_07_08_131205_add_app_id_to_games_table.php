<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('games', function (Blueprint $table) {
            // Menambahkan kolom app_id bertipe string agar aman
            // nullable() digunakan agar data GTA V lama yang sudah ada tidak memicu eror
            $table->string('app_id')->nullable();
        });
    }

    public function down()
    {
        Schema::table('games', function (Blueprint $table) {
            // Membatalkan penambahan kolom (drop) jika sewaktu-waktu kita melakukan rollback
            $table->dropColumn('app_id');
        });
    }
};