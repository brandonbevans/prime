'use client';

import { supabase } from '@/lib/supabase';
import { useRouter } from 'next/navigation';
import { FormEvent, useState } from 'react';

const valueProps = [
  {
    title: "Elevate Your Self-Esteem",
    description:
      "Understand the science of self-worth and build the inner confidence every successful person relies on.",
  },
  {
    title: "Goal Setting, Simplified",
    description:
      "Translate inspiration into action with guided frameworks that turn long-term vision into daily momentum.",
  },
  {
    title: "Habits That Last",
    description:
      "Stay consistent with smart reminders, streak tracking, and the signature Golden Hour morning routine.",
  },
  {
    title: "Live Your True Vision",
    description:
      "Clarify what you really want from life and map a path you're excited to invest your time and energy into.",
  },
];

const experienceHighlights = [
  {
    title: "Daily Golden Hour Guidance",
    description:
      "Start each morning with reflection, focus, and curated action steps designed to keep you grounded and growing.",
  },
  {
    title: "Progress Intelligence",
    description:
      "See exactly where you're winning, what needs attention, and celebrate the milestones that keep motivation high.",
  },
  {
    title: "Purposeful Minimalism",
    description:
      "A calm interface built to reduce noise and spotlight what matters: your self-image, goals, and daily follow-through.",
  },
];

