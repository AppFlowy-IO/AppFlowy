if [ -z "$1" ]; then
  echo "No port number provided"
  exit 1
fi

PORT=$1

echo "Starting deployment on port $PORT"

rm -rf dist

tar -xzf build-output.tar.gz

rm -rf build-output.tar.gz

docker system prune -f

docker build -t appflowy-web-app-"$PORT" .

docker rm -f appflowy-web-app-"$PORT" || true

docker run -d --env-file .env -p "$PORT":80 --restart always --name appflowy-web-app-"$PORT" appflowy-web-app-"$PORT"