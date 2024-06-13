const hasLoadedFonts: Set<string> = new Set();

export function getFontFamily(attribute: string) {
  const fontFamily = attribute.split('_')[0];

  if (hasLoadedFonts.has(fontFamily)) {
    return fontFamily;
  }

  window.WebFont?.load({
    google: {
      families: [fontFamily],
    },
  });
  return fontFamily;
}
