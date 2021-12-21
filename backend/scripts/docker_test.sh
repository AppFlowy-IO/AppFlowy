#!/bin/bash
curl -i --request Get --url http://0.0.0.0:8000/api/user --header 'content-type: application/json' --data '{"token":"123"}'