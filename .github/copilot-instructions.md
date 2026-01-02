# Laravel Data Jobs - AI Coding Assistant Instructions

## Project Overview
This is a Laravel package (`badrshs/laravel-data-jobs`) that provides a framework for managing one-time data migration jobs with priority support, execution tracking, and automatic discovery. Jobs are implemented as Artisan commands that use the `DataJob` trait.

## Architecture & Core Concepts

### Job Discovery Pattern
The package uses reflection-based auto-discovery via [RunDataJobsCommand.php](src/Console/RunDataJobsCommand.php#L130-L150). Any Artisan command that uses the `DataJob` trait is automatically detected by scanning `$this->getApplication()->all()` and checking `class_uses_recursive()`. No manual registration required.

### DataJob Trait Pattern
[Contracts/DataJob.php](src/Contracts/DataJob.php) provides two methods for commands:
- `getJobPriority(): int` - Lower numbers run first (default: 100)
- `getJobParameters(): array` - Metadata for logging (default: empty array)

Example usage in a command:
```php
use Badrshs\LaravelDataJobs\Contracts\DataJob;
use Illuminate\Console\Command;

class MigrateUsersCommand extends Command {
    use DataJob;
    
    protected $signature = 'migrate:users';
    
    public function getJobPriority(): int { return 10; }
    public function handle() { /* migration logic */ }
}
```

### Execution & State Management
Jobs are tracked in `data_jobs_log` table with states: `pending`, `running`, `completed`, `failed`. The [RunDataJobsCommand](src/Console/RunDataJobsCommand.php#L197-L244) logs execution via DB facade, stores error messages, and prevents re-runs unless `--force` is used. Status checking happens before execution via `getJobStatus()`.

### Service Provider Pattern
[DataJobsServiceProvider.php](src/DataJobsServiceProvider.php) follows standard Laravel patterns:
- `register()`: Merges package config from `config/data-jobs.php`
- `boot()`: Registers commands, publishes migrations/config, loads migrations
- Auto-discovery: Registered in `composer.json` extra.laravel.providers

## Key Commands & Workflows

### Development Commands
```powershell
# Run tests with Orchestra Testbench
vendor/bin/phpunit

# Install package locally in Laravel app
php artisan data-jobs:install [--force]

# Run all pending data jobs (sorted by priority)
php artisan data:run-jobs

# Run specific job or with options
php artisan data:run-jobs --job=MigrateUsersCommand --force --fresh
```

### Release Workflow
Use [release.ps1](release.ps1) (not release.bat). Script:
1. Auto-increments patch version from last git tag
2. Stages changes and commits with message
3. Creates and pushes git tag (format: `v1.2.3`)
4. Pushes to `origin main` branch

## Testing Conventions

### TestCase Setup
[tests/TestCase.php](tests/TestCase.php) uses Orchestra Testbench with:
- SQLite in-memory database (`:memory:`)
- Manual migration loading via `loadMigrationsFrom()`
- Package provider registration in `getPackageProviders()`

### Test Naming
Use snake_case with `/** @test */` annotation:
```php
/** @test */
public function it_installs_the_package(): void
```

## Code Patterns & Conventions

### Error Handling in Commands
[RunDataJobsCommand](src/Console/RunDataJobsCommand.php#L207-L244) catches `\Throwable` and stores messages in `error_message` column. Commands return exit codes (`Command::SUCCESS`/`Command::FAILURE`), not exceptions.

### Database Interactions
Use DB facade directly (not Eloquent models). Examples:
- `DB::table('data_jobs_log')->updateOrInsert()` for idempotent logging
- Indexed queries on `status` and `priority` columns
- JSON column for flexible `parameters` storage

### Console Output Styling
Follow emoji-prefixed patterns from [RunDataJobsCommand](src/Console/RunDataJobsCommand.php#L79-L104):
- 🚀 Starting operations
- ✅ Success/completed
- ❌ Failures
- ⏭️ Skipped items
- ▶️ Running/in-progress

### Configuration Files
Config published to `config/data-jobs.php` with keys:
- `log_table`: Custom table name (default: `data_jobs_log`)
- `auto_run`: Enable automatic execution (default: false)
- `logging_enabled`: Toggle execution logging (default: true)

## Package Dependencies
- PHP: ^8.1-8.3
- Laravel: ^10.0-12.0 (supports Laravel 10, 11, and 12)
- Dev: Orchestra Testbench for package testing, PHPUnit, Mockery

## Important Implementation Details

1. **Job execution uses command's `run()` method**: Pass `ArrayInput([])` and current output, not `call()` or `handle()`
2. **Priority sorting happens at runtime**: Jobs sorted via `usort()` before execution, not database-level
3. **Status table uses unique constraint**: `job_class` column is unique, enabling `updateOrInsert()` pattern
4. **Migration timestamps are fixed**: [2024_01_01_000000_create_data_jobs_log_table.php](database/migrations/2024_01_01_000000_create_data_jobs_log_table.php) uses specific timestamp to ensure consistent ordering
5. **No async execution**: Jobs run sequentially in single process, not queued

## Versioning & Releases
- Use semantic versioning with `v` prefix (v1.0.0)
- Target branch: `main` (not master)
- Release script auto-increments patch by default
- Packagist sync happens automatically after GitHub tag push
