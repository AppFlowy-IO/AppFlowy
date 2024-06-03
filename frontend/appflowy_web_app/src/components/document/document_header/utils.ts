// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
import ColorThief from 'colorthief';

const colorThief = new ColorThief();

export function calculateTextColor(rgb: [number, number, number]): string {
  const [r, g, b] = rgb;
  const brightness = (r * 299 + g * 587 + b * 114) / 1000;

  return brightness > 125 ? 'black' : 'white';
}

export async function showColorsForImage(image: HTMLImageElement) {
  const img = new Image();

  img.crossOrigin = 'Anonymous'; // Handle CORS
  img.src = image.src;

  await new Promise((resolve, reject) => {
    img.onload = resolve;
    img.onerror = reject;
  });

  const dominantColor = colorThief.getColor(img);

  return calculateTextColor(dominantColor);
}
