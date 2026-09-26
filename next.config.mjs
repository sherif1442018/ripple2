/** @type {import('next').NextConfig} */
const isProd = process.env.NODE_ENV === 'production';

// CSP is intentionally strict. `unsafe-inline` on style-src is required because
// Three.js / React inline a small number of computed styles on canvas-adjacent
// elements at runtime; everything else stays locked down. No `unsafe-eval`.
const csp = [
  "default-src 'self'",
  "base-uri 'self'",
  "object-src 'none'",
  "frame-ancestors 'none'",
  "img-src 'self' data: blob:",
  "font-src 'self' data: https://fonts.gstatic.com https://fonts.googleapis.com",
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
  // Cloudflare Turnstile (CAPTCHA) is the one third-party script this site loads.
  "script-src 'self' https://challenges.cloudflare.com" + (isProd ? '' : " 'unsafe-eval' 'unsafe-inline'"),
  "frame-src https://challenges.cloudflare.com",
  "connect-src 'self' https://challenges.cloudflare.com" + (process.env.NEXT_PUBLIC_SITE_URL ? ` ${process.env.NEXT_PUBLIC_SITE_URL}` : ''),
  "worker-src 'self' blob:",
  "manifest-src 'self'",
  ...(isProd ? ['upgrade-insecure-requests'] : [])
].join('; ');

const securityHeaders = [
  { key: 'Content-Security-Policy', value: csp },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-DNS-Prefetch-Control', value: 'off' },
  { key: 'X-Permitted-Cross-Domain-Policies', value: 'none' },
  { key: 'Origin-Agent-Cluster', value: '?1' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()'
  },
  { key: 'Cross-Origin-Opener-Policy', value: 'same-origin' },
  { key: 'Cross-Origin-Resource-Policy', value: 'same-origin' },
  ...(isProd
    ? [{ key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' }]
    : [])
];

const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  devIndicators: false,
  images: {
    formats: ['image/avif', 'image/webp']
  },
  async headers() {
    return [{ source: '/:path*', headers: securityHeaders }];
  }
};

export default nextConfig;
