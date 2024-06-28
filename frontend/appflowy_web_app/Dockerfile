FROM oven/bun:latest

WORKDIR /app

RUN apt-get update && \
    apt-get install -y nginx

RUN bun install cheerio pino pino-pretty

COPY . .

RUN addgroup --system nginx && \
    adduser --system --no-create-home --disabled-login --ingroup nginx nginx

RUN apt-get clean && rm -rf /var/lib/apt/lists/*


COPY dist/ /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/nginx.conf

COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh


EXPOSE 80

CMD ["/app/start.sh"]
