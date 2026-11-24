import 'dart:math' as math;
import 'dart:ui';

// Ported from scoutxScraperAssets.ts + ScoutXScraperHeroLoop motion helpers.

abstract final class ScoutXScraper {
  static const cw = 1440.0;
  static const ch = 960.0;
  static const loop = 8.0;
  static const step = 0.5;
  static const off = 3.0;

  static const ink = Color(0xFF0E2D3A);
  static const muted = Color(0xFF5D6068);
  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE6E4DD);
  static const logoChip = Color(0xFFF6F5F1);
  static const feedShell = Color(0x99FFFFFF);
  static const feedBorder = Color(0xFFE4E2DA);
  static const rackBody = Color(0xFF191B21);
  static const rackUnit = Color(0xFF23262E);
  static const rackVent = Color(0xFF30343E);
  static const rackLedOff = Color(0xFF393D47);
  static const rackLedIdle = Color(0xFF8FB0FF);
  static const rackFoot = Color(0xFF0F1014);

  static const rx0 = 240.0;
  static const rw = 320.0;
  static const ry = 560.0;
  static const tw = 160.0;
  static const th = 62.0;
  static const fx = 1040.0;
  static const fy = 240.0;
  static const fwc = 360.0;
  static const fh = 72.0;
  static const rh = 82.0;
  static const feedN = 5;

  static const muzzleX = rx0 + rw / 2;
  static const muzzleY = ry;
}

abstract final class ScoutXScraperK {
  static const fire = 0.35;
  static const hit = 0.6;
  static const badge = 0.66;
  static const inS = 0.8;
  static const inE = 1.25;
  static const exS = 1.5;
  static const exE = 1.95;
  static const out = 1.95;
  static const end = 2.4;
}

int sxBinOf(int companyIndex) =>
    scoutxBinOf[companyIndex % scoutxBinOf.length];

class ScoutXClusterBin {
  final String name;
  final int base;
  final double x;
  final double y;
  final double w;
  final double h;
  int count;
  double pulse;

  ScoutXClusterBin({
    required this.name,
    required this.base,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  })  : count = base,
        pulse = 0;
}

const scoutXScraperTitles = [
  'SDE II',
  'Senior Software Engineer',
  'Backend Engineer, Infra',
  'ML Engineer',
  'Staff Engineer, Platform',
  'Frontend Engineer',
  'iOS Engineer',
  'Data Engineer',
  'SRE, Cloud',
  'Product Engineer',
  'Platform Engineer',
  'Research Software Eng.',
  'Cloud Architect',
  'Quantitative Analyst',
  'Solutions Engineer',
  'Strategy Analyst',
];

const scoutXScraperLocs = [
  'Seattle',
  'Redmond',
  'Mountain View',
  'Menlo Park',
  'Cupertino',
  'San Francisco',
  'New York',
  'San Francisco',
  'Santa Clara',
  'Bentonville',
  'San Francisco',
  'Boston',
  'Austin',
  'New York',
  'San Francisco',
  'Chicago',
];

const scoutXRoleBadges = [3, 1, 4, 2, 6, 2, 3, 1, 5, 2, 4, 3, 2, 4, 3, 2];

const scoutXScraperCompanies = [
  'Amazon',
  'Oracle',
  'Uber',
  'Pinterest',
  'Target',
  'SoFi',
  'Ralph Lauren',
  'Stanford',
  'Microsoft',
  'Google',
  'Meta',
  'Apple',
  'Nvidia',
  'Netflix',
  'Tesla',
  'JPMorgan',
  'Goldman Sachs',
  'IBM',
  'Cisco',
  'Intel',
  'Adobe',
  'Salesforce',
  'Snowflake',
  'Stripe',
];