export default function Home() {
  const year = new Date().getFullYear();
  const router = useRouter();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);
    setIsSubmitting(true);

    const formData = new FormData(event.currentTarget);
    const email = formData.get('email') as string;

    try {
      const { error: insertError } = await supabase
        .from('waitlist_signups')
        .insert([{ email }]);

      if (insertError) {
        throw insertError;
      }

      router.push('/thank-you');
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : 'Something went wrong. Please try again.'
      );
      setIsSubmitting(false);
    }
  };

  return (
    <div className="relative min-h-screen overflow-hidden bg-slate-950 text-slate-100">
      <div className="absolute inset-0 -z-10 bg-[radial-gradient(circle_at_top,_rgba(212,175,55,0.14),transparent_55%),radial-gradient(circle_at_bottom,_rgba(30,64,175,0.28),transparent_60%)]" />
      <main className="mx-auto flex min-h-screen w-full max-w-6xl flex-col px-6 pb-20 pt-24 sm:px-10 lg:px-16">
        <header className="flex flex-col gap-14 lg:flex-row lg:items-center lg:justify-between">
          <div className="max-w-2xl space-y-8">
            <p className="text-sm font-semibold uppercase tracking-[0.35em] text-amber-300">
              WealthIQ Coming Soon
            </p>
            <h1 className="text-4xl font-semibold leading-tight tracking-tight sm:text-5xl md:text-6xl">
              Build the confidence, clarity, and habits that compound your
              success.
          </h1>
            <p className="text-lg leading-relaxed text-slate-300">
              WealthIQ is the personal development operating system for people
              who refuse to settle. Learn how self-esteem fuels performance,
              master goal setting, and build habits that keep you accountable to
              the future you deserve.
            </p>
            <form
              className="mt-8 w-full max-w-xl space-y-3"
              onSubmit={handleSubmit}
            >
              <label htmlFor="email" className="sr-only">
                Email address
              </label>
              <div className="flex flex-col gap-3 sm:flex-row">
                <input
                  id="email"
                  name="email"
                  type="email"
                  required
                  placeholder="you@email.com"
                  autoComplete="email"
                  className="w-full flex-1 rounded-full border border-white/20 bg-white/10 px-5 py-3 text-base text-slate-100 outline-none transition focus:border-amber-300 focus:ring-2 focus:ring-amber-300/40"
                />
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="inline-flex items-center justify-center rounded-full bg-amber-400 px-6 py-3 text-base font-semibold text-slate-950 transition hover:bg-amber-300 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber-200 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {isSubmitting ? 'Joining...' : 'Join the waitlist'}
                </button>
              </div>
              {error && (
                <p className="text-sm text-red-400">{error}</p>
              )}
              <p className="text-sm text-slate-400">
                Early supporters on the waitlist receive a complimentary 3-month
                WealthIQ subscription at launch.
              </p>
            </form>
          </div>
          <div className="flex w-full max-w-md flex-col gap-4 rounded-3xl border border-white/10 bg-white/5 p-8 shadow-[0_30px_80px_-30px_rgba(12,17,29,0.7)] sm:max-w-lg">
            <h2 className="text-lg font-semibold text-amber-200">
              Your journey starts here
            </h2>
            <p className="text-sm text-slate-300">
              WealthIQ helps you align who you are with who you want to become.
            </p>
            <ul className="space-y-4 text-sm leading-relaxed text-slate-200">
              <li className="flex gap-3">
                <span className="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-amber-400/20 text-sm font-semibold text-amber-200">
                  1
                </span>
                Learn why self-esteem is the foundation for every bold move you
                make.
              </li>
              <li className="flex gap-3">
                <span className="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-amber-400/20 text-sm font-semibold text-amber-200">
                  2
                </span>
                Set goals that feel meaningful, measurable, and aligned with
                your real ambitions.
              </li>
              <li className="flex gap-3">
                <span className="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-amber-400/20 text-sm font-semibold text-amber-200">
                  3
                </span>
                Build daily rituals and accountability loops that keep you in
                motion.
              </li>
              <li className="flex gap-3">
                <span className="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-amber-400/20 text-sm font-semibold text-amber-200">
                  4
                </span>
                Design the life you're willing to work for, and actually stay
                committed to it.
              </li>
            </ul>
          </div>
        </header>

        <section className="mt-24 space-y-10">
          <div className="max-w-2xl space-y-3">
            <p className="text-sm font-semibold uppercase tracking-[0.25em] text-amber-300">
              Why WealthIQ works
            </p>
            <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">
              Four pillars to build unstoppable momentum
            </h2>
            <p className="text-lg text-slate-300">
              Each pillar combines proven psychology with real-world coaching so
              you can grow faster, stay consistent, and enjoy the journey.
            </p>
          </div>
          <div className="grid gap-6 sm:grid-cols-2">
            {valueProps.map((prop) => (
              <article
                key={prop.title}
                className="rounded-3xl border border-white/10 bg-white/[0.06] p-8 transition hover:border-amber-300/50 hover:bg-white/[0.09]"
              >
                <h3 className="text-xl font-semibold text-slate-100">
                  {prop.title}
                </h3>
                <p className="mt-4 text-base leading-relaxed text-slate-300">
                  {prop.description}
                </p>
              </article>
            ))}
          </div>
        </section>

        <section className="mt-24 rounded-3xl border border-white/10 bg-gradient-to-br from-white/6 via-white/4 to-white/0 p-10 sm:p-14">
          <div className="max-w-2xl space-y-4">
            <h2 className="text-3xl font-semibold sm:text-4xl">
              Designed for the way high achievers really grow
            </h2>
            <p className="text-lg text-slate-300">
              WealthIQ blends mindful reflection with execution muscle. It's the
              toolkit for ambitious people who want their daily actions to match
              their deepest priorities.
            </p>
          </div>
          <div className="mt-10 grid gap-6 sm:grid-cols-3">
            {experienceHighlights.map((highlight) => (
              <article
                key={highlight.title}
                className="rounded-2xl border border-white/10 bg-slate-950/60 p-6"
              >
                <h3 className="text-lg font-semibold text-slate-100">
                  {highlight.title}
                </h3>
                <p className="mt-3 text-sm leading-relaxed text-slate-300">
                  {highlight.description}
                </p>
              </article>
            ))}
          </div>
          <div className="mt-10 flex flex-col gap-4 rounded-2xl border border-amber-300/40 bg-amber-400/10 p-6 text-amber-100 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.25em]">
                Bonus for early members
              </p>
              <p className="mt-2 text-lg text-amber-50">
                Join the waitlist today and lock in a free 3-month WealthIQ
                subscription when we launch.
              </p>
            </div>
            <a
              href="#"
              className="inline-flex items-center justify-center rounded-full border border-amber-200/60 bg-amber-200/20 px-5 py-3 text-sm font-semibold text-amber-50 transition hover:bg-amber-200/30 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber-100"
            >
              Reserve my spot
          </a>
        </div>
        </section>

        <footer className="mt-24 border-t border-white/10 pt-8 text-sm text-slate-500">
          <p>Copyright {year} WealthIQ. All rights reserved.</p>
        </footer>
      </main>
    </div>
  );
}
