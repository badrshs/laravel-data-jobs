<?php

namespace Badrshs\LaravelDataJobs\Console;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;

class InstallCommand extends Command
{
    protected $signature = 'data-jobs:install {--force : Overwrite existing files}';

    protected $description = 'Install Laravel Data Jobs package';

    public function handle(): int
    {
        $this->info('Installing Laravel Data Jobs...');

        // Publish config
        $this->comment('Publishing configuration...');
        $this->callSilent('vendor:publish', [
            '--tag' => 'data-jobs-config',
            '--force' => $this->option('force'),
        ]);

        // Run migrations
        $this->comment('Running migrations...');
        $this->call('migrate');

        // Success message
        $this->newLine();
        $this->info('✓ Laravel Data Jobs installed successfully!');
        $this->newLine();

        // Show next steps
        $this->comment('Next steps:');
        $this->line('1. Create a data job: php artisan make:command YourDataJob');
        $this->line('2. Add this line to your command: use DataJob;');
        $this->line('3. Run data jobs: php artisan data-jobs:run');
        $this->newLine();
        $this->line('Documentation: https://github.com/badrshs/laravel-data-jobs');

        return self::SUCCESS;
    }
}
