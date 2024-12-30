use collab_database::fields::number_type_option::{NumberFormat, NumberTypeOption};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

// Number
#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct NumberTypeOptionPB {
  #[pb(index = 1)]
  pub format: NumberFormatPB,

  #[pb(index = 2)]
  pub scale: u32,

  #[pb(index = 3)]
  pub symbol: String,

  #[pb(index = 5)]
  pub name: String,
}

impl From<NumberTypeOption> for NumberTypeOptionPB {
  fn from(data: NumberTypeOption) -> Self {
    Self {
      format: data.format.into(),
      scale: data.scale,
      symbol: data.symbol,
      name: data.name,
    }
  }
}

impl From<NumberTypeOptionPB> for NumberTypeOption {
  fn from(data: NumberTypeOptionPB) -> Self {
    Self {
      format: data.format.into(),
      scale: data.scale,
      symbol: data.symbol,
      name: data.name,
    }
  }
}

#[derive(Clone, Copy, Debug, ProtoBuf_Enum, Default)]
pub enum NumberFormatPB {
  #[default]
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

impl From<NumberFormat> for NumberFormatPB {
  fn from(data: NumberFormat) -> Self {
    match data {
      NumberFormat::Num => NumberFormatPB::Num,
      NumberFormat::USD => NumberFormatPB::USD,
      NumberFormat::CanadianDollar => NumberFormatPB::CanadianDollar,
      NumberFormat::EUR => NumberFormatPB::EUR,
      NumberFormat::Pound => NumberFormatPB::Pound,
      NumberFormat::Yen => NumberFormatPB::Yen,
      NumberFormat::Ruble => NumberFormatPB::Ruble,
      NumberFormat::Rupee => NumberFormatPB::Rupee,
      NumberFormat::Won => NumberFormatPB::Won,
      NumberFormat::Yuan => NumberFormatPB::Yuan,
      NumberFormat::Real => NumberFormatPB::Real,
      NumberFormat::Lira => NumberFormatPB::Lira,
      NumberFormat::Rupiah => NumberFormatPB::Rupiah,
      NumberFormat::Franc => NumberFormatPB::Franc,
      NumberFormat::HongKongDollar => NumberFormatPB::HongKongDollar,
      NumberFormat::NewZealandDollar => NumberFormatPB::NewZealandDollar,
      NumberFormat::Krona => NumberFormatPB::Krona,
      NumberFormat::NorwegianKrone => NumberFormatPB::NorwegianKrone,
      NumberFormat::MexicanPeso => NumberFormatPB::MexicanPeso,
      NumberFormat::Rand => NumberFormatPB::Rand,
      NumberFormat::NewTaiwanDollar => NumberFormatPB::NewTaiwanDollar,
      NumberFormat::DanishKrone => NumberFormatPB::DanishKrone,
      NumberFormat::Baht => NumberFormatPB::Baht,
      NumberFormat::Forint => NumberFormatPB::Forint,
      NumberFormat::Koruna => NumberFormatPB::Koruna,
      NumberFormat::Shekel => NumberFormatPB::Shekel,
      NumberFormat::ChileanPeso => NumberFormatPB::ChileanPeso,
      NumberFormat::PhilippinePeso => NumberFormatPB::PhilippinePeso,
      NumberFormat::Dirham => NumberFormatPB::Dirham,
      NumberFormat::ColombianPeso => NumberFormatPB::ColombianPeso,
      NumberFormat::Riyal => NumberFormatPB::Riyal,
      NumberFormat::Ringgit => NumberFormatPB::Ringgit,
      NumberFormat::Leu => NumberFormatPB::Leu,
      NumberFormat::ArgentinePeso => NumberFormatPB::ArgentinePeso,
      NumberFormat::UruguayanPeso => NumberFormatPB::UruguayanPeso,
      NumberFormat::Percent => NumberFormatPB::Percent,
    }
  }
}

impl From<NumberFormatPB> for NumberFormat {
  fn from(data: NumberFormatPB) -> Self {
    match data {
      NumberFormatPB::Num => NumberFormat::Num,
      NumberFormatPB::USD => NumberFormat::USD,
      NumberFormatPB::CanadianDollar => NumberFormat::CanadianDollar,
      NumberFormatPB::EUR => NumberFormat::EUR,
      NumberFormatPB::Pound => NumberFormat::Pound,
      NumberFormatPB::Yen => NumberFormat::Yen,
      NumberFormatPB::Ruble => NumberFormat::Ruble,
      NumberFormatPB::Rupee => NumberFormat::Rupee,
      NumberFormatPB::Won => NumberFormat::Won,
      NumberFormatPB::Yuan => NumberFormat::Yuan,
      NumberFormatPB::Real => NumberFormat::Real,
      NumberFormatPB::Lira => NumberFormat::Lira,
      NumberFormatPB::Rupiah => NumberFormat::Rupiah,
      NumberFormatPB::Franc => NumberFormat::Franc,
      NumberFormatPB::HongKongDollar => NumberFormat::HongKongDollar,
      NumberFormatPB::NewZealandDollar => NumberFormat::NewZealandDollar,
      NumberFormatPB::Krona => NumberFormat::Krona,
      NumberFormatPB::NorwegianKrone => NumberFormat::NorwegianKrone,
      NumberFormatPB::MexicanPeso => NumberFormat::MexicanPeso,
      NumberFormatPB::Rand => NumberFormat::Rand,
      NumberFormatPB::NewTaiwanDollar => NumberFormat::NewTaiwanDollar,
      NumberFormatPB::DanishKrone => NumberFormat::DanishKrone,
      NumberFormatPB::Baht => NumberFormat::Baht,
      NumberFormatPB::Forint => NumberFormat::Forint,
      NumberFormatPB::Koruna => NumberFormat::Koruna,
      NumberFormatPB::Shekel => NumberFormat::Shekel,
      NumberFormatPB::ChileanPeso => NumberFormat::ChileanPeso,
      NumberFormatPB::PhilippinePeso => NumberFormat::PhilippinePeso,
      NumberFormatPB::Dirham => NumberFormat::Dirham,
      NumberFormatPB::ColombianPeso => NumberFormat::ColombianPeso,
      NumberFormatPB::Riyal => NumberFormat::Riyal,
      NumberFormatPB::Ringgit => NumberFormat::Ringgit,
      NumberFormatPB::Leu => NumberFormat::Leu,
      NumberFormatPB::ArgentinePeso => NumberFormat::ArgentinePeso,
      NumberFormatPB::UruguayanPeso => NumberFormat::UruguayanPeso,
      NumberFormatPB::Percent => NumberFormat::Percent,
    }
  }
}
