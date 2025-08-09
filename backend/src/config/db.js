import { Pool } from 'pg';
import { env } from './env.js';

export const pool = new Pool({
  connectionString: env.DATABASE_URL,
  ssl: env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// helper
export const query = (text, params) => pool.query(text, params);
