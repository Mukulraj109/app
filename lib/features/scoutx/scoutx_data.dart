// Static marketing copy for the ScoutX landing — ported from
// ScoutXLandingContent.tsx / ScoutXHowItWorks.tsx / scoutxMedia.ts.

/// Opens the FirstStep website ScoutX page (no in-app PIN / login gate).
const scoutXWebUrl = 'https://firststepjob.com/scoutx';

const scoutXTrustPills = ['Fast', 'Frequent', 'Focused'];

const scoutXBandItems = [
  "ScoutX is FirstStep's in-house hyper-scraper",
  'now open to everyone',
  'Real listings',
  'straight from the source',
];

const scoutXTrackingCompanies = [
  'Google',
  'Meta',
  'Apple',
  'Netflix',
  'Microsoft',
  'Amazon',
  'Nvidia',
  'Stripe',
  'Airbnb',
  'Uber',
  'Oracle',
  'Salesforce',
  'Adobe',
  'IBM',
  'Intel',
  'Cisco',
  'Tesla',
  'JPMorgan Chase',
  'Goldman Sachs',
  'Pfizer',
  'Johnson & Johnson',
  'Walmart',
  'Costco',
  'Disney',
  'Boeing',
  'McKinsey',
  'BCG',
  'Bain',
  'Deloitte',
  'Shopify',
  'DoorDash',
  'Visa',
  'Slack',
  'Zoom',
  'Cloudflare',
  'Datadog',
  'Notion',
  'Okta',
  'Home Depot',
  'CVS',
  'Red Hat',
  'Honeywell',
];

class ScoutXStat {
  final String value;
  final String label;
  final bool accent;
  const ScoutXStat(this.value, this.label, {this.accent = false});
}

const scoutXStats = [
  ScoutXStat('99.98%', 'Ingestion uptime'),
  ScoutXStat('4+ / min', 'Career pages scanned every minute', accent: true),
  ScoutXStat('4,500+', 'Companies tracked'),
  ScoutXStat('150', 'Curated clusters'),
];

class ScoutXReel {
  final String tag;
  final String title;
  final String desc;
  final String src;
  final String poster;
  const ScoutXReel({
    required this.tag,
    required this.title,
    required this.desc,
    required this.src,
    required this.poster,
  });
}

const _bunny = 'https://vz-bb5723d1-a73.b-cdn.net';

const scoutXReels = [
  ScoutXReel(
    tag: '01 · Catalog',
    title: 'Browse clusters',
    desc: 'Industry × city × company sets, curated for you.',
    src: '$_bunny/935c877b-e5fa-40ae-95fe-30e652da1359/playlist.m3u8',
    poster: '$_bunny/935c877b-e5fa-40ae-95fe-30e652da1359/thumbnail_f13d52f2.jpg',
  ),
  ScoutXReel(
    tag: '02 · Subscribe',
    title: 'Subscribe in seconds',
    desc: 'One click and the cluster starts streaming.',
    src: '$_bunny/eb13ceac-f034-4d32-b7c2-0540dfb46a80/playlist.m3u8',
    poster: '$_bunny/eb13ceac-f034-4d32-b7c2-0540dfb46a80/thumbnail_15332d0c.jpg',
  ),
  ScoutXReel(
    tag: '03 · Sync',
    title: 'Live feed',
    desc: 'Every company in your cluster, every run.',
    src: '$_bunny/f7f2054a-d645-4009-a321-6ed9db89d11a/playlist.m3u8',
    poster: '$_bunny/f7f2054a-d645-4009-a321-6ed9db89d11a/thumbnail_6842e618.jpg',
  ),
  ScoutXReel(
    tag: '04 · Act',
    title: 'Apply or assign',
    desc: "Apply yourself, or send it to FirstStep's team.",
    src: '$_bunny/a778ab67-43ba-4605-9d16-9ed2acea7515/playlist.m3u8',
    poster: '$_bunny/a778ab67-43ba-4605-9d16-9ed2acea7515/thumbnail_b6ca3200.jpg',
  ),
];

