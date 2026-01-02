<?php

namespace Badrshs\LaravelDataJobs\Contracts;

trait DataJob
{
    /**
     * Get the parameters for this job.
     * Override this method to provide custom job metadata.
     * 
     * @return array<string, mixed>
     */
    public function getJobParameters(): array
    {
        return [];
    }

    /**
     * Get the priority of this job (lower numbers run first).
     * Override this method to change job execution order.
     * Default is 100.
     * 
     * @return int
     */
    public function getJobPriority(): int
    {
        return 100;
    }
}
