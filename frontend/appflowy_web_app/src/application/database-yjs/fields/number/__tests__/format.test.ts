import { currencyFormaterMap } from '../format';
import { NumberFormat } from '../number.type';
import { expect } from '@jest/globals';

const testCases = [0, 1, 0.5, 0.5666, 1000, 10000, 1000000, 10000000, 1000000.0];
describe('currencyFormaterMap', () => {
  test('should return the correct formatter for Num', () => {
    const formater = currencyFormaterMap[NumberFormat.Num];
    const result = ['0', '1', '0.5', '0.5666', '1,000', '10,000', '1,000,000', '10,000,000', '1,000,000'];
    testCases.forEach((testCase) => {
      expect(formater(testCase)).toBe(result[testCases.indexOf(testCase)]);
    });
  });

  test('should return the correct formatter for Percent', () => {
    const formater = currencyFormaterMap[NumberFormat.Percent];
    const result = ['0%', '1%', '0.5%', '0.57%', '1,000%', '10,000%', '1,000,000%', '10,000,000%', '1,000,000%'];
    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for USD', () => {
    const formater = currencyFormaterMap[NumberFormat.USD];
    const result = ['$0', '$1', '$0.5', '$0.57', '$1,000', '$10,000', '$1,000,000', '$10,000,000', '$1,000,000'];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for CanadianDollar', () => {
    const formater = currencyFormaterMap[NumberFormat.CanadianDollar];
    const result = [
      'CA$0',
      'CA$1',
      'CA$0.5',
      'CA$0.57',
      'CA$1,000',
      'CA$10,000',
      'CA$1,000,000',
      'CA$10,000,000',
      'CA$1,000,000',
    ];
    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for EUR', () => {
    const formater = currencyFormaterMap[NumberFormat.EUR];

    const result = ['€0', '€1', '€0,5', '€0,57', '€1.000', '€10.000', '€1.000.000', '€10.000.000', '€1.000.000'];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Pound', () => {
    const formater = currencyFormaterMap[NumberFormat.Pound];

    const result = ['£0', '£1', '£0.5', '£0.57', '£1,000', '£10,000', '£1,000,000', '£10,000,000', '£1,000,000'];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Yen', () => {
    const formater = currencyFormaterMap[NumberFormat.Yen];

    const result = [
      '￥0',
      '￥1',
      '￥0.5',
      '￥0.57',
      '￥1,000',
      '￥10,000',
      '￥1,000,000',
      '￥10,000,000',
      '￥1,000,000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Ruble', () => {
    const formater = currencyFormaterMap[NumberFormat.Ruble];

    const result = [
      '0 RUB',
      '1 RUB',
      '0,5 RUB',
      '0,57 RUB',
      '1 000 RUB',
      '10 000 RUB',
      '1 000 000 RUB',
      '10 000 000 RUB',
      '1 000 000 RUB',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Rupee', () => {
    const formater = currencyFormaterMap[NumberFormat.Rupee];

    const result = ['₹0', '₹1', '₹0.5', '₹0.57', '₹1,000', '₹10,000', '₹10,00,000', '₹1,00,00,000', '₹10,00,000'];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Won', () => {
    const formater = currencyFormaterMap[NumberFormat.Won];

    const result = ['₩0', '₩1', '₩0.5', '₩0.57', '₩1,000', '₩10,000', '₩1,000,000', '₩10,000,000', '₩1,000,000'];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Yuan', () => {
    const formater = currencyFormaterMap[NumberFormat.Yuan];

    const result = [
      'CN¥0',
      'CN¥1',
      'CN¥0.5',
      'CN¥0.57',
      'CN¥1,000',
      'CN¥10,000',
      'CN¥1,000,000',
      'CN¥10,000,000',
      'CN¥1,000,000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Real', () => {
    const formater = currencyFormaterMap[NumberFormat.Real];

    const result = [
      'R$ 0',
      'R$ 1',
      'R$ 0,5',
      'R$ 0,57',
      'R$ 1.000',
      'R$ 10.000',
      'R$ 1.000.000',
      'R$ 10.000.000',
      'R$ 1.000.000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Lira', () => {
    const formater = currencyFormaterMap[NumberFormat.Lira];

    const result = [
      'TRY 0',
      'TRY 1',
      'TRY 0,5',
      'TRY 0,57',
      'TRY 1.000',
      'TRY 10.000',
      'TRY 1.000.000',
      'TRY 10.000.000',
      'TRY 1.000.000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Rupiah', () => {
    const formater = currencyFormaterMap[NumberFormat.Rupiah];

    const result = [
      'IDR 0',
      'IDR 1',
      'IDR 0,5',
      'IDR 0,57',
      'IDR 1.000',
      'IDR 10.000',
      'IDR 1.000.000',
      'IDR 10.000.000',
      'IDR 1.000.000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Franc', () => {
    const formater = currencyFormaterMap[NumberFormat.Franc];

    const result = [
      'CHF 0',
      'CHF 1',
      'CHF 0.5',
      'CHF 0.57',
      `CHF 1’000`,
      `CHF 10’000`,
      `CHF 1’000’000`,
      `CHF 10’000’000`,
      `CHF 1’000’000`,
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for HongKongDollar', () => {
    const formater = currencyFormaterMap[NumberFormat.HongKongDollar];

    const result = [
      'HK$0',
      'HK$1',
      'HK$0.5',
      'HK$0.57',
      'HK$1,000',
      'HK$10,000',
      'HK$1,000,000',
      'HK$10,000,000',
      'HK$1,000,000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for NewZealandDollar', () => {
    const formater = currencyFormaterMap[NumberFormat.NewZealandDollar];

    const result = [
      'NZ$0',
      'NZ$1',
      'NZ$0.5',
      'NZ$0.57',
      'NZ$1,000',
      'NZ$10,000',
      'NZ$1,000,000',
      'NZ$10,000,000',
      'NZ$1,000,000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Krona', () => {
    const formater = currencyFormaterMap[NumberFormat.Krona];

    const result = [
      '0 SEK',
      '1 SEK',
      '0,5 SEK',
      '0,57 SEK',
      '1 000 SEK',
      '10 000 SEK',
      '1 000 000 SEK',
      '10 000 000 SEK',
      '1 000 000 SEK',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });
  test('should return the correct formatter for NorwegianKrone', () => {
    const formater = currencyFormaterMap[NumberFormat.NorwegianKrone];

    const result = [
      'NOK 0',
      'NOK 1',
      'NOK 0,5',
      'NOK 0,57',
      'NOK 1 000',
      'NOK 10 000',
      'NOK 1 000 000',
      'NOK 10 000 000',
      'NOK 1 000 000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for MexicanPeso', () => {
    const formater = currencyFormaterMap[NumberFormat.MexicanPeso];

    const result = [
      'MX$0',
      'MX$1',
      'MX$0.5',
      'MX$0.57',
      'MX$1,000',
      'MX$10,000',
      'MX$1,000,000',
      'MX$10,000,000',
      'MX$1,000,000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Rand', () => {
    const formater = currencyFormaterMap[NumberFormat.Rand];

    const result = [
      'ZAR 0',
      'ZAR 1',
      'ZAR 0,5',
      'ZAR 0,57',
      'ZAR 1 000',
      'ZAR 10 000',
      'ZAR 1 000 000',
      'ZAR 10 000 000',
      'ZAR 1 000 000',
    ];
    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for NewTaiwanDollar', () => {
    const formater = currencyFormaterMap[NumberFormat.NewTaiwanDollar];

    const result = [
      'NT$0',
      'NT$1',
      'NT$0.5',
      'NT$0.57',
      'NT$1,000',
      'NT$10,000',
      'NT$1,000,000',
      'NT$10,000,000',
      'NT$1,000,000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for DanishKrone', () => {
    const formater = currencyFormaterMap[NumberFormat.DanishKrone];

    const result = [
      '0 DKK',
      '1 DKK',
      '0,5 DKK',
      '0,57 DKK',
      '1.000 DKK',
      '10.000 DKK',
      '1.000.000 DKK',
      '10.000.000 DKK',
      '1.000.000 DKK',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });
  test('should return the correct formatter for Baht', () => {
    const formater = currencyFormaterMap[NumberFormat.Baht];

    const result = [
      'THB 0',
      'THB 1',
      'THB 0.5',
      'THB 0.57',
      'THB 1,000',
      'THB 10,000',
      'THB 1,000,000',
      'THB 10,000,000',
      'THB 1,000,000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });
  test('should return the correct formatter for Forint', () => {
    const formater = currencyFormaterMap[NumberFormat.Forint];

    const result = [
      '0 HUF',
      '1 HUF',
      '0,5 HUF',
      '0,57 HUF',
      '1 000 HUF',
      '10 000 HUF',
      '1 000 000 HUF',
      '10 000 000 HUF',
      '1 000 000 HUF',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Koruna', () => {
    const formater = currencyFormaterMap[NumberFormat.Koruna];

    const result = [
      '0 CZK',
      '1 CZK',
      '0,5 CZK',
      '0,57 CZK',
      '1 000 CZK',
      '10 000 CZK',
      '1 000 000 CZK',
      '10 000 000 CZK',
      '1 000 000 CZK',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Shekel', () => {
    const formater = currencyFormaterMap[NumberFormat.Shekel];

    const result = [
      '‏0 ‏₪',
      '‏1 ‏₪',
      '‏0.5 ‏₪',
      '‏0.57 ‏₪',
      '‏1,000 ‏₪',
      '‏10,000 ‏₪',
      '‏1,000,000 ‏₪',
      '‏10,000,000 ‏₪',
      '‏1,000,000 ‏₪',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });
  test('should return the correct formatter for ChileanPeso', () => {
    const formater = currencyFormaterMap[NumberFormat.ChileanPeso];

    const result = [
      'CLP 0',
      'CLP 1',
      'CLP 0,5',
      'CLP 0,57',
      'CLP 1.000',
      'CLP 10.000',
      'CLP 1.000.000',
      'CLP 10.000.000',
      'CLP 1.000.000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });
  test('should return the correct formatter for PhilippinePeso', () => {
    const formater = currencyFormaterMap[NumberFormat.PhilippinePeso];

    const result = ['₱0', '₱1', '₱0.5', '₱0.57', '₱1,000', '₱10,000', '₱1,000,000', '₱10,000,000', '₱1,000,000'];
    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });
  test('should return the correct formatter for Dirham', () => {
    const formater = currencyFormaterMap[NumberFormat.Dirham];

    const result = [
      '‏0 AED',
      '‏1 AED',
      '‏0.5 AED',
      '‏0.57 AED',
      '‏1,000 AED',
      '‏10,000 AED',
      '‏1,000,000 AED',
      '‏10,000,000 AED',
      '‏1,000,000 AED',
    ];
    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });
  test('should return the correct formatter for ColombianPeso', () => {
    const formater = currencyFormaterMap[NumberFormat.ColombianPeso];

    const result = [
      'COP 0',
      'COP 1',
      'COP 0,5',
      'COP 0,57',
      'COP 1.000',
      'COP 10.000',
      'COP 1.000.000',
      'COP 10.000.000',
      'COP 1.000.000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });
  test('should return the correct formatter for Riyal', () => {
    const formater = currencyFormaterMap[NumberFormat.Riyal];

    const result = [
      'SAR 0',
      'SAR 1',
      'SAR 0.5',
      'SAR 0.57',
      'SAR 1,000',
      'SAR 10,000',
      'SAR 1,000,000',
      'SAR 10,000,000',
      'SAR 1,000,000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Ringgit', () => {
    const formater = currencyFormaterMap[NumberFormat.Ringgit];

    const result = [
      'RM 0',
      'RM 1',
      'RM 0.5',
      'RM 0.57',
      'RM 1,000',
      'RM 10,000',
      'RM 1,000,000',
      'RM 10,000,000',
      'RM 1,000,000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for Leu', () => {
    const formater = currencyFormaterMap[NumberFormat.Leu];

    const result = [
      '0 RON',
      '1 RON',
      '0,5 RON',
      '0,57 RON',
      '1.000 RON',
      '10.000 RON',
      '1.000.000 RON',
      '10.000.000 RON',
      '1.000.000 RON',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for ArgentinePeso', () => {
    const formater = currencyFormaterMap[NumberFormat.ArgentinePeso];

    const result = [
      'ARS 0',
      'ARS 1',
      'ARS 0,5',
      'ARS 0,57',
      'ARS 1.000',
      'ARS 10.000',
      'ARS 1.000.000',
      'ARS 10.000.000',
      'ARS 1.000.000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });

  test('should return the correct formatter for UruguayanPeso', () => {
    const formater = currencyFormaterMap[NumberFormat.UruguayanPeso];

    const result = [
      'UYU 0',
      'UYU 1',
      'UYU 0,5',
      'UYU 0,57',
      'UYU 1.000',
      'UYU 10.000',
      'UYU 1.000.000',
      'UYU 10.000.000',
      'UYU 1.000.000',
    ];

    testCases.forEach((testCase, index) => {
      expect(formater(testCase)).toBe(result[index]);
    });
  });
});