class ScoutXHowStep {
  final String n;
  final String title;
  final String body;
  final List<String> points;
  const ScoutXHowStep({
    required this.n,
    required this.title,
    required this.body,
    required this.points,
  });
}

const scoutXHowSteps = [
  ScoutXHowStep(
    n: '01',
    title: 'Pick a cluster',
    body:
        'Start from one of 150 curated sets, or build your own from up to 50 companies you actually want to work at.',
    points: [
      'Curated by industry × city × company',
      'Custom clusters up to 50 companies',
      'Ops keeps curated sets current',
    ],
  ),
  ScoutXHowStep(
    n: '02',
    title: 'Roles stream in',
    body:
        'Curated clusters are scraped every minute and stream nonstop. Custom clusters run on a window you set, from 1h to 24h.',
    points: [
      'Curated: live, every minute',
      'Custom: your 1h–24h window',
      'Every company hit on every run',
    ],
  ),
  ScoutXHowStep(
    n: '03',
    title: 'Apply, or assign to FirstStep',
    body:
        "ScoutX finds the roles. You decide what happens next: apply on the employer's site yourself, or hand it to FirstStep's application team.",
    points: [
      "Direct link to the employer's careers page",
      "FirstStep's team applies on your behalf",
      'Nothing is ever auto-applied',
    ],
  ),
];

class ScoutXCluster {
  final String name;
  final String sub;
  final List<String> domains;
  final String more;
  final int roles;
  final int cos;
  const ScoutXCluster({
    required this.name,
    required this.sub,
    required this.domains,
    required this.more,
    required this.roles,
    required this.cos,
  });

  List<String> get faviconUrls => domains
      .map((d) => 'https://www.google.com/s2/favicons?domain=$d&sz=128')
      .toList();
}

const scoutXClusters = [
  ScoutXCluster(
    name: 'FAANG Software Engineering',
    sub: 'Bay Area · Seattle · remote-friendly',
    domains: ['meta.com', 'apple.com', 'amazon.com', 'google.com'],
    more: '+8',
    roles: 214,
    cos: 12,
  ),
  ScoutXCluster(
    name: 'NYC Strategy & Consulting',
    sub: 'MBB · Big Four · boutique advisory',
    domains: ['mckinsey.com', 'bain.com', 'bcg.com', 'deloitte.com'],
    more: '+144',
    roles: 61,
    cos: 148,
  ),
  ScoutXCluster(
    name: 'Healthcare Texas',
    sub: 'Clinical · operations · health tech',
    domains: [
      'bswhealth.com',
      'utsouthwestern.edu',
      'hcahealthcare.com',
      'tenethealth.com',
    ],
    more: '+72',
    roles: 89,
    cos: 76,
  ),
];

class ScoutXFeedRole {
  final String title;
  final String company;
  final String loc;
  const ScoutXFeedRole(this.title, this.company, this.loc);
}

/// Dummy feed rows for the compact hero loop (from scoutxScraperAssets).
const scoutXFeedRoles = [
  ScoutXFeedRole('SDE II', 'Amazon', 'Seattle'),
  ScoutXFeedRole('Senior Software Engineer', 'Microsoft', 'Redmond'),
  ScoutXFeedRole('Backend Engineer, Infra', 'Google', 'Mountain View'),
  ScoutXFeedRole('ML Engineer', 'Meta', 'Menlo Park'),
  ScoutXFeedRole('iOS Engineer', 'Apple', 'Cupertino'),
  ScoutXFeedRole('Frontend Engineer', 'Stripe', 'San Francisco'),
  ScoutXFeedRole('Staff Engineer, Platform', 'Netflix', 'Los Gatos'),
  ScoutXFeedRole('Data Engineer', 'Uber', 'San Francisco'),
];
