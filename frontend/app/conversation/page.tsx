'use client';

import { supabase } from '@/lib/supabase';
import { Session } from '@supabase/supabase-js';
import clsx from 'clsx';
import { FormEvent, useCallback, useEffect, useRef, useState } from 'react';

type ElevenLabsEvent =
  | { type: 'ping'; ping_event: { event_id: number | string } }
  | { type: 'agent_response'; agent_response_event: { agent_response: string } }
  | { type: 'audio'; audio_event: { audio_base_64: string } }
  | { type: 'user_transcript'; user_transcription_event: { user_transcript: string } }
  | { type: 'conversation_initiation_metadata' }
  | { type: 'interruption'; interruption_event: { reason?: string } }
  | Record<string, unknown>;

type ConnectionStatus = 'idle' | 'connecting' | 'connected' | 'error';

const API_BASE = process.env.NEXT_PUBLIC_CONVERSATION_API_URL ?? 'http://localhost:8000';

const ConversationPage = () => {
  const [session, setSession] = useState<Session | null>(null);
  const [status, setStatus] = useState<ConnectionStatus>('idle');
  const [error, setError] = useState<string | null>(null);
  const [logs, setLogs] = useState<string[]>([]);
  const websocketRef = useRef<WebSocket | null>(null);
  const audioCtxRef = useRef<AudioContext | null>(null);
  const audioQueueRef = useRef<Promise<void>>(Promise.resolve());

  useEffect(() => {
    let mounted = true;
    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return;
      setSession(data.session ?? null);
    });
    const { data: listener } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession);
    });
    return () => {
      mounted = false;
      listener.subscription.unsubscribe();
    };
  }, []);

  const appendLog = useCallback((message: string) => {
    setLogs((prev) => [message, ...prev].slice(0, 40));
  }, []);

  const playAudio = useCallback(async (base64: string) => {
    if (!audioCtxRef.current) {
      audioCtxRef.current = new AudioContext();
    }
    const ctx = audioCtxRef.current;
    if (ctx.state === 'suspended') {
      await ctx.resume();
    }
    const buffer = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0)).buffer;
    const audioBuffer = await ctx.decodeAudioData(buffer.slice(0));
    await new Promise<void>((resolve) => {
      const source = ctx.createBufferSource();
      source.buffer = audioBuffer;
      source.connect(ctx.destination);
      source.onended = () => resolve();
      source.start();
    });
  }, []);

  const enqueueAudio = useCallback(
    (base64: string) => {
      audioQueueRef.current = audioQueueRef.current
        .catch((err) => {
          console.error('Audio queue error', err);
        })
        .then(() => playAudio(base64));
    },
    [playAudio]
  );

  const closeConversation = useCallback(() => {
    websocketRef.current?.close();
    websocketRef.current = null;
    audioQueueRef.current = Promise.resolve();
    setStatus('idle');
  }, []);

  useEffect(() => () => closeConversation(), [closeConversation]);

  const ensureSession = useCallback(async () => {
    const { data } = await supabase.auth.getSession();
    if (!data.session) {
      throw new Error('You must sign in before starting a conversation');
    }
    return data.session;
  }, []);

  const handleMessage = useCallback(
    (event: MessageEvent) => {
      try {
        const message: ElevenLabsEvent = JSON.parse(event.data);
        if (message.type === 'ping' && 'ping_event' in message) {
          websocketRef.current?.send(
            JSON.stringify({
              type: 'pong',
              pong_event: { event_id: message.ping_event.event_id },
            })
          );
          return;
        }
        if (message.type === 'agent_response' && 'agent_response_event' in message) {
          appendLog(`Agent: ${message.agent_response_event.agent_response}`);
        }
        if (message.type === 'user_transcript' && 'user_transcription_event' in message) {
          appendLog(`You: ${message.user_transcription_event.user_transcript}`);
        }
        if (message.type === 'audio' && 'audio_event' in message) {
          enqueueAudio(message.audio_event.audio_base_64);
        }
      } catch (err) {
        console.error('Failed to parse event', err);
      }
    },
    [appendLog, enqueueAudio]
  );

  const startConversation = useCallback(async () => {
    try {
      setStatus('connecting');
      setError(null);
      const activeSession = await ensureSession();
      const response = await fetch(`${API_BASE}/api/conversation/session`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${activeSession.access_token}`,
        },
      });

      if (!response.ok) {
        const body = await response.json().catch(() => ({}));
        throw new Error(body.detail ?? 'Unable to start conversation');
      }

      const payload = await response.json();
      const ws = new WebSocket(payload.ws_url as string);
      websocketRef.current = ws;

      ws.onopen = () => {
        setStatus('connected');
        appendLog('Connected to conversation service');
      };
      ws.onerror = (event) => {
        console.error(event);
        setStatus('error');
        setError('WebSocket error');
      };
      ws.onclose = () => {
          setStatus('idle');
      };
      ws.onmessage = handleMessage;
    } catch (err) {
      console.error(err);
      setStatus('error');
      setError(err instanceof Error ? err.message : 'Failed to start conversation');
    }
  }, [appendLog, ensureSession, handleMessage]);

  if (!session) {
    return (
      <main className="mx-auto flex min-h-screen max-w-4xl flex-col items-center justify-center px-6 py-16 text-slate-100">
        <AuthCard />
      </main>
    );
  }

  return (
    <main className="mx-auto flex min-h-screen max-w-5xl flex-col gap-8 px-6 py-14 text-slate-100">
      <header className="space-y-2">
        <p className="text-sm uppercase tracking-[0.3em] text-amber-300">Beta Feature</p>
        <h1 className="text-4xl font-semibold">Voice Conversation Debugger</h1>
        <p className="text-slate-300">
          Start a private conversation session routed through the FastAPI conversation service. For now, the agent will
          greet you with your onboarding details from Supabase.
        </p>
        <div className="flex flex-wrap items-center gap-3 text-sm text-slate-400">
          <span>Signed in as {session.user.email}</span>
          <button
            onClick={() => supabase.auth.signOut()}
            className="rounded-full border border-white/20 px-4 py-1 text-xs uppercase tracking-[0.3em] transition hover:border-white/60"
          >
            Sign out
          </button>
        </div>
      </header>

      <section className="rounded-3xl border border-white/10 bg-white/[0.04] p-6">
        <div className="flex flex-wrap items-center gap-4">
          <StatusBadge status={status} />
          {error && <p className="text-sm text-red-400">{error}</p>}
        </div>
        <div className="mt-6 flex flex-wrap gap-4">
          <button
            onClick={startConversation}
            disabled={status === 'connecting' || status === 'connected'}
            className={clsx(
              'rounded-full px-6 py-3 text-sm font-semibold transition',
              status === 'connected'
                ? 'bg-green-500 text-slate-950 opacity-80'
                : 'bg-amber-400 text-slate-950 hover:bg-amber-300'
            )}
          >
            {status === 'connecting' ? 'Connecting…' : status === 'connected' ? 'Conversation Live' : 'Start Conversation'}
          </button>
          <button
            onClick={closeConversation}
            disabled={status !== 'connected'}
            className="rounded-full border border-white/20 px-6 py-3 text-sm text-white/80 transition hover:border-white/40"
          >
            Stop
          </button>
        </div>
      </section>

      <section className="grid gap-6 md:grid-cols-2">
        <div className="rounded-3xl border border-white/10 bg-white/[0.03] p-5">
          <h2 className="text-lg font-semibold">Recent Messages</h2>
          <div className="mt-4 h-64 overflow-y-auto space-y-3 text-sm text-slate-300">
            {logs.length === 0 && <p className="text-slate-500">No conversation yet.</p>}
            {logs.map((entry, index) => (
              <p key={`${entry}-${index}`} className="rounded-xl bg-white/[0.02] px-3 py-2">
                {entry}
              </p>
            ))}
          </div>
        </div>
        <div className="rounded-3xl border border-white/10 bg-white/[0.03] p-5 text-sm text-slate-300">
          <h2 className="text-lg font-semibold text-white">How it works</h2>
          <ol className="mt-4 space-y-3 list-decimal list-inside">
            <li>Authenticate with Supabase to provide the access token.</li>
            <li>Start a session to get a signed WebSocket URL from the FastAPI server.</li>
            <li>The server greets you via ElevenLabs using your onboarding profile.</li>
          </ol>
        </div>
      </section>
    </main>
  );
};

const StatusBadge = ({ status }: { status: ConnectionStatus }) => {
  const colors: Record<ConnectionStatus, string> = {
    idle: 'bg-white/10 text-slate-200',
    connecting: 'bg-amber-400/30 text-amber-200',
    connected: 'bg-green-500/20 text-green-300',
    error: 'bg-red-500/20 text-red-300',
  };

  const copy: Record<ConnectionStatus, string> = {
    idle: 'Idle',
    connecting: 'Connecting…',
    connected: 'Connected',
    error: 'Error',
  };

  return <span className={clsx('rounded-full px-4 py-1 text-sm font-medium', colors[status])}>{copy[status]}</span>;
};

const AuthCard = () => {
  const [formState, setFormState] = useState<'idle' | 'signing-in'>('idle');
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);
    setFormState('signing-in');
    const formData = new FormData(event.currentTarget);
    const email = formData.get('email') as string;
    const password = formData.get('password') as string;
    const { error: authError } = await supabase.auth.signInWithPassword({ email, password });
    if (authError) {
      setError(authError.message);
      setFormState('idle');
      return;
    }
    setFormState('idle');
  };

  return (
    <div className="w-full max-w-md rounded-3xl border border-white/10 bg-white/[0.04] p-8">
      <h1 className="text-3xl font-semibold text-white">Sign in to continue</h1>
      <p className="mt-2 text-sm text-slate-400">
        Use a Supabase user that already has onboarding data in `user_profiles`.
      </p>
      <form className="mt-6 space-y-4" onSubmit={handleSubmit}>
        <div>
          <label htmlFor="email" className="text-xs uppercase tracking-[0.3em] text-slate-400">
            Email
          </label>
          <input
            id="email"
            name="email"
            type="email"
            required
            className="mt-2 w-full rounded-2xl border border-white/20 bg-white/5 px-4 py-2 text-base text-white outline-none focus:border-amber-300"
          />
        </div>
        <div>
          <label htmlFor="password" className="text-xs uppercase tracking-[0.3em] text-slate-400">
            Password
          </label>
          <input
            id="password"
            name="password"
            type="password"
            required
            className="mt-2 w-full rounded-2xl border border-white/20 bg-white/5 px-4 py-2 text-base text-white outline-none focus:border-amber-300"
          />
        </div>
        {error && <p className="text-sm text-red-400">{error}</p>}
        <button
          type="submit"
          disabled={formState === 'signing-in'}
          className="w-full rounded-full bg-amber-400 py-3 text-sm font-semibold text-slate-950 transition hover:bg-amber-300 disabled:opacity-60"
        >
          {formState === 'signing-in' ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
    </div>
  );
};

export default ConversationPage;
