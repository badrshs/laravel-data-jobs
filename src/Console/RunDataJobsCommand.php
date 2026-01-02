<?php

namespace Badrshs\LaravelDataJobs\Console;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Badrshs\LaravelDataJobs\Contracts\DataJob;
use ReflectionClass;

class RunDataJobsCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'data:run-jobs 
                            {--force : Force re-run completed jobs}
                            {--job= : Run a specific job class}
                            {--fresh : Clear all job logs and run from scratch}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Run all data jobs that implement the DataJob interface';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        if ($this->option('fresh')) {
            if ($this->confirm('⚠️  This will clear all job execution logs. Continue?', false)) {
                DB::table('data_jobs_log')->truncate();
                $this->info('✅ Job logs cleared');
            } else {
                return self::SUCCESS;
            }
        }

        $this->info('🚀 Starting data jobs execution...');
        $this->newLine();

        $jobs = $this->discoverDataJobs();

        if (empty($jobs)) {
            $this->warn('No data jobs found.');
            return self::SUCCESS;
        }

        // Filter by specific job if requested
        if ($jobClass = $this->option('job')) {
            $jobs = array_filter($jobs, fn($job) => $job['class'] === $jobClass);
            if (empty($jobs)) {
                $this->error("Job class '{$jobClass}' not found.");
                return self::FAILURE;
            }
        }

        // Sort by priority (lower numbers first)
        usort($jobs, fn($a, $b) => $a['priority'] <=> $b['priority']);

        $this->table(
            ['Priority', 'Job Class', 'Status'],
            array_map(fn($job) => [
                $job['priority'],
                class_basename($job['class']),
                $this->getJobStatus($job['class'])
            ], $jobs)
        );

        $this->newLine();

        $executed = 0;
        $skipped = 0;
        $failed = 0;

        foreach ($jobs as $job) {
            $status = $this->getJobStatus($job['class']);

            if ($status === 'completed' && !$this->option('force')) {
                $this->line("⏭️  Skipping {$job['name']} (already completed)");
                $skipped++;
                continue;
            }

            $this->info("▶️  Running: {$job['name']}");

            $result = $this->executeJob($job);

            if ($result === true) {
                $this->info("✅ Completed: {$job['name']}");
                $executed++;
            } else {
                $this->error("❌ Failed: {$job['name']}");
                $this->error("   Error: {$result}");
                $failed++;

                if (!$this->confirm('Continue with remaining jobs?', true)) {
                    break;
                }
            }

            $this->newLine();
        }

        $this->newLine();
        $this->info('📊 Execution Summary:');
        $this->line("   - Executed: {$executed}");
        $this->line("   - Skipped: {$skipped}");
        $this->line("   - Failed: {$failed}");

        return $failed > 0 ? self::FAILURE : self::SUCCESS;
    }

    /**
     * Discover all commands that implement DataJob interface.
     *
     * @return array
     */
    protected function discoverDataJobs(): array
    {
        $jobs = [];
        $commands = collect($this->getApplication()->all());

        foreach ($commands as $command) {
            if (!$command instanceof Command) {
                continue;
            }

            $reflection = new ReflectionClass($command);

            if ($reflection->implementsInterface(DataJob::class)) {
                /** @var Command&DataJob $command */
                $jobs[] = [
                    'class' => get_class($command),
                    'name' => class_basename($command),
                    'command' => $command,
                    'priority' => $command->getJobPriority(),
                    'parameters' => $command->getJobParameters(),
                ];
            }
        }

        return $jobs;
    }

    /**
     * Get the status of a job from the log.
     *
     * @param string $jobClass
     * @return string
     */
    protected function getJobStatus(string $jobClass): string
    {
        $log = DB::table('data_jobs_log')
            ->where('job_class', $jobClass)
            ->first();

        return $log ? $log->status : 'pending';
    }

    /**
     * Execute a single job and log the result.
     *
     * @param array $job
     * @return bool|string True on success, error message on failure
     */
    protected function executeJob(array $job): bool|string
    {
        $jobClass = $job['class'];
        $startTime = now();

        // Create or update log entry
        DB::table('data_jobs_log')->updateOrInsert(
            ['job_class' => $jobClass],
            [
                'priority' => $job['priority'],
                'parameters' => json_encode($job['parameters']),
                'status' => 'running',
                'started_at' => $startTime,
                'error_message' => null,
                'updated_at' => $startTime,
            ]
        );

        try {
            /** @var Command $command */
            $command = $job['command'];

            // Execute the command
            $exitCode = $command->run(
                new \Symfony\Component\Console\Input\ArrayInput([]),
                $this->output
            );

            if ($exitCode === Command::SUCCESS) {
                DB::table('data_jobs_log')
                    ->where('job_class', $jobClass)
                    ->update([
                        'status' => 'completed',
                        'completed_at' => now(),
                        'updated_at' => now(),
                    ]);

                return true;
            } else {
                $errorMessage = "Command exited with code: {$exitCode}";
                DB::table('data_jobs_log')
                    ->where('job_class', $jobClass)
                    ->update([
                        'status' => 'failed',
                        'error_message' => $errorMessage,
                        'updated_at' => now(),
                    ]);

                return $errorMessage;
            }
        } catch (\Throwable $e) {
            $errorMessage = $e->getMessage();

            DB::table('data_jobs_log')
                ->where('job_class', $jobClass)
                ->update([
                    'status' => 'failed',
                    'error_message' => $errorMessage,
                    'updated_at' => now(),
                ]);

            return $errorMessage;
        }
    }
}
