import { SelectOptionColorPB } from '@/services/backend';

export const SelectOptionColorMap = {
  [SelectOptionColorPB.Purple]: 'bg-tint-purple',
  [SelectOptionColorPB.Pink]: 'bg-tint-pink',
  [SelectOptionColorPB.LightPink]: 'bg-tint-red',
  [SelectOptionColorPB.Orange]: 'bg-tint-orange',
  [SelectOptionColorPB.Yellow]: 'bg-tint-yellow',
  [SelectOptionColorPB.Lime]: 'bg-tint-lime',
  [SelectOptionColorPB.Green]: 'bg-tint-green',
  [SelectOptionColorPB.Aqua]: 'bg-tint-aqua',
  [SelectOptionColorPB.Blue]: 'bg-tint-blue',
};

export const SelectOptionColorTextMap = {
  [SelectOptionColorPB.Purple]: 'purpleColor',
  [SelectOptionColorPB.Pink]: 'pinkColor',
  [SelectOptionColorPB.LightPink]: 'lightPinkColor',
  [SelectOptionColorPB.Orange]: 'orangeColor',
  [SelectOptionColorPB.Yellow]: 'yellowColor',
  [SelectOptionColorPB.Lime]: 'limeColor',
  [SelectOptionColorPB.Green]: 'greenColor',
  [SelectOptionColorPB.Aqua]: 'aquaColor',
  [SelectOptionColorPB.Blue]: 'blueColor',
} as const;
