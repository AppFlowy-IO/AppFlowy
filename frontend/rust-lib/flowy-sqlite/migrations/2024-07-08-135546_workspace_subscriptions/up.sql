-- Your SQL goes here
CREATE TABLE workspace_subscriptions_table (
    workspace_id TEXT NOT NULL,
    subscription_plan INTEGER NOT NULL,
    recurring_interval INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL,
    has_canceled BOOLEAN NOT NULL DEFAULT FALSE,
    canceled_at TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (workspace_id)
);