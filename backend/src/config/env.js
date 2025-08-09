import dotenv from 'dotenv';
dotenv.config();

export const env = {
  NODE_ENV: process.env.NODE_ENV ?? 'development',
  PORT: Number(process.env.PORT ?? 3001),
  FRONTEND_URLS: (process.env.FRONTEND_URLS ?? 'http://localhost:5173')
    .split(',')
    .map(s => s.trim())
    .filter(Boolean),
  DATABASE_URL: process.env.DATABASE_URL
};

if (!env.DATABASE_URL) {
  console.warn('[WARN] DATABASE_URL no está definida. Configúrala en Render o .env');
}
