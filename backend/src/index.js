import express from 'express';
import cookieParser from 'cookie-parser';
import { env } from './config/env.js';
import { corsMiddleware } from './config/cors.js';
import { pool } from './config/db.js';
import { notFound, errorHandler } from './middlewares/errorHandler.js';

import authRoutes from './routes/authroutes.js';
import planeRoutes from './routes/planeroutes.js';
import materialRoutes from './routes/materialroutes.js';

const app = express();

// Middlewares
app.use(corsMiddleware);
app.use(express.json({ limit: '2mb' }));
app.use(cookieParser());

// Healthcheck
app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'asistente_adia-backend', env: env.NODE_ENV });
});

// Rutas
app.use('/auth', authRoutes);
app.use('/api', planeRoutes);
app.use('/api', materialRoutes);

// 404 y errores
app.use(notFound);
app.use(errorHandler);

// Arranque del servidor + prueba de conexión a DB
app.listen(env.PORT, async () => {
  try {
    await pool.query('SELECT 1');
    console.log(`[OK] DB conectada. Backend escuchando en :${env.PORT}`);
  } catch (e) {
    console.error('[ERROR] No se pudo conectar a la DB:', e.message);
  }
});
