<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
{
    Schema::create('games', function (Blueprint $table) {
        $table->id();
        $table->string('title'); // Judul Game
        
        // Kolom Spesifikasi Minimum
        $table->string('min_os')->nullable();
        $table->text('min_cpu')->nullable(); // Pakai text karena data array JSON
        $table->integer('min_ram')->nullable();
        $table->text('min_gpu')->nullable(); // Pakai text karena data array JSON
        $table->integer('min_storage')->nullable();
        
        // Kolom Spesifikasi Rekomendasi
        $table->string('rec_os')->nullable();
        $table->text('rec_cpu')->nullable();
        $table->integer('rec_ram')->nullable();
        $table->text('rec_gpu')->nullable();
        $table->integer('rec_storage')->nullable();
        
        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('games');
    }
};
