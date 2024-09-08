export function getHeadingCssProperty (level: number) {
  switch (level) {
    case 1:
      return 'text-[1.75rem] max-md:text-[24px] pt-[10px] max-md:pt-[1.5vw] pb-[4px] max-md:pb-[1vw] font-bold';
    case 2:
      return 'text-[1.55rem] max-md:text-[22px] pt-[8px] max-md:pt-[1vw] pb-[2px] max-md:pb-[0.5vw] font-bold';
    case 3:
      return 'text-[1.35rem] max-md:text-[20px] pt-[4px] font-bold';
    case 4:
      return 'text-[1.25rem] max-md:text-[16px] pt-[4px] font-bold';
    case 5:
      return 'text-[1.15rem] pt-[4px] font-bold';
    case 6:
      return 'text-[1.05rem] pt-[4px] font-bold';
    default:
      return '';
  }
}
