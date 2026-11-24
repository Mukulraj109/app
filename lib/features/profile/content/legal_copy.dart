// In-app Terms and Privacy mirrored from web TermsPage + PrivacyPolicyPage.

class LegalSection {
  const LegalSection({
    required this.title,
    required this.paragraphs,
    this.bullets = const [],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
}

const termsLead =
    'FirstStepJob Services operates firststepjob.com and sells digital career-support services: job application submission by human team members, interview preparation tools, resume support, and related coaching. By using the website, this app, or a paid plan, you agree to the privacy policy and the refund policy. FirstStep is not a recruitment agency and does not guarantee interviews or job offers.';

const termsSections = <LegalSection>[
  LegalSection(
    title: 'Services',
    paragraphs: [
      'Services are delivered electronically through the dashboard, this app, email, and online communication. No physical goods are shipped. Plan entitlements are described on the pricing page and may change; the dashboard reflects the active plan.',
    ],
  ),
  LegalSection(
    title: 'Accounts',
    paragraphs: [
      'You must provide accurate information and keep credentials confidential. You are responsible for activity on your account. FirstStep may suspend access for abuse, unpaid invoices, or legal risk.',
    ],
  ),
  LegalSection(
    title: 'Payments and cancellations',
    paragraphs: [
      'Payments are processed by Razorpay. Card data is not stored by FirstStep. Cancellation and refunds follow the refund policy published on firststepjob.com.',
    ],
  ),
  LegalSection(
    title: 'Privacy',
    paragraphs: [
      'Personal data is handled as described in the Privacy policy section below and the security page on the website. Contact connect@firststepjob.com for legal notices related to these terms.',
    ],
  ),
];

const privacyEffectiveDate = 'July 1, 2025';

const privacyIntro =
    'This Privacy Policy describes how FirstStepJob Services (“we”, “our”, or “us”) collects, uses, stores, and protects your personal information when you use our website https://firststepjob.com, this mobile app, our services, payments, and integrated Google features. By using our website, app, or services, you agree to the terms of this Privacy Policy.';

const privacySections = <LegalSection>[
  LegalSection(
    title: '1. Information We Collect',
    paragraphs: [
      'A. Information You Provide to Us',
      'B. Google User Data (If You Use Google Login or Google APIs)',
      'Depending on permissions you grant during login, we may access your Google email address, your Google profile basic information, and Google Drive files (only if you explicitly upload your resume from Drive).',
      'We do not access your Gmail content, calendars, contacts, or any other Google data unless you explicitly grant permission.',
    ],
    bullets: [
      'Full Name',
      'Email Address',
      'Phone Number',
    ],
  ),
  LegalSection(
    title: '2. How We Use Your Information',
    paragraphs: [
      'A. General Website / App Data — to contact you in response to inquiries; to support resume building and job application services; to send updates, notifications, or onboarding details; and to improve our platform and user experience.',
      'B. Google User Data is used only for authenticating your account using Google Login, allowing you to upload resumes directly from Google Drive (if permitted), and pre-filling your profile information to save time.',
      'We do not use Google data for marketing, advertising, profiling, or resale.',
    ],
  ),
  LegalSection(
    title: '3. Sharing of Information',
    paragraphs: [
      'We may share your data only in the following cases. We never sell, rent, or trade your personal data to third parties.',
    ],
    bullets: [
      'With trusted service providers (email tools, analytics providers, cloud hosting)',
      'With Google APIs strictly under Google\'s Limited Use Policy',
      'If required by law, court order, or government request',
    ],
  ),
  LegalSection(
    title: '4. Payments, Billing, Refunds, and Shipping',
    paragraphs: [
      'All payments made on FirstStepJob are processed securely through Razorpay, a third-party payment gateway.',
      'We do not store, process, or have access to your credit/debit card details, UPI information, or banking credentials. All sensitive payment information is handled directly by Razorpay.',
      'Refunds or cancellations, if applicable, are governed by our internal policies. Approved refunds will be credited to the original payment method within 7–10 working days, subject to Razorpay\'s processing timelines.',
      'FirstStepJob provides digital services only. No physical goods are shipped or delivered. All services are provided electronically via email, dashboard or app access, or online communication.',
    ],
  ),
  LegalSection(
    title: '5. Data Storage and Security',
    paragraphs: [
      'Your data is stored securely using modern encryption and access-control practices. We use industry-level cloud providers such as MongoDB Atlas and AWS / Render hosting.',
      'Google user data is stored only if required for service functionality and only with your explicit consent.',
    ],
  ),
  LegalSection(
    title: '6. Cookies and Tracking',
    paragraphs: [
      'We use cookies for basic analytics, authentication, and essential website functionality. You may disable cookies via your browser settings. The mobile app uses similar session and analytics controls for signed-in features.',
    ],
  ),
  LegalSection(
    title: '7. Third-Party Links',
    paragraphs: [
      'Our website and app may contain links to third-party websites. We are not responsible for the content or privacy practices of external sites.',
    ],
  ),
  LegalSection(
    title: '8. Your Rights and Choices',
    paragraphs: [
      'You may request access to or deletion of your account or uploaded files; request a copy or correction of your personal data; and disconnect Google access at any time via your Google Account settings. In this app you can also request deletion from Settings → Delete account.',
    ],
  ),
  LegalSection(
    title: '9. Children\'s Privacy',
    paragraphs: [
      'Our services are not intended for children under 13 years of age. We do not knowingly collect personal data from minors.',
    ],
  ),
  LegalSection(
    title: '10. Google API Services Disclosure',
    paragraphs: [
      'FirstStepJob\'s use of Google user data complies with the Google API Services User Data Policy, including the Limited Use requirements.',
      'We only access Google data to provide features explicitly requested by the user (such as Google Login or Google Drive file upload). We never use Google data for advertising or unauthorized purposes.',
    ],
  ),
  LegalSection(
    title: '11. Updates to This Policy',
    paragraphs: [
      'We may update this Privacy Policy from time to time. Changes will be posted on the website privacy page with an updated effective date.',
    ],
  ),
  LegalSection(
    title: '12. Contact Us',
    paragraphs: [
      'For any questions regarding this Privacy Policy or our data practices, contact connect@firststepjob.com or visit https://firststepjob.com.',
    ],
  ),
];
