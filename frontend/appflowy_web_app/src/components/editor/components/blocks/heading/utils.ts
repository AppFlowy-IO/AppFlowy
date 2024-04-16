export function getHeadingCssProperty(level: number) {
  switch (level) {
    case 1:
      return 'text-3xl pt-[10px] pb-[8px] font-bold';
    case 2:
      return 'text-2xl pt-[8px] pb-[6px] font-bold';
    case 3:
      return 'text-xl pt-[4px] font-bold';
    case 4:
      return 'text-lg pt-[4px] font-bold';
    case 5:
      return 'text-base pt-[4px] font-bold';
    case 6:
      return 'text-sm pt-[4px] font-bold';
    default:
      return '';
  }
}
