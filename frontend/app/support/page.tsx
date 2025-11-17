import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Support Center | WealthIQ",
  description:
    "Get help with WealthIQ. Find answers to frequently asked questions or contact our support team.",
};

const faqs = [
  {
    question: "How do I access my WealthIQ subscription?",
    answer:
      "Once WealthIQ launches, you'll receive an email with your access code and instructions to redeem your complimentary 3-month subscription. Simply follow the instructions in the email to get started.",
  },
  {
    question: "What is the Golden Hour routine?",
    answer:
      "The Golden Hour is WealthIQ's signature morning routine that combines reflection, goal alignment, and intentional action planning. It's designed to help you start each day with clarity and purpose.",
  },
  {
    question: "Can I cancel my subscription anytime?",
    answer:
      "Yes, you can cancel your subscription at any time through your device's subscription settings. Your access will continue until the end of your current billing period.",
  },
  {
    question: "What happens after my free 3-month subscription ends?",
    answer:
      "After your complimentary 3-month subscription expires, you can choose to continue with a paid subscription to maintain access to all WealthIQ features, or cancel anytime with no obligation.",
  },
  {
    question: "Is my data secure and private?",
    answer:
      "Absolutely. We take your privacy seriously. All personal data is encrypted and stored securely. You can read our full Privacy Policy for detailed information about how we handle your data.",
  },
  {
    question: "How do I reset my password or account?",
    answer:
      "Once the app launches, you'll be able to manage your account settings directly within WealthIQ. For account-related issues, please contact our support team using the form below.",
  },
];

const contactMethods = [
  {
    title: "Email Support",
    description: "Get help via email",
    action: "Send us an email",
    href: "mailto:support@wealthiq.app",
  },
  {
    title: "In-App Support",
    description: "Access help directly in the app",
    action: "Open in app",
    href: "#",
  },
];

export default function Support() {
  const year = new Date().getFullYear();

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
            Support Center
          </h1>
          <p className="mt-4 text-lg leading-relaxed text-slate-300">
            We&apos;re here to help you get the most out of WealthIQ. Find answers to
            common questions or reach out to our support team.
          </p>
        </header>

        <section className="space-y-8">
          <div>
            <h2 className="text-2xl font-semibold tracking-tight">
              Frequently Asked Questions
            </h2>
            <p className="mt-2 text-slate-400">
              Quick answers to the most common questions about WealthIQ.
            </p>
          </div>
          <div className="space-y-4">
            {faqs.map((faq, index) => (
              <details
                key={index}
                className="group rounded-2xl border border-white/10 bg-white/[0.06] p-6 transition hover:border-amber-300/50 hover:bg-white/[0.09]"
              >
                <summary className="cursor-pointer text-lg font-semibold text-slate-100 transition group-open:text-amber-200">
                  {faq.question}
                </summary>
                <p className="mt-4 text-base leading-relaxed text-slate-300">
                  {faq.answer}
                </p>
              </details>
            ))}
          </div>
        </section>

        <section className="mt-16 space-y-8">
          <div>
            <h2 className="text-2xl font-semibold tracking-tight">
              Contact Support
            </h2>
            <p className="mt-2 text-slate-400">
              Need more help? Reach out to our support team and we&apos;ll get back to
              you as soon as possible.
            </p>
          </div>
          <div className="grid gap-6 sm:grid-cols-2">
            {contactMethods.map((method, index) => (
              <div
                key={index}
                className="rounded-2xl border border-white/10 bg-white/[0.06] p-6 transition hover:border-amber-300/50 hover:bg-white/[0.09]"
              >
                <h3 className="text-lg font-semibold text-slate-100">
                  {method.title}
                </h3>
                <p className="mt-2 text-sm text-slate-300">
                  {method.description}
                </p>
                <a
                  href={method.href}
                  className="mt-4 inline-flex items-center text-sm font-semibold text-amber-300 transition hover:text-amber-200"
                >
                  {method.action} →
                </a>
              </div>
            ))}
          </div>
        </section>

        <section className="mt-16 rounded-3xl border border-amber-300/40 bg-amber-400/10 p-8 text-amber-50">
          <h2 className="text-xl font-semibold">Still have questions?</h2>
          <p className="mt-2 text-base text-amber-100">
            Our support team is available to help you with any questions or
            concerns. We typically respond within 24-48 hours.
          </p>
          <a
            href="mailto:support@wealthiq.app?subject=Support%20Request"
            className="mt-6 inline-flex items-center justify-center rounded-full border border-amber-200/60 bg-amber-200/20 px-6 py-3 text-sm font-semibold text-amber-50 transition hover:bg-amber-200/30 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber-100"
          >
            Contact Support
          </a>
        </section>

        <footer className="mt-24 border-t border-white/10 pt-8 text-sm text-slate-500">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <p>Copyright {year} WealthIQ. All rights reserved.</p>
            <div className="flex gap-6">
              <Link
                href="/privacy"
                className="transition hover:text-slate-400"
              >
                Privacy Policy
              </Link>
            </div>
          </div>
        </footer>
      </main>
    </div>
  );
}

