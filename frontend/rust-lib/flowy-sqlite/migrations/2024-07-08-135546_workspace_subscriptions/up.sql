-- Your SQL goes here
CREATE TABLE workspace_subscriptions_table (
    workspace_id TEXT NOT NULL,
    subscription_plan INTEGER NOT NULL,
    workspace_status INTEGER NOT NULL,
    end_date TIMESTAMP,
    addons TEXT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (workspace_id)
);