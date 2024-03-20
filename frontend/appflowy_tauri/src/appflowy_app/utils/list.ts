const romanMap: [number, string][] = [
  [1000, 'M'],
  [900, 'CM'],
  [500, 'D'],
  [400, 'CD'],
  [100, 'C'],
  [90, 'XC'],
  [50, 'L'],
  [40, 'XL'],
  [10, 'X'],
  [9, 'IX'],
  [5, 'V'],
  [4, 'IV'],
  [1, 'I'],
];

export function romanize(num: number): string {
  let result = '';
  let nextNum = num;

  for (const [value, symbol] of romanMap) {
    const count = Math.floor(nextNum / value);

    nextNum -= value * count;
    result += symbol.repeat(count);
    if (nextNum === 0) break;
  }

  return result;
}

export function letterize(num: number): string {
  let nextNum = num;
  let letters = '';

  while (nextNum > 0) {
    nextNum--;
    const letter = String.fromCharCode((nextNum % 26) + 'a'.charCodeAt(0));

    letters = letter + letters;
    nextNum = Math.floor(nextNum / 26);
  }

  return letters;
}
