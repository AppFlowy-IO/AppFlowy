export function getHeadingCssProperty (level: number) {
  switch (level) {
    case 1:
      return 'text-[1.75rem] max-md:text-[24px] py-[8px] font-bold';
    case 2:
      return 'text-[1.55rem] max-md:text-[22px] py-[6px] font-bold';
    case 3:
      return 'text-[1.35rem] max-md:text-[20px] py-[4px] font-bold';
    case 4:
      return 'text-[1.25rem] max-md:text-[16px] py-[4px] font-bold';
    case 5:
      return 'text-[1.15rem] py-[2px] font-bold';
    case 6:
      return 'text-[1.05rem] py-[2px] font-bold';
    default:
      return '';
  }
}
