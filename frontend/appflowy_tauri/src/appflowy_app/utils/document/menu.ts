export function selectOptionByUpDown(isUp: boolean, selected: string | null, options: string[]) {
  const index = options.findIndex((option) => option === selected);
  const length = options.length;

  const nextIndex = isUp ? (index - 1 + length) % length : (index + 1) % length;

  return options[nextIndex];
}
