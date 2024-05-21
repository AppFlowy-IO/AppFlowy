import { Filter } from '@/application/database-yjs';

export enum NumberFormat {
  Num = 0,
  USD = 1,
  CanadianDollar = 2,
  EUR = 4,
  Pound = 5,
  Yen = 6,
  Ruble = 7,
  Rupee = 8,
  Won = 9,
  Yuan = 10,
  Real = 11,
  Lira = 12,
  Rupiah = 13,
  Franc = 14,
  HongKongDollar = 15,
  NewZealandDollar = 16,
  Krona = 17,
  NorwegianKrone = 18,
  MexicanPeso = 19,
  Rand = 20,
  NewTaiwanDollar = 21,
  DanishKrone = 22,
  Baht = 23,
  Forint = 24,
  Koruna = 25,
  Shekel = 26,
  ChileanPeso = 27,
  PhilippinePeso = 28,
  Dirham = 29,
  ColombianPeso = 30,
  Riyal = 31,
  Ringgit = 32,
  Leu = 33,
  ArgentinePeso = 34,
  UruguayanPeso = 35,
  Percent = 36,
}

export enum NumberFilterCondition {
  Equal = 0,
  NotEqual = 1,
  GreaterThan = 2,
  LessThan = 3,
  GreaterThanOrEqualTo = 4,
  LessThanOrEqualTo = 5,
  NumberIsEmpty = 6,
  NumberIsNotEmpty = 7,
}

export interface NumberFilter extends Filter {
  condition: NumberFilterCondition;
  content: string;
}
