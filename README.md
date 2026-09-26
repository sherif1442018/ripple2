# Ripple — creative studio website

One idea. Endless impact.

A production Next.js site for Ripple: brand identity, digital design, creative
direction, and web development. Built on the App Router, TypeScript, a custom
Three.js (r186) ripple scene, and GSAP/ScrollTrigger motion.

## Tech stack

- **Next.js 16** (App Router, Server Components by default)
- **React 18** + **TypeScript** (strict mode)
- **three@0.186.0** — pinned; do not upgrade to a new major without re-testing
  the shader in `src/components/three/RippleScene.tsx`
- **GSAP 3** + ScrollTrigger for motion
- **Zod** for input validation
- Plain CSS (custom properties for the design system) — no CSS framework, to
  keep the dependency surface small

No database is used. The contact form and project builder deliver via email
(SMTP) when configured, or log server-side otherwise — see below.

## Getting started

```bash
npm install
cp .env.example .env.local   # then fill in real values
npm run dev
```

Visit http://localhost:3000.

## Scripts

```bash
npm run dev         # local dev server
npm run build       # production build
npm run start       # run the production build
npm run lint        # ESLint (flat config, eslint-config-next)
npm run typecheck   # tsc --noEmit
```

Before shipping any change, run all four and make sure they're clean —
CI should do the same.

## Environment variables

See `.env.example` for the full list with comments. Summary:

| Variable | Required | Notes |
|---|---|---|
| `NEXT_PUBLIC_SITE_URL` | yes | Used for canonical URLs, sitemap, OG tags, CSP `connect-src`. |
| `NEXT_PUBLIC_WHATSAPP_NUMBER` | yes | Full international format, digits only (see below). |
| `NEXT_PUBLIC_INSTAGRAM_HANDLE` | no | Defaults to `ripple___eg`. |
| `NEXT_PUBLIC_CAPTCHA_SITE_KEY` | yes (prod) | Cloudflare Turnstile site key — public by design. |
| `CAPTCHA_SECRET_KEY` | yes (prod) | Turnstile secret key — **never** expose this to the client. |
| `ALLOWED_ORIGINS` | yes (prod) | Comma-separated list of origins allowed to call the API cross-origin. |
| `SESSION_SECRET` | if you add auth later | Not used yet — reserved. |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASSWORD` / `CONTACT_INBOX_EMAIL` | no | If unset, inquiries are logged server-side instead of emailed. |
| `RATE_LIMIT_REDIS_URL` / `RATE_LIMIT_REDIS_TOKEN` | no | See "Rate limiting" below. |

Never prefix a secret with `NEXT_PUBLIC_` — that exposes it to every visitor's
browser. Only `NEXT_PUBLIC_CAPTCHA_SITE_KEY` (a site key, not a secret, by
Turnstile's own design) and the other genuinely public values above use that
prefix.

## CAPTCHA setup (Cloudflare Turnstile)

1. Create a site at https://dash.cloudflare.com/?to=/:account/turnstile.
2. Copy the **Site Key** into `NEXT_PUBLIC_CAPTCHA_SITE_KEY`.
3. Copy the **Secret Key** into `CAPTCHA_SECRET_KEY` (server-only).
4. The widget renders on the contact form and the project builder; both API
   routes (`/api/contact`, `/api/estimate`) verify the token server-side
   against `https://challenges.cloudflare.com/turnstile/v0/siteverify` before
   accepting anything. The client-side result is never trusted alone.

hCaptcha's `/siteverify` endpoint is wire-compatible if you prefer that
provider instead — swap the URL in `src/lib/captcha.ts`.

## Rate limiting

`src/lib/rateLimit.ts` ships a fixed-window in-memory limiter. It works
correctly for a single-process deployment but does **not** share state across
multiple server instances or edge regions. If you deploy to more than one
instance, replace it with a shared store (Upstash Redis is a good fit — the
env vars are already reserved) without changing any call sites.

## How to add a portfolio project

Open `src/lib/projects.ts` and append an object to the `projects` array:

```ts
{
  slug: 'my-project',
  title: 'My Project',
  category: 'Brand identity',
  year: 2026,
  client: 'Client name',
  description: 'One sentence.',
  services: ['Brand identity'],
  cover: '/work/my-project/cover.jpg',
  gallery: ['/work/my-project/1.jpg'],
  challenge: '...',
  approach: '...',
  result: '...',
  featured: true
}
```

Drop the matching images under `public/work/my-project/`. The `/work` index
and `/work/[slug]` detail page pick it up automatically — no other file needs
to change.

## How to edit services and pricing

Open `src/lib/services.ts`. `services` is the base service list and prices;
`websiteBuilderOptions` controls the page-count multipliers, animation-level
add-ons, and feature add-ons shown in the "Build your website" tool on the
Services page. **The server, not the browser, always has the final word**:
`calculateEstimate()` in that same file re-validates every id against this
list and recomputes the total — `/api/estimate` never trusts a client-supplied
price or total.

## How to change the WhatsApp number

