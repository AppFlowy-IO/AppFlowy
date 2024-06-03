#!/bin/bash

# Start the frontend server
node server.cjs &

# Start the nginx server
service nginx start

tail -f /dev/null

