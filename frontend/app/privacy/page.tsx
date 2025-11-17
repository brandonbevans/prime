import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Privacy Policy | WealthIQ",
  description:
    "WealthIQ Privacy Policy. Learn how we collect, use, and protect your personal information.",
};

const sections = [
  {
    title: "Information We Collect",
    content: `We collect information that you provide directly to us, including:
- Account information (email address, name)
- Content you create (goals, reflections, habit tracking data)
- Usage data (how you interact with the app)
- Device information (device type, operating system)
- Payment information (processed securely through Apple's payment system)`,
  },
  {
    title: "How We Use Your Information",
    content: `We use the information we collect to:
- Provide, maintain, and improve our services
- Process transactions and send related information
- Send you technical notices and support messages
- Respond to your comments and questions
- Monitor and analyze trends and usage
- Personalize your experience within the app`,
  },
  {
    title: "Data Storage and Security",
    content: `We implement appropriate technical and organizational measures to protect your personal information. Your data is encrypted in transit and at rest. We use industry-standard security practices to safeguard your information against unauthorized access, disclosure, alteration, or destruction.`,
  },
  {
    title: "Data Sharing",
    content: `We do not sell your personal information. We may share your information only in the following circumstances:
- With your explicit consent
- To comply with legal obligations
- To protect our rights and safety
- With service providers who assist us in operating the app (under strict confidentiality agreements)
- In connection with a business transfer (merger, acquisition, etc.)`,
  },
  {
    title: "Your Rights and Choices",
    content: `You have the right to:
- Access your personal data
- Correct inaccurate data
- Request deletion of your data
- Object to processing of your data
- Export your data
- Withdraw consent at any time

To exercise these rights, please contact us at privacy@wealthiq.app.`,
  },
  {
    title: "Third-Party Services",
    content: `WealthIQ may integrate with third-party services for analytics, payment processing, and other functionality. These services have their own privacy policies. We use:
- Apple App Store (for subscription management)
- Analytics providers (to understand app usage)
- Cloud storage providers (to securely store your data)`,
  },
  {
    title: "Children's Privacy",
    content: `WealthIQ is not intended for users under the age of 13. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.`,
  },
  {
    title: "Changes to This Policy",
    content: `We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new policy on this page and updating the "Last Updated" date. We encourage you to review this policy periodically.`,
  },
  {
    title: "Contact Us",
    content: `If you have questions about this Privacy Policy or our data practices, please contact us at:

Email: privacy@wealthiq.app
Support: support@wealthiq.app`,
  },
];

export default function Privacy() {
  const year = new Date().getFullYear();
  const lastUpdated = "January 2025";

  return (
    <div className="relative min-h-screen overflow-hidden bg-slate-950 text-slate-100">
      <div className="absolute inset-0 -z-10 bg-[radial-gradient(circle_at_top,_rgba(212,175,55,0.14),transparent_55%),radial-gradient(circle_at_bottom,_rgba(30,64,175,0.28),transparent_60%)]" />
      <main className="mx-auto flex min-h-screen w-full max-w-4xl flex-col px-6 pb-20 pt-24 sm:px-10">
        <header className="mb-12">
          <Link
            href="/"
            className="inline-flex items-center gap-2 text-sm text-slate-400 transition hover:text-amber-300"
          >
            <span>←</span> Back to home
          </Link>
          <h1 className="mt-6 text-4xl font-semibold leading-tight tracking-tight sm:text-5xl">
            Privacy Policy
          </h1>
          <p className="mt-4 text-sm text-slate-400">
            Last Updated: {lastUpdated}
          </p>
          <p className="mt-4 text-lg leading-relaxed text-slate-300">
            At WealthIQ, we are committed to protecting your privacy. This Privacy
            Policy explains how we collect, use, disclose, and safeguard your
            information when you use our mobile application and services.
          </p>
        </header>

        <section className="space-y-12">
          {sections.map((section, index) => (
            <div key={index} className="space-y-4">
              <h2 className="text-2xl font-semibold tracking-tight text-slate-100">
                {section.title}
              </h2>
              <div className="prose prose-invert max-w-none">
                <p className="whitespace-pre-line text-base leading-relaxed text-slate-300">
                  {section.content}
                </p>
              </div>
            </div>
          ))}
        </section>

        <section className="mt-16 rounded-3xl border border-white/10 bg-white/[0.06] p-8">
          <h2 className="text-xl font-semibold text-slate-100">
            Questions About Privacy?
          </h2>
          <p className="mt-2 text-base text-slate-300">
            If you have any questions or concerns about this Privacy Policy or our
            data practices, please don&apos;t hesitate to reach out to us.
          </p>
          <div className="mt-6 flex flex-col gap-4 sm:flex-row">
            <a
              href="mailto:privacy@wealthiq.app?subject=Privacy%20Policy%20Question"
              className="inline-flex items-center justify-center rounded-full border border-amber-200/60 bg-amber-200/20 px-6 py-3 text-sm font-semibold text-amber-50 transition hover:bg-amber-200/30 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber-100"
            >
              Contact Privacy Team
            </a>
            <Link
              href="/support"
              className="inline-flex items-center justify-center rounded-full border border-white/20 px-6 py-3 text-sm font-semibold text-slate-100 transition hover:border-amber-200/60 hover:text-amber-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber-100"
            >
              Visit Support Center
            </Link>
          </div>
        </section>

        <footer className="mt-24 border-t border-white/10 pt-8 text-sm text-slate-500">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <p>Copyright {year} WealthIQ. All rights reserved.</p>
            <div className="flex gap-6">
              <Link
                href="/support"
                className="transition hover:text-slate-400"
              >
                Support
              </Link>
            </div>
          </div>
        </footer>
      </main>
    </div>
  );
}

