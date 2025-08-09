import { Router } from 'express';

const router = Router();

/**
 * Placeholder: cuando integremos Google OAuth,
 * aquí estarán /auth/google y /auth/google/callback.
 */

// Estado de sesión simple
router.get('/me', (req, res) => {
  // Si más adelante usamos JWT, aquí decodificamos el token.
  res.json({ user: req.user ?? null });
});

export default router;
