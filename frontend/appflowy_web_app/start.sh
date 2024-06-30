#!/bin/bash



# Start the nginx server
service nginx start

# Start the frontend server
bun run server.cjs

tail -f /dev/null

