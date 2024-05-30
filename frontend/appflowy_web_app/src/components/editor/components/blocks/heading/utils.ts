export function getHeadingCssProperty(level: number) {
  switch (level) {
    case 1:
      return 'text-3xl pt-[10px] max-md:pt-[1.5vw] pb-[4px] max-md:pb-[1vw] font-bold max-sm:text-[6vw]';
    case 2:
      return 'text-2xl pt-[8px] max-md:pt-[1vw] pb-[2px] max-md:pb-[0.5vw] font-bold max-sm:text-[5vw]';
    case 3:
      return 'text-xl pt-[4px] font-bold max-sm:text-[4vw]';
    case 4:
      return 'text-lg pt-[4px] font-bold';
    case 5:
      return 'pt-[4px] font-bold';
    case 6:
      return 'pt-[4px] font-bold';
    default:
      return '';
  }
}
