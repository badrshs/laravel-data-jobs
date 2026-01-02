# Laravel Data Jobs

[![Latest Version on Packagist](https://img.shields.io/packagist/v/badrshs/laravel-data-jobs.svg?style=flat-square)](https://packagist.org/packages/badrshs/laravel-data-jobs)
[![Total Downloads](https://img.shields.io/packagist/dt/badrshs/laravel-data-jobs.svg?style=flat-square)](https://packagist.org/packages/badrshs/laravel-data-jobs)
[![License](https://img.shields.io/packagist/l/badrshs/laravel-data-jobs.svg?style=flat-square)](https://packagist.org/packages/badrshs/laravel-data-jobs)

A Laravel package for managing and executing data migration jobs with tracking, priority support, and execution logging.

## Features

- 🚀 Simple interface for creating data migration jobs
- 📊 Automatic job discovery and execution
- 🎯 Priority-based job ordering
- 📝 Complete execution logging and tracking
- 🔄 Skip already completed jobs
- ⚠️ Error handling and reporting
- 🎨 Beautiful CLI output with progress tracking

## Installation

### Quick Install (Recommended)

```bash
composer require badrshs/laravel-data-jobs
php artisan data-jobs:install
```

That's it! The install command will:
- ✓ Publish the configuration file
- ✓ Run database migrations
- ✓ Show you next steps

### Manual Installation

If you prefer manual setup:

### 1. Install via Composer

```bash
composer require badrshs/laravel-data-jobs
```

### 2. Publish Config (Optional)

```bash
php artisan vendor:publish --tag=data-jobs-config
```

### 3. Run Migrations

```bash
php artisan migrate
```

## Requirements

- PHP 8.0, 8.1, 8.2, or 8.3
- Laravel 9.x, 10.x, 11.x, or 12.x

## Usage

### Creating a Data Job

1. Create a new Artisan command:

```bash
php artisan make:command MigrateUserData
```

2. Add the `DataJob` trait to your command:

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Badrshs\LaravelDataJobs\Contracts\DataJob;
use Illuminate\Support\Facades\DB;

class MigrateUserData extends Command
{
    use DataJob;

    protected $signature = 'data:migrate-user-data';
    protected $description = 'Migrate user data from old format to new format';

    public function handle(): int
    {
        $this->info('Starting user data migration...');
        
        // Your migration logic here
        DB::table('users')
            ->whereNull('migrated_at')
            ->update([
                'migrated_at' => now(),
                // ... other updates
            ]);

        $this->info('Migration completed!');
        
        return self::SUCCESS;
    }
}
```

**That's it!** Just add `use DataJob;` to your command class.

### Customizing Job Behavior (Optional)

Override these methods only if you need custom behavior:

```php
class MigrateUserData extends Command
{
    use DataJob;

    protected $signature = 'data:migrate-user-data';
    protected $description = 'Migrate user data from old format to new format';

    public function handle(): int
    {
        // Your migration logic
        return self::SUCCESS;
    }

    /**
     * Optional: Define job parameters (metadata)
     */
    public function getJobParameters(): array
    {
        return [
            'table' => 'users',
            'type' => 'data-migration',
        ];
    }

    /**
     * Optional: Set job priority (lower numbers run first, default is 100)
     */
    public function getJobPriority(): int
    {
        return 10; // High priority
    }
    }
}
```

### Running Data Jobs

Execute all pending data jobs:

```bash
php artisan data:run-jobs
```

### Command Options

**Force re-run completed jobs:**
```bash
php artisan data:run-jobs --force
```

**Run a specific job:**
```bash
php artisan data:run-jobs --job="App\Console\Commands\MigrateUserData"
```

**Clear logs and start fresh:**
```bash
php artisan data:run-jobs --fresh
```

## How It Works

1. **Discovery**: The package automatically discovers all Artisan commands that implement the `DataJob` interface
2. **Prioritization**: Jobs are sorted by priority (lower numbers first)
3. **Execution**: Each job is executed in order
4. **Logging**: Execution status, errors, and timestamps are logged to the `data_jobs_log` table
5. **Skip Completed**: Already completed jobs are skipped unless `--force` is used

## Job Lifecycle

```
┌─────────────┐
│   Pending   │ ─┐
└─────────────┘  │
                 ▼
┌─────────────┐
│   Running   │
└─────────────┘
       │
       ├─── Success ──────▶ ┌─────────────┐
       │                    │  Completed  │
       │                    └─────────────┘
       │
       └─── Failure ──────▶ ┌─────────────┐
                            │   Failed    │
                            └─────────────┘
```

## Database Schema

The package creates a `data_jobs_log` table with the following structure:

| Column        | Type      | Description                           |
|--------------|-----------|---------------------------------------|
| id           | bigint    | Primary key                          |
| job_class    | string    | Fully qualified job class name       |
| priority     | integer   | Job execution priority               |
| parameters   | json      | Job metadata/parameters              |
| status       | enum      | pending, running, completed, failed  |
| error_message| text      | Error message if failed              |
| started_at   | timestamp | When job execution started           |
| completed_at | timestamp | When job completed successfully      |
| created_at   | timestamp | Record creation time                 |
| updated_at   | timestamp | Record update time                   |

## Example Output

```
🚀 Starting data jobs execution...

┌──────────┬─────────────────────┬───────────┐
│ Priority │ Job Class           │ Status    │
├──────────┼─────────────────────┼───────────┤
│ 10       │ MigrateUserData     │ pending   │
│ 20       │ MigratePaymentData  │ completed │
│ 30       │ UpdateCampaignStats │ pending   │
└──────────┴─────────────────────┴───────────┘

▶️  Running: MigrateUserData
Starting user data migration...
Migration completed!
✅ Completed: MigrateUserData

⏭️  Skipping MigratePaymentData (already completed)

▶️  Running: UpdateCampaignStats
Updating campaign statistics...
✅ Completed: UpdateCampaignStats

📊 Execution Summary:
   - Executed: 2
   - Skipped: 1
   - Failed: 0
```

## Configuration

Edit `config/data-jobs.php` to customize behavior:

```php
return [
    // Database table for storing job logs
    'log_table' => 'data_jobs_log',
    
    // Auto-run pending jobs on boot (default: false)
    'auto_run' => false,
    
    // Enable execution logging (default: true)
    'logging_enabled' => true,
];
```

## Best Practices

1. **Keep jobs idempotent**: Jobs should be safe to run multiple times
2. **Use transactions**: Wrap database operations in transactions
3. **Set appropriate priorities**: Critical migrations should have lower priority numbers
4. **Add descriptive output**: Use Laravel's console output methods for clear feedback
5. **Handle errors gracefully**: Return proper exit codes and log errors
6. **Test thoroughly**: Test jobs with `--force` flag before production deployment

## Requirements

- PHP 8.2 or higher
- Laravel 11.0 or higher
- MySQL/PostgreSQL/SQLite database

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

The MIT License (MIT). Please see [License File](LICENSE) for more information.

## Support

If you discover any security vulnerabilities or issues, please open an issue on [GitHub](https://github.com/badrshs/laravel-data-jobs/issues).

## Credits

- [Badr](https://github.com/badrshs)
- [All Contributors](https://github.com/badrshs/laravel-data-jobs/contributors)
