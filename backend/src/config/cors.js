import cors from 'cors';
import { env } from './env.js';

export const corsMiddleware = cors({
  origin(origin, callback) {
    // permitir same-origin (como Postman) o lista blanca
    if (!origin || env.FRONTEND_URLS.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error(`CORS bloqueado para origen: ${origin}`));
  },
  credentials: true
});
