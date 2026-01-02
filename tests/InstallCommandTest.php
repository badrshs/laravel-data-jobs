<?php

namespace Badrshs\LaravelDataJobs\Tests;

use Illuminate\Support\Facades\Schema;

class InstallCommandTest extends TestCase
{
    /** @test */
    public function it_installs_the_package(): void
    {
        $this->artisan('data-jobs:install')
            ->expectsOutput('Installing Laravel Data Jobs...')
            ->assertSuccessful();

        // Check if migration table exists
        $this->assertTrue(Schema::hasTable('data_jobs_log'));
    }

    /** @test */
    public function it_publishes_config_file(): void
    {
        $this->artisan('data-jobs:install')
            ->assertSuccessful();

        $this->assertFileExists(config_path('data-jobs.php'));
    }
}
