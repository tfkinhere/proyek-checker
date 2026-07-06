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
    Schema::create('hardware_benchmarks', function (Blueprint $table) {
        $table->id();
        $table->enum('component_type', ['cpu', 'gpu', 'ram', 'storage']);
        $table->string('component_name');
        $table->integer('performance_score');
        $table->timestamps();

        // Composite Unique Key
        $table->unique(['component_type', 'component_name']);
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('hardware_benchmarks');
    }
};
