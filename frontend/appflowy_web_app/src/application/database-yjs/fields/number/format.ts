import { NumberFormat } from './number.type';

const commonProps = {
  minimumFractionDigits: 0,
  maximumFractionDigits: 2,
  style: 'currency',
  currencyDisplay: 'symbol',
  useGrouping: true,
};

export const currencyFormaterMap: Record<NumberFormat, (n: number) => string> = {
  [NumberFormat.Num]: (n: number) =>
    new Intl.NumberFormat('en-US', {
      style: 'decimal',
      minimumFractionDigits: 0,
      maximumFractionDigits: 20,
    }).format(n),
  [NumberFormat.Percent]: (n: number) =>
    new Intl.NumberFormat('en-US', {
      ...commonProps,
      style: 'decimal',
    }).format(n) + '%',
  [NumberFormat.USD]: (n: number) =>
    new Intl.NumberFormat('en-US', {
      ...commonProps,
      currency: 'USD',
    }).format(n),
  [NumberFormat.CanadianDollar]: (n: number) =>
    new Intl.NumberFormat('en-CA', {
      ...commonProps,
      currency: 'CAD',
    })
      .format(n)
      .replace('$', 'CA$'),
  [NumberFormat.EUR]: (n: number) =>
    new Intl.NumberFormat('en-IE', {
      ...commonProps,
      currency: 'EUR',
    }).format(n),
  [NumberFormat.Pound]: (n: number) =>
    new Intl.NumberFormat('en-GB', {
      ...commonProps,
      currency: 'GBP',
    }).format(n),
  [NumberFormat.Yen]: (n: number) =>
    new Intl.NumberFormat('ja-JP', {
      ...commonProps,
      currency: 'JPY',
    }).format(n),
  [NumberFormat.Ruble]: (n: number) =>
    new Intl.NumberFormat('ru-RU', {
      ...commonProps,
      currency: 'RUB',
      currencyDisplay: 'code',
    })
      .format(n)
      .replaceAll(' ', ' '),
  [NumberFormat.Rupee]: (n: number) =>
    new Intl.NumberFormat('hi-IN', {
      ...commonProps,
      currency: 'INR',
    }).format(n),
  [NumberFormat.Won]: (n: number) =>
    new Intl.NumberFormat('ko-KR', {
      ...commonProps,
      currency: 'KRW',
    }).format(n),
  [NumberFormat.Yuan]: (n: number) =>
    new Intl.NumberFormat('zh-CN', {
      ...commonProps,
      currency: 'CNY',
    })
      .format(n)
      .replace('¥', 'CN¥'),
  [NumberFormat.Real]: (n: number) =>
    new Intl.NumberFormat('pt-BR', {
      ...commonProps,
      currency: 'BRL',
    })
      .format(n)
      .replaceAll(' ', ' '),
  [NumberFormat.Lira]: (n: number) =>
    new Intl.NumberFormat('tr-TR', {
      ...commonProps,
      currency: 'TRY',
      currencyDisplay: 'code',
    })
      .format(n)
      .replaceAll(' ', ' '),
  [NumberFormat.Rupiah]: (n: number) =>
    new Intl.NumberFormat('id-ID', {
      ...commonProps,
      currency: 'IDR',
      currencyDisplay: 'code',
    })
      .format(n)
      .replaceAll(' ', ' '),
  [NumberFormat.Franc]: (n: number) =>
    new Intl.NumberFormat('de-CH', {
      ...commonProps,
      currency: 'CHF',
    })
      .format(n)
      .replaceAll(' ', ' '),
  [NumberFormat.HongKongDollar]: (n: number) =>
    new Intl.NumberFormat('zh-HK', {
      ...commonProps,
      currency: 'HKD',
    }).format(n),
  [NumberFormat.NewZealandDollar]: (n: number) =>
    new Intl.NumberFormat('en-NZ', {
      ...commonProps,
      currency: 'NZD',
    })
      .format(n)
      .replace('$', 'NZ$'),
  [NumberFormat.Krona]: (n: number) =>
    new Intl.NumberFormat('sv-SE', {
      ...commonProps,
      currency: 'SEK',
      currencyDisplay: 'code',
    }).format(n),
  [NumberFormat.NorwegianKrone]: (n: number) =>
    new Intl.NumberFormat('nb-NO', {
      ...commonProps,
      currency: 'NOK',
      currencyDisplay: 'code',
    }).format(n),
  [NumberFormat.MexicanPeso]: (n: number) =>
    new Intl.NumberFormat('es-MX', {
      ...commonProps,
      currency: 'MXN',
    })
      .format(n)
      .replace('$', 'MX$'),
  [NumberFormat.Rand]: (n: number) =>
    new Intl.NumberFormat('en-ZA', {
      ...commonProps,
      currency: 'ZAR',
      currencyDisplay: 'code',
    }).format(n),
  [NumberFormat.NewTaiwanDollar]: (n: number) =>
    new Intl.NumberFormat('zh-TW', {
      ...commonProps,
      currency: 'TWD',
    })
      .format(n)
      .replace('$', 'NT$'),
  [NumberFormat.DanishKrone]: (n: number) =>
    new Intl.NumberFormat('da-DK', {
      ...commonProps,
      currency: 'DKK',
      currencyDisplay: 'code',
    }).format(n),
  [NumberFormat.Baht]: (n: number) =>
    new Intl.NumberFormat('th-TH', {
      ...commonProps,
      currency: 'THB',
      currencyDisplay: 'code',
    }).format(n),
  [NumberFormat.Forint]: (n: number) =>
    new Intl.NumberFormat('hu-HU', {
      ...commonProps,
      currency: 'HUF',
      currencyDisplay: 'code',
    }).format(n),
  [NumberFormat.Koruna]: (n: number) =>
    new Intl.NumberFormat('cs-CZ', {
      ...commonProps,
      currency: 'CZK',
      currencyDisplay: 'code',
    }).format(n),
  [NumberFormat.Shekel]: (n: number) =>
    new Intl.NumberFormat('he-IL', {
      ...commonProps,
      currency: 'ILS',
    }).format(n),
  [NumberFormat.ChileanPeso]: (n: number) =>
    new Intl.NumberFormat('es-CL', {
      ...commonProps,
      currency: 'CLP',
      currencyDisplay: 'code',
    }).format(n),
  [NumberFormat.PhilippinePeso]: (n: number) =>
    new Intl.NumberFormat('fil-PH', {
      ...commonProps,
      currency: 'PHP',
    }).format(n),
  [NumberFormat.Dirham]: (n: number) =>
    new Intl.NumberFormat('ar-AE', {
      ...commonProps,
      currency: 'AED',
      currencyDisplay: 'code',
    }).format(n),
  [NumberFormat.ColombianPeso]: (n: number) =>
    new Intl.NumberFormat('es-CO', {
      ...commonProps,
      currency: 'COP',
      currencyDisplay: 'code',
    }).format(n),
  [NumberFormat.Riyal]: (n: number) =>
    new Intl.NumberFormat('en-US', {
      ...commonProps,
      currency: 'SAR',
      currencyDisplay: 'code',
    }).format(n),
  [NumberFormat.Ringgit]: (n: number) =>
    new Intl.NumberFormat('ms-MY', {
      ...commonProps,
      currency: 'MYR',
    }).format(n),
  [NumberFormat.Leu]: (n: number) =>
    new Intl.NumberFormat('ro-RO', {
      ...commonProps,
      currency: 'RON',
    }).format(n),
  [NumberFormat.ArgentinePeso]: (n: number) =>
    new Intl.NumberFormat('es-AR', {
      ...commonProps,
      currency: 'ARS',
      currencyDisplay: 'code',
    }).format(n),
  [NumberFormat.UruguayanPeso]: (n: number) =>
    new Intl.NumberFormat('es-UY', {
      ...commonProps,
      currency: 'UYU',
      currencyDisplay: 'code',
    }).format(n),
};
