<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('games', function (Blueprint $table) {
            $table->string('min_os')->nullable()->after('rec_specs');
            $table->string('min_cpu')->nullable()->after('min_os');
            $table->string('min_gpu')->nullable()->after('min_cpu');
            $table->string('rec_os')->nullable()->after('min_gpu');
            $table->string('rec_cpu')->nullable()->after('rec_os');
            $table->string('rec_gpu')->nullable()->after('rec_cpu');
        });
    }

    public function down(): void
    {
        Schema::table('games', function (Blueprint $table) {
            $table->dropColumn(['min_os', 'min_cpu', 'min_gpu', 'rec_os', 'rec_cpu', 'rec_gpu']);
        });
    }
};