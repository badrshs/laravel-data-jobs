# Laravel Data Jobs

[![Latest Version on Packagist](https://img.shields.io/packagist/v/badrshs/laravel-data-jobs.svg?style=flat-square)](https://packagist.org/packages/badrshs/laravel-data-jobs)
[![Total Downloads](https://img.shields.io/packagist/dt/badrshs/laravel-data-jobs.svg?style=flat-square)](https://packagist.org/packages/badrshs/laravel-data-jobs)
[![License](https://img.shields.io/packagist/l/badrshs/laravel-data-jobs.svg?style=flat-square)](https://packagist.org/packages/badrshs/laravel-data-jobs)

A Laravel package for running one-time data migration and transformation jobs in a controlled way.

It lets you define Artisan commands as data jobs that run once by default, can be prioritized, and are fully tracked. This is useful for tasks like migrating data after schema changes or backfilling data for new features.

The package automatically discovers these jobs, runs them in priority order, and records their status as pending, running, completed, or failed in the database. A single Artisan command, data:run-jobs, handles executing all registered jobs safely and in order.

## The Problem

When working on Laravel applications, you often need to run one-time data migrations or transformations—tasks that don't fit into regular database migrations but still need to be executed in a controlled, trackable way. These might include:

- Migrating data between tables after a schema change
- Backfilling data for new features
- Transforming existing data to match new requirements
- Seeding production data based on business logic

Managing these tasks manually is error-prone and makes it difficult to track what has been executed across different environments.

## The Solution

**Laravel Data Jobs** provides a simple, elegant solution by turning Artisan commands into trackable, priority-based data jobs. Simply add the `DataJobable` trait to your command, and the package handles:

- ✅ **Automatic Discovery** - No manual registration required
- ✅ **Execution Tracking** - Prevents duplicate runs and logs all activity
- ✅ **Priority Support** - Control the order of job execution
- ✅ **Status Management** - Track pending, running, completed, and failed jobs
- ✅ **Error Handling** - Graceful failure handling with detailed error logging
- ✅ **Enable/Disable Jobs** - Disable specific jobs without removing them

## Installation

Install the package via Composer:

```bash
composer require badrshs/laravel-data-jobs
```

Run the installation command:

```bash
php artisan data-jobs:install
```

This will:
- Publish the configuration file to `config/data-jobs.php`
- Run the migration to create the `data_jobs_log` table

## Usage

### 1. Create a Data Job Command

Create a new Artisan command:

```bash
php artisan make:command MigrateUsersCommandExample
```

### 2. Add the DataJobable Trait

Add the `DataJobable` trait to your command and optionally customize priority:

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Badrshs\LaravelDataJobs\Contracts\DataJobable;

class MigrateUsersCommandExample extends Command
{
    use DataJobable;

    protected $signature = 'data:migrate-users';
    protected $description = 'Migrate users to new structure';

    // Optional: Set job priority (lower numbers run first, default: 100)
    public function getJobPriority(): int
    {
        return 10;
    }

    // Optional: Define job metadata/parameters
    public function getJobParameters(): array
    {
        return ['batch' => 'user-migration'];
    }

    // Optional: Disable this job so it gets skipped during execution (default: true)
    public function isEnabled(): bool
    {
        return false;
    }

    public function handle(): int
    {
        $this->info('Migrating users...');
        
        // Your migration logic here
        
        $this->info('Migration complete!');
        return self::SUCCESS;
    }
}
```

### 3. Run Your Data Jobs

Execute all pending jobs:

```bash
php artisan data:run-jobs
```

The package will automatically discover and execute all commands using the `DataJobable` trait, sorted by priority.

### Advanced Usage

**Run a specific job:**
```bash
php artisan data:run-jobs --job=MigrateUsersCommandExample
```

**Force re-run completed jobs:**
```bash
php artisan data:run-jobs --force
```

**Clear all logs and run fresh:**
```bash
php artisan data:run-jobs --fresh
```

## How It Works

1. **Discovery**: The package scans all registered Artisan commands for those using the `DataJobable` trait
2. **Enabled Check**: Disabled jobs (`isEnabled(): false`) are filtered out immediately with a `🚫 Disabled` message
3. **Priority Sorting**: Remaining jobs are sorted by priority (lower numbers execute first)
4. **Status Tracking**: Each job's status is logged in the `data_jobs_log` table
5. **Execution**: Jobs run sequentially, with full error handling and logging
6. **Completion**: Successfully completed jobs won't run again unless forced

## Configuration

Publish and customize the configuration file:

```bash
php artisan vendor:publish --tag=data-jobs-config
```

Available options in `config/data-jobs.php`:

```php
return [
    // Database table name for job logs
    'log_table' => 'data_jobs_log',
    
    // Enable/disable execution logging (jobs run without DB tracking when false)
    'logging_enabled' => true,
    
    // Auto-run pending jobs (not yet implemented)
    'auto_run' => false,
];
```

## Example Output

When running jobs, you'll see clear progress feedback:

```
🚀 Starting data jobs execution...

┌──────────┬──────────────────────────────┬───────────┐
│ Priority │ Job Class                    │ Status    │
├──────────┼──────────────────────────────┼───────────┤
│ 10       │ MigrateUsersCommandExample   │ pending   │
│ 20       │ UpdateStatsCommandExample    │ completed │
└──────────┴──────────────────────────────┴───────────┘

🚫 Disabled: DisabledJobExample (skipped)
▶️  Running: MigrateUsersCommandExample
✅ Completed: MigrateUsersCommandExample

⏭️  Skipping UpdateStatsCommandExample (already completed)

📊 Execution Summary:
   - Executed: 1
   - Skipped: 1
   - Failed: 0
```

## Requirements

- PHP 8.1 or higher
- Laravel 10.0, 11.0, or 12.0

## Testing

Run the test suite:

```bash
vendor/bin/phpunit
```

Or using Composer:

```bash
composer test
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Credits

- [Badr](https://github.com/badrshs)
- [All Contributors](../../contributors)

## License

The MIT License (MIT). Please see [License File](LICENSE) for more information.

## Support

- **Issues**: [GitHub Issues](https://github.com/badrshs/laravel-data-jobs/issues)
- **Documentation**: [GitHub Repository](https://github.com/badrshs/laravel-data-jobs)
