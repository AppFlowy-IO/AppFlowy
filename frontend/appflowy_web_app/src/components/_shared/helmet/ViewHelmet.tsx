import { ViewIcon, ViewIconType } from '@/application/types';
import React, { useEffect } from 'react';
import { Helmet } from 'react-helmet';

function ViewHelmet ({
  name,
  icon,
}: {
  name?: string;
  icon?: ViewIcon
}) {

  useEffect(() => {
    const setFavicon = async () => {
      try {
        let url = '/appflowy.svg';

        if (icon && icon.ty === ViewIconType.Emoji && icon.value) {
          const emojiCode = icon?.value?.codePointAt(0)?.toString(16); // Convert emoji to hex code
          const baseUrl = 'https://raw.githubusercontent.com/googlefonts/noto-emoji/main/svg/emoji_u';

          const response = await fetch(`${baseUrl}${emojiCode}.svg`);
          const svgText = await response.text();
          const blob = new Blob([svgText], { type: 'image/svg+xml' });

          url = URL.createObjectURL(blob);
        }

        const link = document.querySelector('link[rel*=\'icon\']') as HTMLLinkElement || document.createElement('link');

        link.type = 'image/svg+xml';
        link.rel = 'icon';
        link.href = url;
        document.getElementsByTagName('head')[0].appendChild(link);
      } catch (error) {
        console.error('Error setting favicon:', error);
      }
    };

    void setFavicon();

    return () => {
      const link = document.querySelector('link[rel*=\'icon\']');

      if (link) {
        document.getElementsByTagName('head')[0].removeChild(link);
      }
    };
  }, [icon]);

  if (!name) return null;
  return (
    <Helmet>
      <title>{name} | AppFlowy</title>
    </Helmet>
  );
}

export default ViewHelmet;