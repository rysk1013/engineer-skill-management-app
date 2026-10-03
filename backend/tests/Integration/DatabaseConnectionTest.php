<?php

declare(strict_types=1);

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

test('connects to the test PostgreSQL database', function () {
    $result = DB::selectOne('select current_database() as database');

    expect($result->database)
        ->toBe('engineer_skill_management_test');

    expect(Schema::hasTable('users'))
        ->toBeTrue();
});
