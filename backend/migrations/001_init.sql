-- 001_init.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================
-- Usuarios (OAuth Google)
-- ========================
CREATE TABLE IF NOT EXISTS usuarios (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT NOT NULL UNIQUE,
  nombre TEXT,
  google_id TEXT UNIQUE,
  institucion TEXT,
  grado TEXT,
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================
-- Planeaciones
-- ========================
CREATE TABLE IF NOT EXISTS planeaciones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('secuencial','proyecto')),
  grado TEXT,
  campo_formativo TEXT,
  contenido TEXT,           -- temaCentral → contenido
  sesiones INT,             -- numeroSesiones → sesiones
  duracion INT,             -- duracionSesion (minutos)
  tema TEXT,                -- opcional
  estado TEXT NOT NULL DEFAULT 'borrador', -- borrador|final
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_planeaciones_usuario ON planeaciones(usuario_id);
CREATE INDEX IF NOT EXISTS idx_planeaciones_tipo ON planeaciones(tipo);

-- =========================================
-- Secciones generadas por planeación (tabs)
-- planeacion | material_apoyo | rubrica | lista_cotejo
-- =========================================
CREATE TABLE IF NOT EXISTS plan_secciones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  planeacion_id UUID NOT NULL REFERENCES planeaciones(id) ON DELETE CASCADE,
  seccion TEXT NOT NULL CHECK (seccion IN ('planeacion','material_apoyo','rubrica','lista_cotejo')),
  version INT NOT NULL DEFAULT 1,
  contenido JSONB NOT NULL,           -- almacena texto estructurado/markdown/objetos
  es_editado_por_docente BOOLEAN NOT NULL DEFAULT FALSE,
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_plan_secciones_planeacion ON plan_secciones(planeacion_id);
CREATE INDEX IF NOT EXISTS idx_plan_secciones_seccion ON plan_secciones(seccion);

-- ========================
-- Catálogo: 9 Pilares
-- ========================
CREATE TABLE IF NOT EXISTS pilares (
  id SERIAL PRIMARY KEY,
  clave TEXT NOT NULL UNIQUE,  -- ej: rol, contexto, objetivo, formato, tono, audiencia, restricciones, instrucciones, criterios_exito
  nombre TEXT NOT NULL,
  descripcion TEXT
);

-- Valores de pilares por planeación
CREATE TABLE IF NOT EXISTS plan_pilares (
  planeacion_id UUID NOT NULL REFERENCES planeaciones(id) ON DELETE CASCADE,
  clave TEXT NOT NULL REFERENCES pilares(clave) ON UPDATE CASCADE,
  valor JSONB NOT NULL,            -- puede ser texto o estructura
  PRIMARY KEY (planeacion_id, clave)
);

CREATE INDEX IF NOT EXISTS idx_plan_pilares_planeacion ON plan_pilares(planeacion_id);

-- ========================
-- Plantilla 8.1 (versionada)
-- ========================
CREATE TABLE IF NOT EXISTS plantilla_versions (
  id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL DEFAULT 'Plantilla Maestra',
  version TEXT NOT NULL,                 -- '8.1'
  descripcion TEXT,
  activa BOOLEAN NOT NULL DEFAULT FALSE,
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_plantilla_nombre_version ON plantilla_versions(nombre, version);

-- Secciones de la plantilla (con orden y flags)
CREATE TABLE IF NOT EXISTS plantilla_secciones (
  id SERIAL PRIMARY KEY,
  plantilla_version_id INT NOT NULL REFERENCES plantilla_versions(id) ON DELETE CASCADE,
  clave TEXT NOT NULL,                   -- ej: instruccion_principal, instrucciones_ejecucion, formato_salida, etc.
  titulo TEXT NOT NULL,
  orden INT NOT NULL DEFAULT 0,
  habilitada BOOLEAN NOT NULL DEFAULT TRUE,
  instrucciones TEXT                     -- texto base de la sección
);

CREATE INDEX IF NOT EXISTS idx_secciones_plantilla ON plantilla_secciones(plantilla_version_id);

-- ========================
-- Contenidos base NEM
-- (Carga desde CON_PLAN.xlsx)
-- ========================
CREATE TABLE IF NOT EXISTS contenidos_base (
  id SERIAL PRIMARY KEY,
  grado TEXT NOT NULL,
  campo_formativo TEXT NOT NULL,
  contenido TEXT NOT NULL,
  bloque TEXT,               -- si aplica
  codigo TEXT,               -- si tu Excel tiene algún identificador
  metadata JSONB             -- por si hay columnas extras
);

CREATE INDEX IF NOT EXISTS idx_contenidos_base ON contenidos_base(grado, campo_formativo);

-- ========================
-- Semillas: 9 Pilares
-- ========================
INSERT INTO pilares (clave, nombre, descripcion) VALUES
  ('rol','Rol','Rol/Persona/Autoridad que adopta la IA'),
  ('contexto','Contexto','Marco situacional y restricciones suaves'),
  ('objetivo','Objetivo','Meta específica y medible del output'),
  ('formato','Formato','Estructura/plantilla del resultado'),
  ('tono','Tono','Estilo y voz del texto'),
  ('audiencia','Audiencia','Quién recibe/usa el resultado'),
  ('restricciones','Restricciones','Limitaciones duras y reglas'),
  ('instrucciones','Instrucciones','Pasos o guía operativa'),
  ('criterios_exito','Criterios de Éxito','Checklist de validación del output')
ON CONFLICT (clave) DO NOTHING;

-- ========================
-- Semillas: Plantilla 8.1 (solo cabecera y secciones típicas)
-- Nota: Ajusta 'instrucciones' con tu texto definitivo modificado para planeaciones.
-- ========================
INSERT INTO plantilla_versions (nombre, version, descripcion, activa)
VALUES ('Plantilla Maestra', '8.1', 'Versión segmentada y ajustada a planeaciones NEM', TRUE)
ON CONFLICT (nombre, version) DO NOTHING;

-- Obtiene id de la versión activa (8.1). Algunos motores no permiten variables; usar CTE:
WITH pv AS (
  SELECT id FROM plantilla_versions WHERE nombre='Plantilla Maestra' AND version='8.1' LIMIT 1
)
INSERT INTO plantilla_secciones (plantilla_version_id, clave, titulo, orden, habilitada, instrucciones)
SELECT pv.id, x.clave, x.titulo, x.orden, TRUE, x.instrucciones
FROM pv,
( VALUES
  ('instruccion_principal','🧠 Instrucción principal',10,'Actúa como un "Arquitecto de Planeaciones NEM". Genera un borrador profesional listo para editar. Sigue estrictamente la estructura y valida datos faltantes.'),
  ('instrucciones_ejecucion','🚫 Instrucciones de ejecución',20,'No reveles tu razonamiento oculto. No salgas del formato. Si faltan datos, pregunta con 3 opciones + campo libre.'),
  ('formato_salida','📦 Formato de salida',30,'Devuelve JSON con: plan, material_apoyo, rubrica, lista_cotejo. Incluye campos: objetivos, contenidos, actividades, evaluación, diferenciación, tiempos.'),
  ('criterios_exito','✅ Criterios de éxito',40,'Coherencia NEM, viabilidad en tiempo, evaluación alineada, diferenciación, claridad y accionabilidad.'),
  ('notas_politica','ℹ️ Notas y políticas',50,'Ajustar a NEM, respeto y seguridad; evitar contenidos sensibles; lenguaje inclusivo.')
) AS x(clave,titulo,orden,instrucciones)
ON CONFLICT DO NOTHING;
