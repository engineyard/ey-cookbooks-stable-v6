# Sidekiq

This recipe is used to run Sidekiq on the stable-v6 stack.

The sidekiq recipe is managed by Engine Yard.
You should not copy this recipe to your repository but instead copy custom-sidekiq 
or use [environment variables](#environment-variables) to setup sidekiq.
Please check the [custom-sidekiq readme](../../custom-cookbooks/sidekiq/cookbooks/custom-sidekiq) for the complete instructions.

We accept contributions for changes that can be used by all customers.

## Environment Variables

| Environment Variable                     | Default Value  | Description                                                     |
| ---------------------------------------- | -------------- | --------------------------------------------------------------- |
| `EY_SIDEKIQ_ENABLED`                     | `false`        | Enables Sidekiq                                                 |
| `EY_SIDEKIQ_INSTANCES_ROLE`              | N/A            | Pattern to match for instance roles.*                           |
| `EY_SIDEKIQ_INSTANCES_NAME`              | N/A            | Pattern to match for instance names.*                           |
| `EY_SIDEKIQ_NUM_WORKERS`                 | 1              | The number of Sidekiq workers per instance.                     |
| `EY_SIDEKIQ_CONCURRENCY`                 | 25             | The number of threads in each worker.                           |
| `EY_SIDEKIQ_WORKER_MEMORY_MB`            | 400            | Maximum worker memory in MB.                                    |
| `EY_SIDEKIQ_VERBOSE`                     | `false`        | Activate verbose mode.                                          |
| `EY_SIDEKIQ_ORPHAN_MONITORING_ENABLED`   | `false`        | Activate a cronjob which monitors for orphan sidekiq processes. |
| `EY_SIDEKIQ_ORPHAN_MONITORING_SCHEDULE`  | `*/5 * * * *`  | Cron schedule for the orphan monitor.                           |
| `EY_SIDEKIQ_QUEUE_PRIORITY_<queue_name>` | `default => 1` | Set additional queue priorities.**                              |
*: These environment variables match instances by their role and name.
   Every matching instance is set up to run sidekiq workers.
   The values are regular expressions.
   The two matches are combined via a logical `and`.
   Any variable that's not set, matches all instances by default.
   So, if you want to install sidekiq on all instances, don't set any of those variables.

**: The name of this environment variable is dynamic and contains 
    the name of the queue (`<queue_name>`) at the end.
    The value is the numeric priority for that queue.
