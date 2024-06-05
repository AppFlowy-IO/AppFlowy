#!/bin/bash

# Start the frontend server
bun run server.cjs &

# Start the nginx server
service nginx start

tail -f /dev/null

