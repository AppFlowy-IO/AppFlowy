rm -rf dist

tar -xzf build-output.tar.gz

rm -rf build-output.tar.gz

docker system prune -f

docker build -t appflowy-web-app .

docker rm -f appflowy-web-app || true

docker run -d --env-file .env -p 30012:80 --restart always --name appflowy-web-app appflowy-web-app