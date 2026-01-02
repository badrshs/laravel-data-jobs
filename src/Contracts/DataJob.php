<?php

namespace Badrshs\LaravelDataJobs\Contracts;

interface DataJob
{
    /**
     * Get the parameters for this job.
     * 
     * @return array<string, mixed>
     */
    public function getJobParameters(): array;

    /**
     * Get the priority of this job (lower numbers run first).
     * 
     * @return int
     */
    public function getJobPriority(): int;
}
