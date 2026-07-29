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
        Schema::create('user_specs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            // Menampung string inputan user persis apa adanya (tanpa simbol X)
            $table->string('os', 150);
            $table->string('cpu', 150);
            $table->string('gpu', 150);
            // Menampung nilai angka dari slider Flutter
            $table->integer('ram');
            $table->integer('storage');
            // Status aktif untuk membedakan mana spek lama dan spek baru
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_specs');
    }
};
