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
     * You can customize this if you need a different table name.
     */
    'log_table' => 'data_jobs_log',

    /**
     * Enable or disable job execution logging.
     * When disabled, jobs will run without database tracking.
     */
    'logging_enabled' => true,
];
