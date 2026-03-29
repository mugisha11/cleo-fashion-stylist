/// Trusted fashion e-commerce retailers for "buy clothes" and "try from link" suggestions.
/// Used by Cleo to recommend where to shop and to recognize product links.
class TrustedRetailer {
  final String name;
  final String baseUrl;
  final String country;
  final List<String> domains;

  const TrustedRetailer({
    required this.name,
    required this.baseUrl,
    required this.country,
    required this.domains,
  });
}

/// Reputable fashion retailers by country (at least one per country for Cleo suggestions).
final List<TrustedRetailer> trustedFashionRetailers = [
  // Germany (DE)
  const TrustedRetailer(name: 'Zalando', baseUrl: 'https://en.zalando.de/', country: 'DE', domains: ['zalando.de', 'zalando.com']),
  const TrustedRetailer(name: 'OTTO', baseUrl: 'https://www.otto.de/', country: 'DE', domains: ['otto.de']),
  const TrustedRetailer(name: 'ABOUT YOU', baseUrl: 'https://en.aboutyou.de/', country: 'DE', domains: ['aboutyou.de', 'aboutyou.com']),
  const TrustedRetailer(name: 'Amazon DE', baseUrl: 'https://www.amazon.de/', country: 'DE', domains: ['amazon.de']),
  // United Kingdom (UK)
  const TrustedRetailer(name: 'ASOS', baseUrl: 'https://www.asos.com/', country: 'UK', domains: ['asos.com']),
  const TrustedRetailer(name: 'Next', baseUrl: 'https://www.next.co.uk/', country: 'UK', domains: ['next.co.uk']),
  const TrustedRetailer(name: 'John Lewis', baseUrl: 'https://www.johnlewis.com/', country: 'UK', domains: ['johnlewis.com']),
  const TrustedRetailer(name: 'M&S', baseUrl: 'https://www.marksandspencer.com/', country: 'UK', domains: ['marksandspencer.com']),
  const TrustedRetailer(name: 'Boohoo', baseUrl: 'https://www.boohoo.com/', country: 'UK', domains: ['boohoo.com']),
  // United States (US)
  const TrustedRetailer(name: 'Nordstrom', baseUrl: 'https://www.nordstrom.com/', country: 'US', domains: ['nordstrom.com']),
  const TrustedRetailer(name: 'Macy\'s', baseUrl: 'https://www.macys.com/', country: 'US', domains: ['macys.com']),
  const TrustedRetailer(name: 'Amazon US', baseUrl: 'https://www.amazon.com/', country: 'US', domains: ['amazon.com']),
  const TrustedRetailer(name: 'Revolve', baseUrl: 'https://www.revolve.com/', country: 'US', domains: ['revolve.com']),
  // France (FR)
  const TrustedRetailer(name: 'La Redoute', baseUrl: 'https://www.laredoute.com/', country: 'FR', domains: ['laredoute.com']),
  const TrustedRetailer(name: 'Veepee', baseUrl: 'https://www.veepee.com/', country: 'FR', domains: ['veepee.com']),
  const TrustedRetailer(name: 'Zalando FR', baseUrl: 'https://www.zalando.fr/', country: 'FR', domains: ['zalando.fr']),
  const TrustedRetailer(name: 'Amazon FR', baseUrl: 'https://www.amazon.fr/', country: 'FR', domains: ['amazon.fr']),
  // Spain (ES)
  const TrustedRetailer(name: 'El Corte Inglés', baseUrl: 'https://www.elcorteingles.es/', country: 'ES', domains: ['elcorteingles.es']),
  const TrustedRetailer(name: 'Zalando ES', baseUrl: 'https://www.zalando.es/', country: 'ES', domains: ['zalando.es']),
  const TrustedRetailer(name: 'Mango', baseUrl: 'https://shop.mango.com/', country: 'ES', domains: ['mango.com']),
  const TrustedRetailer(name: 'Amazon ES', baseUrl: 'https://www.amazon.es/', country: 'ES', domains: ['amazon.es']),
  // Italy (IT)
  const TrustedRetailer(name: 'Yoox', baseUrl: 'https://www.yoox.com/', country: 'IT', domains: ['yoox.com']),
  const TrustedRetailer(name: 'Zalando IT', baseUrl: 'https://www.zalando.it/', country: 'IT', domains: ['zalando.it']),
  const TrustedRetailer(name: 'Amazon IT', baseUrl: 'https://www.amazon.it/', country: 'IT', domains: ['amazon.it']),
  // Netherlands (NL)
  const TrustedRetailer(name: 'Wehkamp', baseUrl: 'https://www.wehkamp.nl/', country: 'NL', domains: ['wehkamp.nl']),
  const TrustedRetailer(name: 'Zalando NL', baseUrl: 'https://www.zalando.nl/', country: 'NL', domains: ['zalando.nl']),
  const TrustedRetailer(name: 'Amazon NL', baseUrl: 'https://www.amazon.nl/', country: 'NL', domains: ['amazon.nl']),
  // Austria (AT)
  const TrustedRetailer(name: 'Zalando AT', baseUrl: 'https://www.zalando.at/', country: 'AT', domains: ['zalando.at']),
  const TrustedRetailer(name: 'OTTO AT', baseUrl: 'https://www.otto.at/', country: 'AT', domains: ['otto.at']),
  // Switzerland (CH)
  const TrustedRetailer(name: 'Zalando CH', baseUrl: 'https://www.zalando.ch/', country: 'CH', domains: ['zalando.ch']),
  // Belgium (BE)
  const TrustedRetailer(name: 'Zalando BE', baseUrl: 'https://www.zalando.be/', country: 'BE', domains: ['zalando.be']),
  // Poland (PL)
  const TrustedRetailer(name: 'Reserved', baseUrl: 'https://www.reserved.com/', country: 'PL', domains: ['reserved.com']),
  const TrustedRetailer(name: 'Zalando PL', baseUrl: 'https://www.zalando.pl/', country: 'PL', domains: ['zalando.pl']),
  const TrustedRetailer(name: 'CCC', baseUrl: 'https://www.ccc.eu/', country: 'PL', domains: ['ccc.eu']),
  // Sweden (SE)
  const TrustedRetailer(name: 'Nelly', baseUrl: 'https://www.nelly.com/', country: 'SE', domains: ['nelly.com']),
  const TrustedRetailer(name: 'Boozt', baseUrl: 'https://www.boozt.com/', country: 'SE', domains: ['boozt.com']),
  const TrustedRetailer(name: 'Zalando SE', baseUrl: 'https://www.zalando.se/', country: 'SE', domains: ['zalando.se']),
  // Norway (NO)
  const TrustedRetailer(name: 'Zalando NO', baseUrl: 'https://www.zalando.no/', country: 'NO', domains: ['zalando.no']),
  // Denmark (DK)
  const TrustedRetailer(name: 'Zalando DK', baseUrl: 'https://www.zalando.dk/', country: 'DK', domains: ['zalando.dk']),
  // Finland (FI)
  const TrustedRetailer(name: 'Zalando FI', baseUrl: 'https://www.zalando.fi/', country: 'FI', domains: ['zalando.fi']),
  // Portugal (PT)
  const TrustedRetailer(name: 'Zalando PT', baseUrl: 'https://www.zalando.pt/', country: 'PT', domains: ['zalando.pt']),
  const TrustedRetailer(name: 'Amazon PT', baseUrl: 'https://www.amazon.pt/', country: 'PT', domains: ['amazon.pt']),
  // Ireland (IE)
  const TrustedRetailer(name: 'ASOS IE', baseUrl: 'https://www.asos.com/', country: 'IE', domains: ['asos.com']),
  // Greece (GR)
  const TrustedRetailer(name: 'Skroutz', baseUrl: 'https://www.skroutz.gr/', country: 'GR', domains: ['skroutz.gr']),
  // Czech Republic (CZ)
  const TrustedRetailer(name: 'Zalando CZ', baseUrl: 'https://www.zalando.cz/', country: 'CZ', domains: ['zalando.cz']),
  // Hungary (HU)
  const TrustedRetailer(name: 'About You HU', baseUrl: 'https://www.aboutyou.hu/', country: 'HU', domains: ['aboutyou.hu']),
  // Romania (RO)
  const TrustedRetailer(name: 'eMAG RO', baseUrl: 'https://www.emag.ro/', country: 'RO', domains: ['emag.ro']),
  // Croatia (HR)
  const TrustedRetailer(name: 'About You HR', baseUrl: 'https://www.aboutyou.hr/', country: 'HR', domains: ['aboutyou.hr']),
  // Slovenia (SI)
  const TrustedRetailer(name: 'About You SI', baseUrl: 'https://www.aboutyou.si/', country: 'SI', domains: ['aboutyou.si']),
  // Slovakia (SK)
  const TrustedRetailer(name: 'About You SK', baseUrl: 'https://www.aboutyou.sk/', country: 'SK', domains: ['aboutyou.sk']),
  // Luxembourg (LU)
  const TrustedRetailer(name: 'Zalando LU', baseUrl: 'https://www.zalando.lu/', country: 'LU', domains: ['zalando.lu']),
  // Estonia (EE)
  const TrustedRetailer(name: 'About You EE', baseUrl: 'https://www.aboutyou.ee/', country: 'EE', domains: ['aboutyou.ee']),
  // Latvia (LV)
  const TrustedRetailer(name: 'About You LV', baseUrl: 'https://www.aboutyou.lv/', country: 'LV', domains: ['aboutyou.lv']),
  // Lithuania (LT)
  const TrustedRetailer(name: 'About You LT', baseUrl: 'https://www.aboutyou.lt/', country: 'LT', domains: ['aboutyou.lt']),
  // Bulgaria (BG)
  const TrustedRetailer(name: 'About You BG', baseUrl: 'https://www.aboutyou.bg/', country: 'BG', domains: ['aboutyou.bg']),
  // Ukraine (UA)
  const TrustedRetailer(name: 'Rozetka', baseUrl: 'https://rozetka.com.ua/', country: 'UA', domains: ['rozetka.com.ua']),
  // Israel (IL)
  const TrustedRetailer(name: 'Zap', baseUrl: 'https://www.zap.co.il/', country: 'IL', domains: ['zap.co.il']),
  // Taiwan (TW)
  const TrustedRetailer(name: 'momo', baseUrl: 'https://www.momoshop.com.tw/', country: 'TW', domains: ['momoshop.com.tw']),
  // Vietnam (VN)
  const TrustedRetailer(name: 'Shopee VN', baseUrl: 'https://shopee.vn/', country: 'VN', domains: ['shopee.vn']),
  const TrustedRetailer(name: 'Lazada VN', baseUrl: 'https://www.lazada.vn/', country: 'VN', domains: ['lazada.vn']),
  // Pakistan (PK)
  const TrustedRetailer(name: 'Daraz PK', baseUrl: 'https://www.daraz.pk/', country: 'PK', domains: ['daraz.pk']),
  // Bangladesh (BD)
  const TrustedRetailer(name: 'Daraz BD', baseUrl: 'https://www.daraz.com.bd/', country: 'BD', domains: ['daraz.com.bd']),
  // Sri Lanka (LK)
  const TrustedRetailer(name: 'Daraz LK', baseUrl: 'https://www.daraz.lk/', country: 'LK', domains: ['daraz.lk']),
  // Nepal (NP)
  const TrustedRetailer(name: 'Daraz NP', baseUrl: 'https://www.daraz.com.np/', country: 'NP', domains: ['daraz.com.np']),
  // Peru (PE)
  const TrustedRetailer(name: 'Falabella PE', baseUrl: 'https://www.falabella.com.pe/', country: 'PE', domains: ['falabella.com.pe']),
  // Ecuador (EC)
  const TrustedRetailer(name: 'Falabella EC', baseUrl: 'https://www.falabella.com.ec/', country: 'EC', domains: ['falabella.com.ec']),
  // Uruguay (UY)
  const TrustedRetailer(name: 'Mercado Libre UY', baseUrl: 'https://www.mercadolibre.com.uy/', country: 'UY', domains: ['mercadolibre.com.uy']),
  // Morocco (MA)
  const TrustedRetailer(name: 'Jumia MA', baseUrl: 'https://www.jumia.ma/', country: 'MA', domains: ['jumia.ma']),
  // Kenya (KE)
  const TrustedRetailer(name: 'Jumia KE', baseUrl: 'https://www.jumia.co.ke/', country: 'KE', domains: ['jumia.co.ke']),
  // Ghana (GH)
  const TrustedRetailer(name: 'Jumia GH', baseUrl: 'https://www.jumia.com.gh/', country: 'GH', domains: ['jumia.com.gh']),
  // Algeria (DZ)
  const TrustedRetailer(name: 'Jumia DZ', baseUrl: 'https://www.jumia.dz/', country: 'DZ', domains: ['jumia.dz']),
  // Tunisia (TN)
  const TrustedRetailer(name: 'Jumia TN', baseUrl: 'https://www.jumia.com.tn/', country: 'TN', domains: ['jumia.com.tn']),
  // Qatar (QA)
  const TrustedRetailer(name: 'Namshi QA', baseUrl: 'https://www.namshi.com/qatar/', country: 'QA', domains: ['namshi.com']),
  // Kuwait (KW)
  const TrustedRetailer(name: 'Namshi KW', baseUrl: 'https://www.namshi.com/kuwait/', country: 'KW', domains: ['namshi.com']),
  // Bahrain (BH)
  const TrustedRetailer(name: 'Namshi BH', baseUrl: 'https://www.namshi.com/bahrain/', country: 'BH', domains: ['namshi.com']),
  // Oman (OM)
  const TrustedRetailer(name: 'Namshi OM', baseUrl: 'https://www.namshi.com/oman/', country: 'OM', domains: ['namshi.com']),
  // Jordan (JO)
  const TrustedRetailer(name: 'Namshi JO', baseUrl: 'https://www.namshi.com/jordan/', country: 'JO', domains: ['namshi.com']),
  // Lebanon (LB)
  const TrustedRetailer(name: 'Namshi LB', baseUrl: 'https://www.namshi.com/lebanon/', country: 'LB', domains: ['namshi.com']),
  // Iraq (IQ)
  const TrustedRetailer(name: 'Noon IQ', baseUrl: 'https://www.noon.com/iraq-en/', country: 'IQ', domains: ['noon.com']),
  // Malta (MT)
  const TrustedRetailer(name: 'ASOS MT', baseUrl: 'https://www.asos.com/', country: 'MT', domains: ['asos.com']),
  // Cyprus (CY)
  const TrustedRetailer(name: 'ASOS CY', baseUrl: 'https://www.asos.com/', country: 'CY', domains: ['asos.com']),
  // Iceland (IS)
  const TrustedRetailer(name: 'Zalando IS', baseUrl: 'https://www.zalando.is/', country: 'IS', domains: ['zalando.is']),
  // Bolivia (BO)
  const TrustedRetailer(name: 'Mercado Libre BO', baseUrl: 'https://www.mercadolibre.com.bo/', country: 'BO', domains: ['mercadolibre.com.bo']),
  // Paraguay (PY)
  const TrustedRetailer(name: 'Mercado Libre PY', baseUrl: 'https://www.mercadolibre.com.py/', country: 'PY', domains: ['mercadolibre.com.py']),
  // Costa Rica (CR)
  const TrustedRetailer(name: 'Mercado Libre CR', baseUrl: 'https://www.mercadolibre.co.cr/', country: 'CR', domains: ['mercadolibre.co.cr']),
  // Panama (PA)
  const TrustedRetailer(name: 'Mercado Libre PA', baseUrl: 'https://www.mercadolibre.com.pa/', country: 'PA', domains: ['mercadolibre.com.pa']),
  // Dominican Republic (DO)
  const TrustedRetailer(name: 'Mercado Libre DO', baseUrl: 'https://www.mercadolibre.com.do/', country: 'DO', domains: ['mercadolibre.com.do']),
  // Puerto Rico (PR)
  const TrustedRetailer(name: 'Amazon PR', baseUrl: 'https://www.amazon.com/', country: 'PR', domains: ['amazon.com']),
  // Australia (AU)
  const TrustedRetailer(name: 'The Iconic', baseUrl: 'https://www.theiconic.com.au/', country: 'AU', domains: ['theiconic.com.au']),
  const TrustedRetailer(name: 'David Jones', baseUrl: 'https://www.davidjones.com/', country: 'AU', domains: ['davidjones.com']),
  const TrustedRetailer(name: 'Myer', baseUrl: 'https://www.myer.com.au/', country: 'AU', domains: ['myer.com.au']),
  const TrustedRetailer(name: 'Amazon AU', baseUrl: 'https://www.amazon.com.au/', country: 'AU', domains: ['amazon.com.au']),
  // Canada (CA)
  const TrustedRetailer(name: 'Hudson\'s Bay', baseUrl: 'https://www.thebay.com/', country: 'CA', domains: ['thebay.com']),
  const TrustedRetailer(name: 'SSENSE', baseUrl: 'https://www.ssense.com/', country: 'CA', domains: ['ssense.com']),
  const TrustedRetailer(name: 'Amazon CA', baseUrl: 'https://www.amazon.ca/', country: 'CA', domains: ['amazon.ca']),
  // Japan (JP)
  const TrustedRetailer(name: 'Zozotown', baseUrl: 'https://zozo.jp/', country: 'JP', domains: ['zozo.jp', 'zozotown.com']),
  const TrustedRetailer(name: 'Uniqlo JP', baseUrl: 'https://www.uniqlo.com/jp/', country: 'JP', domains: ['uniqlo.com']),
  const TrustedRetailer(name: 'Amazon JP', baseUrl: 'https://www.amazon.co.jp/', country: 'JP', domains: ['amazon.co.jp']),
  // India (IN)
  const TrustedRetailer(name: 'Myntra', baseUrl: 'https://www.myntra.com/', country: 'IN', domains: ['myntra.com']),
  const TrustedRetailer(name: 'Ajio', baseUrl: 'https://www.ajio.com/', country: 'IN', domains: ['ajio.com']),
  const TrustedRetailer(name: 'Flipkart Fashion', baseUrl: 'https://www.flipkart.com/', country: 'IN', domains: ['flipkart.com']),
  const TrustedRetailer(name: 'Amazon IN', baseUrl: 'https://www.amazon.in/', country: 'IN', domains: ['amazon.in']),
  // Brazil (BR)
  const TrustedRetailer(name: 'Dafiti', baseUrl: 'https://www.dafiti.com.br/', country: 'BR', domains: ['dafiti.com.br']),
  const TrustedRetailer(name: 'Amazon BR', baseUrl: 'https://www.amazon.com.br/', country: 'BR', domains: ['amazon.com.br']),
  // Mexico (MX)
  const TrustedRetailer(name: 'Liverpool', baseUrl: 'https://www.liverpool.com.mx/', country: 'MX', domains: ['liverpool.com.mx']),
  const TrustedRetailer(name: 'Amazon MX', baseUrl: 'https://www.amazon.com.mx/', country: 'MX', domains: ['amazon.com.mx']),
  // Argentina (AR)
  const TrustedRetailer(name: 'Falabella AR', baseUrl: 'https://www.falabella.com.ar/', country: 'AR', domains: ['falabella.com.ar']),
  const TrustedRetailer(name: 'Mercado Libre AR', baseUrl: 'https://www.mercadolibre.com.ar/', country: 'AR', domains: ['mercadolibre.com.ar']),
  // Colombia (CO)
  const TrustedRetailer(name: 'Falabella CO', baseUrl: 'https://www.falabella.com.co/', country: 'CO', domains: ['falabella.com.co']),
  // Chile (CL)
  const TrustedRetailer(name: 'Falabella CL', baseUrl: 'https://www.falabella.com/', country: 'CL', domains: ['falabella.com']),
  // Russia (RU)
  const TrustedRetailer(name: 'Wildberries', baseUrl: 'https://www.wildberries.ru/', country: 'RU', domains: ['wildberries.ru']),
  const TrustedRetailer(name: 'Lamoda', baseUrl: 'https://www.lamoda.ru/', country: 'RU', domains: ['lamoda.ru']),
  // South Korea (KR)
  const TrustedRetailer(name: 'Musinsa', baseUrl: 'https://www.musinsa.com/', country: 'KR', domains: ['musinsa.com']),
  const TrustedRetailer(name: 'Coupang', baseUrl: 'https://www.coupang.com/', country: 'KR', domains: ['coupang.com']),
  const TrustedRetailer(name: 'W Concept', baseUrl: 'https://www.wconcept.co.kr/', country: 'KR', domains: ['wconcept.co.kr']),
  // Turkey (TR)
  const TrustedRetailer(name: 'Trendyol', baseUrl: 'https://www.trendyol.com/', country: 'TR', domains: ['trendyol.com']),
  const TrustedRetailer(name: 'Hepsiburada', baseUrl: 'https://www.hepsiburada.com/', country: 'TR', domains: ['hepsiburada.com']),
  const TrustedRetailer(name: 'LC Waikiki', baseUrl: 'https://www.lcwaikiki.com/', country: 'TR', domains: ['lcwaikiki.com']),
  // UAE
  const TrustedRetailer(name: 'Namshi', baseUrl: 'https://www.namshi.com/', country: 'UAE', domains: ['namshi.com']),
  const TrustedRetailer(name: 'Noon', baseUrl: 'https://www.noon.com/', country: 'UAE', domains: ['noon.com']),
  const TrustedRetailer(name: 'Ounass', baseUrl: 'https://www.ounass.ae/', country: 'UAE', domains: ['ounass.ae']),
  // Saudi Arabia (SA)
  const TrustedRetailer(name: 'Namshi SA', baseUrl: 'https://www.namshi.com/saudi-arabia/', country: 'SA', domains: ['namshi.com']),
  // South Africa (ZA)
  const TrustedRetailer(name: 'Superbalist', baseUrl: 'https://www.superbalist.com/', country: 'ZA', domains: ['superbalist.com']),
  const TrustedRetailer(name: 'Takealot', baseUrl: 'https://www.takealot.com/', country: 'ZA', domains: ['takealot.com']),
  const TrustedRetailer(name: 'Mr Price', baseUrl: 'https://www.mrp.com/', country: 'ZA', domains: ['mrp.com']),
  // Nigeria (NG)
  const TrustedRetailer(name: 'Jumia NG', baseUrl: 'https://www.jumia.com.ng/', country: 'NG', domains: ['jumia.com.ng']),
  // Egypt (EG)
  const TrustedRetailer(name: 'Jumia EG', baseUrl: 'https://www.jumia.com.eg/', country: 'EG', domains: ['jumia.com.eg']),
  // Indonesia (ID)
  const TrustedRetailer(name: 'Tokopedia', baseUrl: 'https://www.tokopedia.com/', country: 'ID', domains: ['tokopedia.com']),
  const TrustedRetailer(name: 'Shopee ID', baseUrl: 'https://shopee.co.id/', country: 'ID', domains: ['shopee.co.id']),
  // Thailand (TH)
  const TrustedRetailer(name: 'Lazada TH', baseUrl: 'https://www.lazada.co.th/', country: 'TH', domains: ['lazada.co.th']),
  const TrustedRetailer(name: 'Central', baseUrl: 'https://www.central.co.th/', country: 'TH', domains: ['central.co.th']),
  // Malaysia (MY)
  const TrustedRetailer(name: 'Zalora MY', baseUrl: 'https://www.zalora.com.my/', country: 'MY', domains: ['zalora.com.my']),
  const TrustedRetailer(name: 'Shopee MY', baseUrl: 'https://shopee.com.my/', country: 'MY', domains: ['shopee.com.my']),
  // Singapore (SG)
  const TrustedRetailer(name: 'Zalora SG', baseUrl: 'https://www.zalora.sg/', country: 'SG', domains: ['zalora.sg']),
  const TrustedRetailer(name: 'ASOS SG', baseUrl: 'https://www.asos.com/', country: 'SG', domains: ['asos.com']),
  // Philippines (PH)
  const TrustedRetailer(name: 'Zalora PH', baseUrl: 'https://www.zalora.com.ph/', country: 'PH', domains: ['zalora.com.ph']),
  const TrustedRetailer(name: 'Shopee PH', baseUrl: 'https://shopee.ph/', country: 'PH', domains: ['shopee.ph']),
  // New Zealand (NZ)
  const TrustedRetailer(name: 'The Iconic NZ', baseUrl: 'https://www.theiconic.co.nz/', country: 'NZ', domains: ['theiconic.co.nz']),
  const TrustedRetailer(name: 'David Jones NZ', baseUrl: 'https://www.davidjones.com/', country: 'NZ', domains: ['davidjones.com']),
  // China (CN) – international-facing
  const TrustedRetailer(name: 'Tmall Global', baseUrl: 'https://www.tmall.com/', country: 'CN', domains: ['tmall.com']),
  const TrustedRetailer(name: 'JD Worldwide', baseUrl: 'https://global.jd.com/', country: 'CN', domains: ['jd.com']),
  // Hong Kong (HK)
  const TrustedRetailer(name: 'Zalora HK', baseUrl: 'https://www.zalora.com.hk/', country: 'HK', domains: ['zalora.com.hk']),
  // Global / multi-country (kept for broad matching)
  const TrustedRetailer(name: 'Zara', baseUrl: 'https://www.zara.com/', country: 'Global', domains: ['zara.com']),
  const TrustedRetailer(name: 'H&M', baseUrl: 'https://www2.hm.com/', country: 'Global', domains: ['hm.com', 'h-m.com']),
  const TrustedRetailer(name: 'Uniqlo', baseUrl: 'https://www.uniqlo.com/', country: 'Global', domains: ['uniqlo.com']),
  const TrustedRetailer(name: 'Net-a-Porter', baseUrl: 'https://www.net-a-porter.com/', country: 'Global', domains: ['net-a-porter.com']),
  const TrustedRetailer(name: 'Farfetch', baseUrl: 'https://www.farfetch.com/', country: 'Global', domains: ['farfetch.com']),
  const TrustedRetailer(name: 'Shein', baseUrl: 'https://www.shein.com/', country: 'Global', domains: ['shein.com']),
];

