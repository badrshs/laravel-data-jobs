<?php

namespace Badrshs\LaravelDataJobs\Contracts;

trait DataJobable
{
    /**
     * Get the parameters for this job.
     * Override this method to provide custom job metadata and CLI options.
     * Parameters are stored in the database log for tracking and auditing.
     * 
     * @return array<string, mixed>
     * 
     * @example
     * public function getJobParameters(): array
     * {
     *     // These parameters will be automatically passed as CLI options
     *     return [
     *         'with-translations' => true,
     *         'batch' => 'user-migration',
     *     ];
     * }
     */
    public function getJobParameters(): array
    {
        return [];
    }

    /**
     * Get the priority of this job (lower numbers run first).
     * Override this method to change job execution order.
     * Default is 100. Lower priority (e.g., 10) runs before higher priority (e.g., 50).
     * 
     * @return int
     * 
     * @example
     * public function getJobPriority(): int
     * {
     *     // Run this job before others (10 < 100)
     *     return 10;
     * }
     */
    public function getJobPriority(): int
    {
        return 100;
    }

    /**
     * Determine whether this job is enabled and should be executed.
     * Override this method and return false to disable the job.
     * 
     * @return bool
     * 
     * @example
     * public function isEnabled(): bool
     * {
     *     return false; // This job will be skipped
     * }
     */
    public function isEnabled(): bool
    {
        return true;
    }
}
