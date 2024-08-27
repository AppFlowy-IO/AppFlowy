import path from 'path';
import * as fs from 'fs';
import pino from 'pino';
import { type CheerioAPI, load } from 'cheerio';
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
import { fetch } from 'bun';

const distDir = path.join(__dirname, 'dist');
const indexPath = path.join(distDir, 'index.html');
const baseURL = process.env.AF_BASE_URL as string;
const defaultSite = 'https://appflowy.io';

const setOrUpdateMetaTag = ($: CheerioAPI, selector: string, attribute: string, content: string) => {
  if ($(selector).length === 0) {
    $('head').append(`<meta ${attribute}="${selector.match(/\[(.*?)\]/)?.[1]}" content="${content}">`);
  } else {
    $(selector).attr('content', content);
  }
};

const logger = pino({
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'SYS:standard',
      destination: `${__dirname}/pino-logger.log`,
    },
  },
  level: 'info',
});

const logRequestTimer = (req: Request) => {
  const start = Date.now();
  const pathname = new URL(req.url).pathname;

  logger.info(`Incoming request: ${pathname}`);
  return () => {
    const duration = Date.now() - start;

    logger.info(`Request for ${pathname} took ${duration}ms`);
  };
};

const fetchMetaData = async (url: string) => {
  logger.info(`Fetching meta data from ${url}`);
  try {
    const response = await fetch(url, {
      verbose: true,
    });

    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }

    return response.json();
  } catch (error) {
    logger.error(`Error fetching meta data ${error}`);
    return null;
  }
};

const createServer = async (req: Request) => {
  const timer = logRequestTimer(req);
  const reqUrl = new URL(req.url);
  const hostname = req.headers.get('host');

  logger.info(`Request URL: ${hostname}${reqUrl.pathname}`);

  if (['/after-payment', '/login', '/as-template'].includes(reqUrl.pathname)) {
    timer();
    const htmlData = fs.readFileSync(indexPath, 'utf8');
    const $ = load(htmlData);

    let title, description;

    if (reqUrl.pathname === '/after-payment') {
      title = 'Payment Success | AppFlowy';
      description = 'Payment success on AppFlowy';
    }

    if (reqUrl.pathname === '/login') {
      title = 'Login | AppFlowy';
      description = 'Login to AppFlowy';
    }

    if (title) $('title').text(title);
    if (description) setOrUpdateMetaTag($, 'meta[name="description"]', 'name', description);

    return new Response($.html(), {
      headers: { 'Content-Type': 'text/html' },
    });
  }

  const [namespace, publishName] = reqUrl.pathname.slice(1).split('/');

  logger.info(`Namespace: ${namespace}, Publish Name: ${publishName}`);

  if (req.method === 'GET') {
    if (namespace === '' || !publishName) {
      timer();
      return new Response(null, {
        status: 302,
        headers: {
          Location: defaultSite,
        },
      });
    }

    let metaData;

    try {
      metaData = await fetchMetaData(`${baseURL}/api/workspace/published/${namespace}/${publishName}`);
    } catch (error) {
      logger.error(`Error fetching meta data: ${error}`);
    }

    const htmlData = fs.readFileSync(indexPath, 'utf8');
    const $ = load(htmlData);

    const description = 'Write, share, and publish docs quickly on AppFlowy.\nGet started for free.';
    let title = 'AppFlowy';
    const url = `https://${hostname}${reqUrl.pathname}`;
    let image = '/og-image.png';
    let favicon = '/appflowy.svg';

    try {
      if (metaData && metaData.view) {
        const view = metaData.view;
        const emoji = view.icon.value;
        const titleList = [];

        if (emoji) {
          const emojiCode = emoji.codePointAt(0).toString(16); // Convert emoji to hex code
          const baseUrl = 'https://raw.githubusercontent.com/googlefonts/noto-emoji/main/svg/emoji_u';

          favicon = `${baseUrl}${emojiCode}.svg`;
        }

        if (view.name) {
          titleList.push(view.name);
          titleList.push('|');
        }

        titleList.push('AppFlowy');
        title = titleList.join(' ');

        try {
          const cover = view.extra ? JSON.parse(view.extra)?.cover : null;

          if (cover) {
            if (['unsplash', 'custom'].includes(cover.type)) {
              image = cover.value;
            } else if (cover.type === 'built_in') {
              image = `/covers/m_cover_image_${cover.value}.png`;
            }
          }
        } catch (_) {
          // Do nothing
        }
      }
    } catch (error) {
      logger.error(`Error injecting meta data: ${error}`);
    }

    $('title').text(title);
    $('link[rel="icon"]').attr('href', favicon);
    setOrUpdateMetaTag($, 'meta[name="description"]', 'name', description);
    setOrUpdateMetaTag($, 'meta[property="og:title"]', 'property', title);
    setOrUpdateMetaTag($, 'meta[property="og:description"]', 'property', description);
    setOrUpdateMetaTag($, 'meta[property="og:image"]', 'property', image);
    setOrUpdateMetaTag($, 'meta[property="og:url"]', 'property', url);
    setOrUpdateMetaTag($, 'meta[property="og:site_name"]', 'property', 'AppFlowy');
    setOrUpdateMetaTag($, 'meta[property="og:type"]', 'property', 'website');
    setOrUpdateMetaTag($, 'meta[name="twitter:card"]', 'name', 'summary_large_image');
    setOrUpdateMetaTag($, 'meta[name="twitter:title"]', 'name', title);
    setOrUpdateMetaTag($, 'meta[name="twitter:description"]', 'name', description);
    setOrUpdateMetaTag($, 'meta[name="twitter:image"]', 'name', image);
    setOrUpdateMetaTag($, 'meta[name="twitter:site"]', 'name', '@appflowy');

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

declare const Bun: {
  serve: (options: { port: number; fetch: typeof createServer; error: (err: Error) => Response }) => void;
};

const start = () => {
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    Bun.serve({
      port: 3000,
      fetch: createServer,
      error: (err) => {
        logger.error(`Internal Server Error: ${err}`);
        return new Response('Internal Server Error', { status: 500 });
      },
    });
    logger.info('Server is running on port 3000');
    logger.info(`Base URL: ${baseURL}`);
  } catch (err) {
    logger.error(err);
    process.exit(1);
  }
};

start();

export {};
