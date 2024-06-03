const path = require('path');
const fs = require('fs');
const pino = require('pino');
const rateLimit = require('@fastify/rate-limit');
const cheerio = require('cheerio');
const axios = require('axios');

const distDir = path.join(__dirname, 'dist');
const indexPath = path.join(distDir, 'index.html');

const setOrUpdateMetaTag = ($, selector, attribute, content) => {
  if ($(selector).length === 0) {
    $('head').append(`<meta ${attribute}="${selector.match(/\[(.*?)\]/)[1]}" content="${content}">`);
  } else {
    $(selector).attr('content', content);
  }
};
// Create a new logger instance
const logger = pino({
  transport: {
    target: 'pino-pretty',
    level: 'info',
    options: {
      colorize: true,
      levelFirst: true,
      destination: `${__dirname}/pino-logger.log`,
    },
  },
});
const fastify = require('fastify')({
  logger,
});
const fetchMetaData = async (url) => {
  try {
    const response = await axios.get(url);
    return response.data;
  } catch (error) {
    fastify.log.error('Error fetching meta data', error);
    return null;
  }
};

fastify.get('*', async (request, reply) => {
  const requestURL = request.raw.url;
  const pageId = requestURL.split('/').pop();
  // const metaData = await fetchMetaData(`https://example.com/api/meta/${pageId}`);

  let htmlData = fs.readFileSync(indexPath, 'utf8');
  const $ = cheerio.load(htmlData);

  if (!pageId) {
    return reply.type('text/html').send($.html());
  }
  const description = 'Write, share, comment, react, and publish docs quickly and securely on AppFlowy.';
  let title = 'AppFlowy';
  const url = 'https://appflowy.com';
  let image = 'https://d3uafhn8yrvdfn.cloudfront.net/website/production/_next/static/media/og-image.e347bfb5.png';
  // Inject meta data into the HTML to support SEO and social sharing
  // if (metaData) {
  //   title = metaData.title;
  //   image = metaData.image;
  // }

  $('title').text(title);
  setOrUpdateMetaTag($, 'meta[name="description"]', 'name', description);
  setOrUpdateMetaTag($, 'meta[property="og:title"]', 'property', title);
  setOrUpdateMetaTag($, 'meta[property="og:description"]', 'property', description);
  setOrUpdateMetaTag($, 'meta[property="og:image"]', 'property', image);
  setOrUpdateMetaTag($, 'meta[property="og:url"]', 'property', url);
  setOrUpdateMetaTag($, 'meta[property="og:type"]', 'property', 'article');
  setOrUpdateMetaTag($, 'meta[name="twitter:card"]', 'name', 'summary_large_image');
  setOrUpdateMetaTag($, 'meta[name="twitter:title"]', 'name', title);
  setOrUpdateMetaTag($, 'meta[name="twitter:description"]', 'name', description);
  setOrUpdateMetaTag($, 'meta[name="twitter:image"]', 'name', image);

  reply.type('text/html').send($.html());
});

const start = async () => {
  try {

    await fastify.register(rateLimit, {
      max: 100,
      timeWindow: '1 minute',
      errorResponseBuilder: (req, context) => {
        return {
          code: 429,
          error: 'Too Many Requests',
          message: `I only allow ${context.max} requests per ${context.ttl} seconds to this API. Try again soon.`,
          date: Date.now(),
          expiresIn: context.ttl,
        };
      },
    });

    await fastify.listen({
      port: 3000,
      host: '0.0.0.0',
    });
    fastify.log.info(`Server is running on port 3000`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