Set `NEXT_PUBLIC_WHATSAPP_NUMBER` in your environment, in full international
format with no `+`, spaces, or leading zero — e.g. Egypt's `010 4294 4136`
becomes `201042944136` (country code `20` + the number with its leading `0`
dropped). `src/lib/whatsapp.ts` strips any non-digit characters defensively
either way.

## How to change Instagram

Set `NEXT_PUBLIC_INSTAGRAM_HANDLE` (no `@`).

## How to replace the logo / images

- Wordmark: it's set as text (`Ripple`, Georgia serif) in `Nav.tsx` and
  `LoadingScreen.tsx` rather than an image, so it stays crisp at any size and
  needs no asset. Swap in an SVG under `public/` and reference it there if
  you'd rather use a mark.
- Project images: see "How to add a portfolio project" above.
- Favicon / OG image: add `app/icon.png` and `app/opengraph-image.png` —
  Next.js's file-based metadata picks these up automatically.

## Security

- **Headers**: CSP, HSTS (prod only), `X-Content-Type-Options`,
  `X-Frame-Options`, `X-DNS-Prefetch-Control`, `Referrer-Policy`, `Permissions-Policy`,
  `Cross-Origin-Opener-Policy`, `Cross-Origin-Resource-Policy` — all set in
  `next.config.mjs`. CSP allows scripts only from `'self'` and Cloudflare
  Turnstile; no `unsafe-eval` in production.
- **CORS**: `src/lib/cors.ts` rejects non-allow-listed origins and only returns
  explicit origins from `ALLOWED_ORIGINS` — never a wildcard.
- **Request limits**: API bodies are bounded before parsing to reduce parser and
  memory abuse; error responses are generic and validated before returning.
- **Input validation**: every API route validates its body against a Zod
  schema (`src/lib/validation.ts`) before touching it.
- **Sanitization**: `src/lib/sanitize.ts` strips control characters and
  CRLF sequences from anything that could end up in an email header or log.
- **CAPTCHA**: verified server-side on every public form (see above).
- **Rate limiting**: enforced server-side on both API routes (see above).
- **No client-trusted pricing**: see "How to edit services and pricing".
- **Error handling**: `app/error.tsx` and every API route return generic
  messages; real errors are only ever `console.error`'d server-side.
- **Dependencies**: `npm audit` is clean as of this writing (three@0.186.0,
  next@16.3.5, nodemailer@10.0.10, eslint@9.x). Re-run `npm audit` after any
  dependency bump and fix what it finds before deploying.
- **Secrets**: `.env`, `.env.local`, and all local environment variants are
  ignored by Git. Never commit a real SMTP password or CAPTCHA secret.
- **Authentication**: this site currently has no login/authentication route and
  therefore no login database or SQL query surface. The shared rate limiter is
  ready for a future login endpoint; contact and estimate endpoints are already
  rate-limited.
- **HTTPS**: the application emits HSTS only in production. Deploy behind the
  provided `Caddyfile.example` (or Vercel/Cloudflare) to terminate TLS and
  obtain a real certificate; a certificate cannot be issued by source code alone.
- **Directory listing**: Next.js serves named public assets and routes, not
  directory indexes. No directory-listing handler is enabled.

### Before you deploy, run:

```bash
npm audit
npm run lint
npm run typecheck
npm run build
```

## HTTPS / SSL

This app does not and cannot generate a TLS certificate for you — that's a
property of your hosting/DNS setup, not application code. In production:

- **Vercel** (or similar): HTTPS is automatic once you attach your domain.
- **Self-hosted**: put the app behind a reverse proxy (Caddy, nginx, or
  Cloudflare) that terminates TLS — e.g. Caddy will provision and renew a
  Let's Encrypt certificate automatically for a domain pointed at it.
- Once TLS is live, `NODE_ENV=production` automatically adds the
  `Strict-Transport-Security` header (see `next.config.mjs`) — don't enable
  HSTS before HTTPS actually works, or you can lock visitors out.

## Production deployment (generic)

```bash
npm install
npm run build
npm run start   # or: run behind your process manager / reverse proxy of choice
```

Set every environment variable from `.env.example` in your hosting
platform's environment settings — never commit a real `.env` file (it's
git-ignored already; double-check with `git status` before your first push).

## Accessibility & motion

- Keyboard navigable throughout; the mobile menu traps focus and closes on
  Escape.
- `prefers-reduced-motion: reduce` is respected globally (see
  `globals.css`) and specifically by the 3D scene, loading screen, and
  scroll reveals.
- The 3D hero degrades to a static CSS gradient if WebGL is unavailable.

## Project structure

```
src/
  app/                 routes (App Router)
    api/contact/        contact form endpoint
    api/estimate/       server-authoritative pricing endpoint
    work/, work/[slug]/ portfolio index + detail template
    services/, about/, contact/
  components/
    three/              RippleScene (3D), HeroCanvas (client-only wrapper)
    ui/                 Nav, Footer, LoadingScreen, Reveal (GSAP), forms
  lib/                  data (projects, services), validation, security,
                         rate limiting, captcha, sanitize, whatsapp, CORS
```
