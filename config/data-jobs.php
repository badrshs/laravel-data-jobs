<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Data Jobs Configuration
    |--------------------------------------------------------------------------
    |
    | This file contains the configuration options for the Laravel Data Jobs
    | package. You can customize the behavior of data job execution here.
    |
    */

    /**
     * The database table name for storing job execution logs.
     */
    'log_table' => 'data_jobs_log',

    /**
     * Automatically run pending jobs on application boot.
     * Set to true for automatic execution, false for manual execution.
     */
    'auto_run' => false,

    /**
     * Enable or disable job execution logging.
     */
    'logging_enabled' => true,
];