/// All domains from trusted retailers (for link detection).
Set<String> get trustedRetailerDomains {
  final set = <String>{};
  for (final r in trustedFashionRetailers) {
    for (final d in r.domains) {
      set.add(d.toLowerCase());
    }
  }
  return set;
}

/// Locale country code → our list country (e.g. GB → UK).
String _normalizeCountryCode(String code) {
  final c = code.toUpperCase();
  if (c == 'GB') return 'UK';
  return c;
}

/// Retailers for a given country code (e.g. "DE", "US", "GB"). Empty if none.
List<TrustedRetailer> getRetailersForCountry(String countryCode) {
  final code = _normalizeCountryCode(countryCode);
  return trustedFashionRetailers
      .where((r) => r.country.toUpperCase() == code)
      .toList();
}

/// Format retailers for system prompt (name + URL).
/// If [userCountryCode] is set (e.g. from device locale), tell the AI to suggest based on user's location first.
String getTrustedRetailersPromptText({String? userCountryCode}) {
  final buffer = StringBuffer();
  if (userCountryCode != null && userCountryCode.isNotEmpty) {
    final code = _normalizeCountryCode(userCountryCode);
    final local = getRetailersForCountry(userCountryCode);
    buffer.writeln('User\'s current location/country: $code. When the user asks where to buy clothes or for shop suggestions, prioritize and suggest retailers in their country first (based on their location).');
    if (local.isNotEmpty) {
      buffer.writeln('Retailers in user\'s country ($code) — suggest these first:');
      for (final r in local) {
        buffer.writeln('- ${r.name}: ${r.baseUrl}');
      }
      buffer.writeln('');
    }
    buffer.writeln('Other trusted fashion retailers (suggest if relevant or if user is shopping abroad):');
  } else {
    buffer.writeln('Trusted fashion retailers you can suggest for buying clothes:');
  }
  for (final r in trustedFashionRetailers) {
    if (userCountryCode != null &&
        userCountryCode.isNotEmpty &&
        r.country.toUpperCase() == _normalizeCountryCode(userCountryCode)) {
      continue; // already listed above
    }
    buffer.writeln('- ${r.name} (${r.country}): ${r.baseUrl}');
  }
  buffer.writeln('');
  buffer.writeln('Do NOT list these URLs in your normal replies. Use them only when the user asks where to buy — then reply with a short message and end with exactly: BUY_LINK=<one_url> (e.g. BUY_LINK=https://www.zalando.de/).');
  buffer.writeln('When the user shares a product link, tell them: "Use the 📷 button to upload the product image or a screenshot, then I can help you try it on."');
  return buffer.toString();
}

/// Check if a URL is from a trusted retailer domain.
bool isTrustedRetailerUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase().replaceFirst('www.', '');
    for (final d in trustedRetailerDomains) {
      if (host == d || host.endsWith('.$d')) return true;
    }
  } catch (_) {}
  return false;
}

/// Check if a URL looks like a direct image URL (for try-on from link).
bool isDirectImageUrl(String url) {
  try {
    final u = url.trim().toLowerCase();
    if (!u.startsWith('http://') && !u.startsWith('https://')) return false;
    if (u.endsWith('.jpg') || u.endsWith('.jpeg') || u.endsWith('.png') ||
        u.endsWith('.webp') || u.endsWith('.gif')) {
      return true;
    }
    // Common CDN path patterns
    if (u.contains('/images/') || u.contains('img.') || u.contains('cdn.') ||
        u.contains('static.') && (u.contains('.jpg') || u.contains('.png'))) {
      return true;
    }
  } catch (_) {}
  return false;
}
