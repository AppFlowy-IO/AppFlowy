const hasLoadedFonts: Set<string> = new Set();

export function getFontFamily(attribute: string) {
  const fontFamily = attribute.split('_')[0];

  if (hasLoadedFonts.has(fontFamily)) {
    return fontFamily;
  }

  void (async () => {
    const script = document.createElement('script');

    script.src = 'https://ajax.googleapis.com/ajax/libs/webfont/1.6.26/webfont.js';
    document.body.appendChild(script);
    await new Promise((resolve) => {
      script.onload = () => {
        resolve(true);
      };
    });
    window.WebFont?.load({
      google: {
        families: [fontFamily],
      },
    });
  })();

  return fontFamily;
}