const scoutxScraperDomains = [
  'amazon.com',
  'oracle.com',
  'uber.com',
  'pinterest.com',
  'target.com',
  'sofi.com',
  'ralphlauren.com',
  'stanford.edu',
  'microsoft.com',
  'google.com',
  'meta.com',
  'apple.com',
  'nvidia.com',
  'netflix.com',
  'tesla.com',
  'jpmorganchase.com',
  'goldmansachs.com',
  'ibm.com',
  'cisco.com',
  'intel.com',
  'adobe.com',
  'salesforce.com',
  'snowflake.com',
  'stripe.com',
];

const scoutxBinOf = [
  0, 0, 1, 1, 3, 2, 3, 3,
  0, 0, 0, 0, 0, 0, 3, 2,
  2, 0, 0, 0, 0, 0, 1, 1,
];

const scoutxLogoFiles = [
  'amazon.svg',
  'oracle.svg',
  'uber.svg',
  'pinterest.svg',
  'target.svg',
  'sofi.svg',
  'ralph-lauren.svg',
  'stanford.svg',
  'microsoft.svg',
  'google.svg',
  'meta.svg',
  'apple.svg',
  'nvidia.svg',
  'netflix.svg',
  'tesla.svg',
  'jpmorgan.svg',
  'goldman.svg',
  'ibm.svg',
  'cisco.svg',
  'intel.svg',
  'adobe.svg',
  'salesforce.svg',
  'snowflake.svg',
  'stripe.svg',
];

const _slotCols = [120.0, 290.0, 460.0, 630.0];
const _slotRows = [70.0, 185.0, 300.0, 415.0];
const _slotRoff = [0.0, 22.0, -12.0, 14.0];
const _slotOrder = [
  [0, 0],
  [0, 2],
  [1, 1],
  [0, 3],
  [1, 0],
  [2, 2],
  [0, 1],
  [1, 3],
  [2, 0],
  [3, 1],
  [2, 3],
  [3, 0],
  [1, 2],
  [3, 2],
  [2, 1],
  [3, 3],
];

List<Offset> get scoutxScraperSlots => _slotOrder
    .map(
      (p) => Offset(
        _slotCols[p[1]] + _slotRoff[p[0]],
        _slotRows[p[0]],
      ),
    )
    .toList(growable: false);

const scoutXScraperBinDefs = [
  ('Big Tech', 1840, 1040.0, 752.0, 168.0, 58.0),
  ('Startups', 2612, 1220.0, 752.0, 168.0, 58.0),
  ('Finance', 1377, 1040.0, 820.0, 168.0, 58.0),
  ('Fortune 500', 3095, 1220.0, 820.0, 168.0, 58.0),
];

int sxCompanyAt(int slot, double absT) {
  const loop = ScoutXScraper.loop;
  final n = _slotOrder.length;
  final pool = scoutXScraperCompanies.length;
  final cycle = (math.max(0, absT) / loop).floor();
  final offset = (cycle * n) % pool;
  return (offset + (slot % n)) % pool;
}

String scoutxFavicon(String domain) =>
    'https://www.google.com/s2/favicons?domain=$domain&sz=128';

String scoutxLogoAsset(int companyIndex) =>
    'assets/scoutx/logos/${scoutxLogoFiles[companyIndex]}';

double sxCl(double v, double a, double b) => v.clamp(a, b);

double sxSeg(double t, double a, double b) => sxCl((t - a) / (b - a), 0, 1);

double sxMod(double v, double m) => ((v % m) + m) % m;

double sxLerp(double a, double b, double u) => a + (b - a) * u;

double sxEnter(double p) => 1 - math.pow(1 - sxCl(p, 0, 1), 3).toDouble();

double sxDraw(double p) {
  final x = sxCl(p, 0, 1);
  return x * x;
}

double sxPop(double p) {
  final t = sxCl(p, 0, 1);
  const c1 = 1.70158;
  const c3 = c1 + 1;
  return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
}

double sxBumpAt(double t, double a, double b) =>
    t > a && t < b ? math.sin(math.pi * sxSeg(t, a, b)) : 0;

double sxRnd(double n) {
  final s = math.sin(n * 12.9898) * 43758.5453;
  return s - s.floor();
}