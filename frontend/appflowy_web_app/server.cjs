const path = require('path');
const fs = require('fs');
const pino = require('pino');
const cheerio = require('cheerio');
const { fetch } = require('bun');
const distDir = path.join(__dirname, 'dist');
const indexPath = path.join(distDir, 'index.html');
const logo = path.join(distDir, 'appflowy.svg');
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
  logger.info(`Fetching meta data from ${url}`);
  try {
    const response = await fetch(url, {
      verbose: true,
    });

    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }

    const data = await response.json();

    return data;
  } catch (error) {
    logger.error(`Error fetching meta data ${error}`);
    return null;
  }
};

const BASE_URL = process.env.AF_BASE_URL || 'https://beta.appflowy.cloud';
const createServer = async (req) => {
  const timer = logRequestTimer(req);
  const reqUrl = new URL(req.url);
  logger.info(`Request URL: ${reqUrl.pathname}`);
  const [
    namespace,
    publishName,
  ] = reqUrl.pathname.slice(1).split('/');

  logger.info(`Namespace: ${namespace}, Publish Name: ${publishName}`);
  if (namespace === '' || !publishName) {
    timer();
    return new Response(null, {
      status: 302,
      headers: {
        'Location': 'https://appflowy.io',
      },
    });
  }

  if (req.method === 'GET') {
    let metaData;
    try {
      metaData = await fetchMetaData(`${BASE_URL}/api/workspace/published/${namespace}/${publishName}`);
    } catch (error) {
      logger.error(`Error fetching meta data: ${error}`);
    }

    let htmlData = fs.readFileSync(indexPath, 'utf8');
    const $ = cheerio.load(htmlData);

    const description = 'Write, share, and publish docs quickly on AppFlowy. \n Get started for free.';
    let title = 'AppFlowy';
    const url = 'https://appflowy.com';
    let image = logo;
    // Inject meta data into the HTML to support SEO and social sharing
    if (metaData) {
      title = `${metaData.view.name} | AppFlowy`;

      try {
        const cover = metaData.view.extra ? JSON.parse(metaData.view.extra)?.cover : null;
        if (cover && ['unsplash', 'custom'].includes(cover.type)) {
          image = cover.value;
        }
      } catch (_) {
        // Do nothing
      }
    }

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
    logger.info(`Base API URL: ${process.env.AF_BASE_URL}`);
  } catch (err) {
    logger.error(err);
    process.exit(1);
  }
};

start();
