export function openOrDownload() {
  const getDeviceType = () => {
    const ua = navigator.userAgent;

    if (/(iPad|iPhone|iPod)/g.test(ua)) {
      return 'iOS';
    } else if (/Android/g.test(ua)) {
      return 'Android';
    } else {
      return 'Desktop';
    }
  };

  const deviceType = getDeviceType();
  const isMobile = deviceType !== 'Desktop';
  const getFallbackLink = () => {
    if (deviceType === 'iOS') {
      return 'https://testflight.apple.com/join/6CexvkDz';
    } else if (deviceType === 'Android') {
      return 'https://play.google.com/store/apps/details?id=io.appflowy.appflowy';
    } else {
      return 'https://appflowy.io/download/#pop';
    }
  };

  const getDuration = () => {
    switch (deviceType) {
      case 'iOS':
        return 250;
      default:
        return 1500;
    }
  };

  const APPFLOWY_SCHEME = 'appflowy-flutter://';

  const iframe = document.createElement('iframe');

  iframe.style.display = 'none';
  iframe.src = APPFLOWY_SCHEME;

  const openSchema = () => {
    if (isMobile) return (window.location.href = APPFLOWY_SCHEME);
    document.body.appendChild(iframe);
    setTimeout(() => {
      document.body.removeChild(iframe);
    }, 1000);
  };

  const openAppFlowy = () => {
    openSchema();

    const initialTime = Date.now();
    let interactTime = initialTime;
    let waitTime = 0;
    const duration = getDuration();

    const updateInteractTime = () => {
      interactTime = Date.now();
    };

    document.removeEventListener('mousemove', updateInteractTime);
    document.removeEventListener('mouseenter', updateInteractTime);

    const checkOpen = setInterval(() => {
      waitTime = Date.now() - initialTime;

      if (waitTime > duration) {
        clearInterval(checkOpen);
        if (isMobile || Date.now() - interactTime < duration) {
          window.open(getFallbackLink(), '_current');
        }
      }
    }, 20);

    if (!isMobile) {
      document.addEventListener('mouseenter', updateInteractTime);
      document.addEventListener('mousemove', updateInteractTime);
    }

    document.addEventListener('visibilitychange', () => {
      const isHidden = document.hidden;

      if (isHidden) {
        clearInterval(checkOpen);
      }
    });

    window.onpagehide = () => {
      clearInterval(checkOpen);
    };

    window.onbeforeunload = () => {
      clearInterval(checkOpen);
    };
  };

  openAppFlowy();
}
