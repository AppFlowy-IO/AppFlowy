const path = require('path');
const fs = require('fs');
const pino = require('pino');
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
      translateTime: 'SYS:standard',
      destination: `${__dirname}/pino-logger.log`,
    },
  },
});

const logRequestTimer = (req) => {
  const start = Date.now();
  const pathname = new URL(req.url).pathname;
  logger.info(`Incoming request: ${pathname}`);
  return () => {
    const duration = Date.now() - start;
    logger.info(`Request for ${pathname} took ${duration}ms`);
  };
};

const fetchMetaData = async (url) => {
  try {
    const response = await axios.get(url);
    return response.data;
  } catch (error) {
    logger.error('Error fetching meta data', error);
    return null;
  }
};

const createServer = async (req) => {
  const timer = logRequestTimer(req);

  if (req.method === 'GET') {
    const pageId = req.url.split('/').pop();
    let htmlData = fs.readFileSync(indexPath, 'utf8');
    const $ = cheerio.load(htmlData);
    if (!pageId) {
      timer();
      return new Response($.html(), {
        headers: { 'Content-Type': 'text/html' },
      });
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

    timer();
    return new Response($.html(), {
      headers: { 'Content-Type': 'text/html' },
    });
  } else {
    timer();
    logger.error({ message: 'Method not allowed', method: req.method });
    return new Response('Method not allowed', { status: 405 });
  }
};

const start = () => {
  try {
    Bun.serve({
      port: 3000,
      fetch: createServer,
      error: (err) => {
        logger.error(`Internal Server Error: ${err}`);
        return new Response('Internal Server Error', { status: 500 });
      },
    });
    logger.info(`Server is running on port 3000`);
  } catch (err) {
    logger.error(err);
    process.exit(1);
  }
};

start();
