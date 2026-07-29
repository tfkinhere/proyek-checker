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
            $table->string('steam_app_id')->unique();
            $table->string('title');
            $table->string('banner_url')->nullable();
            $table->json('min_specs')->nullable(); // Kolom JSON ini yang tadi belum ada di MySQL
            $table->json('rec_specs')->nullable(); // Kolom JSON ini juga
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
