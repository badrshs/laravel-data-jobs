<?php

namespace Badrshs\LaravelDataJobs;

use Illuminate\Support\ServiceProvider;
use Badrshs\LaravelDataJobs\Console\RunDataJobsCommand;

class DataJobsServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        $this->mergeConfigFrom(
            __DIR__ . '/../config/data-jobs.php',
            'data-jobs'
        );
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Register commands
        if ($this->app->runningInConsole()) {
            $this->commands([
                RunDataJobsCommand::class,
            ]);

            // Publish migrations
            $this->publishes([
                __DIR__ . '/../database/migrations' => database_path('migrations'),
            ], 'data-jobs-migrations');

            // Publish config
            $this->publishes([
                __DIR__ . '/../config/data-jobs.php' => config_path('data-jobs.php'),
            ], 'data-jobs-config');
        }

        // Load migrations
        $this->loadMigrationsFrom(__DIR__ . '/../database/migrations');
    }
}
