#!/usr/bin/env bash



# Start the nginx server
service nginx start

# Start the frontend server
bun run server.ts

tail -f /dev/null

