FROM oven/bun:latest

WORKDIR /app

RUN apt-get update && \
    apt-get install -y nginx

RUN bun install cheerio pino pino-pretty

COPY . .


RUN apt-get clean && rm -rf /var/lib/apt/lists/*


COPY dist/ /usr/share/nginx/html/

COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh


EXPOSE 3000

CMD ["/app/start.sh"]
