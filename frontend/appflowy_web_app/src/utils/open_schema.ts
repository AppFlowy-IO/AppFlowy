import { androidDownloadLink, desktopDownloadLink, iosDownloadLink, openAppFlowySchema } from '@/utils/url';

type OS = 'ios' | 'android' | 'other';

interface AppConfig {
  appScheme: string;
  universalLink?: string;
  intentUrl?: string;
  downloadUrl: string;
  timeout?: number;
}

export const getOS = (): OS => {
  const ua = navigator.userAgent;

  if (/iPad|iPhone|iPod/.test(ua)) return 'ios';
  if (/Android/.test(ua)) return 'android';
  return 'other';
};

const isWebView = (): boolean => {
  const ua = navigator.userAgent.toLowerCase();

  return /(webview|wv)/i.test(ua);
};

const createHiddenIframe = (): HTMLIFrameElement => {
  const iframe = document.createElement('iframe');

  iframe.style.display = 'none';
  document.body.appendChild(iframe);
  return iframe;
};

const removeIframe = (iframe: HTMLIFrameElement): void => {
  document.body.removeChild(iframe);
};

const redirectToUrl = (url: string): void => {
  window.location.href = url;
};

export const openAppOrDownload = (config: AppConfig): void => {
  const { appScheme, universalLink, intentUrl, downloadUrl, timeout = 3000 } = config;
  const os = getOS();
  const iframe = createHiddenIframe();

  const timer = setTimeout(() => {
    removeIframe(iframe);
    redirectToUrl(downloadUrl);
  }, timeout);

  const handleVisibilityChange = (): void => {
    if (!document.hidden) {
      clearTimeout(timer);
      removeIframe(iframe);
      redirectToUrl(downloadUrl);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    }
  };

  document.addEventListener('visibilitychange', handleVisibilityChange);

  const openApp = () => {
    switch (os) {
      case 'ios':
        if (isWebView() || !universalLink) {
          iframe.src = appScheme;
        } else {
          redirectToUrl(universalLink);
        }

        break;
      case 'android':
        if (isWebView() || !intentUrl) {
          iframe.src = appScheme;
        } else {
          redirectToUrl(intentUrl);
        }

        break;
      default:
        iframe.src = appScheme;
    }
  };

  openApp();

  iframe.onload = () => {
    clearTimeout(timer);
    removeIframe(iframe);
    redirectToUrl(downloadUrl);
  };
};

export function openOrDownload (schema?: string) {
  const os = getOS();
  const downloadUrl = os === 'ios' ? iosDownloadLink : os === 'android' ? androidDownloadLink : desktopDownloadLink;

  return openAppOrDownload({
    appScheme: schema || openAppFlowySchema,
    downloadUrl,
  });
}