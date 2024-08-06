import { getIconSvgEncodedContent } from '@/utils/emoji';
import React, { useEffect, useMemo, useState } from 'react';
import { ReactComponent as SpaceIcon1 } from '@/assets/space_icon/space_icon_1.svg';
import { ReactComponent as SpaceIcon2 } from '@/assets/space_icon/space_icon_2.svg';
import { ReactComponent as SpaceIcon3 } from '@/assets/space_icon/space_icon_3.svg';
import { ReactComponent as SpaceIcon4 } from '@/assets/space_icon/space_icon_4.svg';
import { ReactComponent as SpaceIcon5 } from '@/assets/space_icon/space_icon_5.svg';
import { ReactComponent as SpaceIcon6 } from '@/assets/space_icon/space_icon_6.svg';
import { ReactComponent as SpaceIcon7 } from '@/assets/space_icon/space_icon_7.svg';
import { ReactComponent as SpaceIcon8 } from '@/assets/space_icon/space_icon_8.svg';
import { ReactComponent as SpaceIcon9 } from '@/assets/space_icon/space_icon_9.svg';
import { ReactComponent as SpaceIcon10 } from '@/assets/space_icon/space_icon_10.svg';
import { ReactComponent as SpaceIcon11 } from '@/assets/space_icon/space_icon_11.svg';
import { ReactComponent as SpaceIcon12 } from '@/assets/space_icon/space_icon_12.svg';
import { ReactComponent as SpaceIcon13 } from '@/assets/space_icon/space_icon_13.svg';
import { ReactComponent as SpaceIcon14 } from '@/assets/space_icon/space_icon_14.svg';
import { ReactComponent as SpaceIcon15 } from '@/assets/space_icon/space_icon_15.svg';

export const getIconComponent = (icon: string) => {
  switch (icon) {
    case 'space_icon_1':
    case '':
      return SpaceIcon1;
    case 'space_icon_2':
      return SpaceIcon2;
    case 'space_icon_3':
      return SpaceIcon3;
    case 'space_icon_4':
      return SpaceIcon4;
    case 'space_icon_5':
      return SpaceIcon5;
    case 'space_icon_6':
      return SpaceIcon6;
    case 'space_icon_7':
      return SpaceIcon7;
    case 'space_icon_8':
      return SpaceIcon8;
    case 'space_icon_9':
      return SpaceIcon9;
    case 'space_icon_10':
      return SpaceIcon10;
    case 'space_icon_11':
      return SpaceIcon11;
    case 'space_icon_12':
      return SpaceIcon12;
    case 'space_icon_13':
      return SpaceIcon13;
    case 'space_icon_14':
      return SpaceIcon14;
    case 'space_icon_15':
      return SpaceIcon15;

    default:
      return null;
  }
};

function SpaceIcon({ value }: { value: string }) {
  const IconComponent = getIconComponent(value);
  const [iconEncodeContent, setIconEncodeContent] = useState<string | null>(null);

  useEffect(() => {
    if (value && !IconComponent) {
      void getIconSvgEncodedContent(value, 'white').then((res) => {
        setIconEncodeContent(res);
      });
    }
  }, [IconComponent, value]);

  const customIcon = useMemo(() => {
    if (!iconEncodeContent) {
      return null;
    }

    /**
     * value eg: 'artificial_intelligence/ai-cloud-spark';
     */
    return <img src={iconEncodeContent} className={'h-full w-full p-1 text-white'} alt={value} />;
  }, [iconEncodeContent, value]);

  if (!IconComponent) {
    return customIcon;
  }

  return <IconComponent className={'h-full w-full'} />;
}

export default SpaceIcon;
