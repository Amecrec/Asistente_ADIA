import { Router } from 'express';
import { pool } from '../config/db.js';
import { requireAuth } from '../middlewares/requireAuth.js';

const router = Router();

// Listar materiales (tabs) por usuario
router.get('/materials', requireAuth, async (req, res, next) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'No autorizado' });

    const sql = `
      SELECT ps.id, ps.planeacion_id, ps.seccion, ps.version, ps.contenido, p.creado_en
      FROM plan_secciones ps
      JOIN planeaciones p ON p.id = ps.planeacion_id
      WHERE p.usuario_id = $1
      ORDER BY p.creado_en DESC
      LIMIT 200
    `;
    const { rows } = await pool.query(sql, [userId]);
    res.json(rows);
  } catch (err) {
    next(err);
  }
});

// Eliminar material por id
router.delete('/materials/:id', requireAuth, async (req, res, next) => {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM plan_secciones WHERE id = $1', [id]);
    res.status(204).end();
  } catch (err) {
    next(err);
  }
});

export default router;
