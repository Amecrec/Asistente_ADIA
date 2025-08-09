-- Tipos
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'plan_tipo') THEN
        CREATE TYPE plan_tipo AS ENUM ('secuencial','proyecto');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'material_tipo') THEN
        CREATE TYPE material_tipo AS ENUM ('material_apoyo','rubrica','lista_cotejo');
    END IF;
END $$;

-- Usuarios (OAuth)
CREATE TABLE IF NOT EXISTS usuarios (
  id            BIGSERIAL PRIMARY KEY,
  email         TEXT UNIQUE NOT NULL,
  nombre        TEXT,
  google_id     TEXT UNIQUE,
  institucion   TEXT,
  grado_docente TEXT,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Contenidos base NEM (desde CON_PLAN.xlsx)
CREATE TABLE IF NOT EXISTS contenidos_base (
  id               BIGSERIAL PRIMARY KEY,
  grado            TEXT NOT NULL,
  campo_formativo  TEXT NOT NULL,
  contenido        TEXT NOT NULL,
  bloque           TEXT,
  UNIQUE (grado, campo_formativo, contenido, COALESCE(bloque, ''))
);

-- Catálogo de Pilares (9 pilares)
CREATE TABLE IF NOT EXISTS pilares_catalogo (
  id          SMALLSERIAL PRIMARY KEY,
  clave       TEXT UNIQUE NOT NULL,  -- ej: 'rol','contexto','objetivo','formato','tono','audiencia','restricciones','instrucciones','criterios_exito'
  nombre      TEXT NOT NULL,
  descripcion TEXT,
  orden       SMALLINT NOT NULL
);

-- Plantillas (v8.1 segmentada + futuras)
CREATE TABLE IF NOT EXISTS plantillas (
  id            BIGSERIAL PRIMARY KEY,
  nombre        TEXT NOT NULL,       -- ej: 'Plantilla Maestra v8.1'
  version       TEXT NOT NULL,       -- ej: '8.1'
  tipo          TEXT NOT NULL,       -- ej: 'planeacion'
  descripcion   TEXT,
  dsl_json      JSONB NOT NULL,      -- definición segmentada (bloques, flags, prioridades)
  activa        BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (nombre, version)
);

-- Bloques de plantilla (para indexar/ordenar y mapear flags)
CREATE TABLE IF NOT EXISTS plantilla_bloques (
  id            BIGSERIAL PRIMARY KEY,
  plantilla_id  BIGINT NOT NULL REFERENCES plantillas(id) ON DELETE CASCADE,
  bloque_clave  TEXT NOT NULL,       -- ej: 'instruccion_principal','rol','contexto', etc.
  bloque_nombre TEXT NOT NULL,
  orden         SMALLINT NOT NULL,
  requerido     BOOLEAN DEFAULT FALSE,
  flag_clave    TEXT,                -- ej: 'incluir_instruccion_principal'
  UNIQUE (plantilla_id, bloque_clave)
);

-- Planeaciones
CREATE TABLE IF NOT EXISTS planeaciones (
  id               BIGSERIAL PRIMARY KEY,
  usuario_id       BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  tipo             plan_tipo NOT NULL,             -- secuencial/proyecto
  grado            TEXT NOT NULL,
  campo_formativo  TEXT NOT NULL,
  contenido        TEXT NOT NULL,                  -- si es secuencial
  sesiones         INTEGER NOT NULL CHECK (sesiones > 0),
  duracion_min     INTEGER NOT NULL CHECK (duracion_min > 0),
  tema_opcional    TEXT,                           -- si aplica
  plantilla_id     BIGINT REFERENCES plantillas(id),
  modelo_ia        TEXT,                           -- proveedor/modelo usado
  estado           TEXT DEFAULT 'borrador',        -- borrador/finalizado
  created_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Valores de Pilares por planeación (snapshot)
CREATE TABLE IF NOT EXISTS plan_pilares_valor (
  id            BIGSERIAL PRIMARY KEY,
  plan_id       BIGINT NOT NULL REFERENCES planeaciones(id) ON DELETE CASCADE,
  pilar_id      SMALLINT NOT NULL REFERENCES pilares_catalogo(id),
  valor_texto   TEXT,     -- cuando sea simple
  valor_json    JSONB,    -- cuando sea estructurado
  UNIQUE (plan_id, pilar_id)
);

-- Texto generado por bloque de plantilla (snapshot)
CREATE TABLE IF NOT EXISTS plan_bloques_texto (
  id              BIGSERIAL PRIMARY KEY,
  plan_id         BIGINT NOT NULL REFERENCES planeaciones(id) ON DELETE CASCADE,
  bloque_clave    TEXT NOT NULL,                 -- debe corresponder a plantilla_bloques.bloque_clave
  contenido_md    TEXT NOT NULL,                 -- guardamos en Markdown (editable)
  tokens_entrada  INTEGER,
  tokens_salida   INTEGER,
  costo_estimado  NUMERIC(12,6),
  proveedor_modelo TEXT,
  created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (plan_id, bloque_clave)
);

-- Materiales generados (material de apoyo, rúbrica, lista de cotejo)
CREATE TABLE IF NOT EXISTS materiales (
  id              BIGSERIAL PRIMARY KEY,
  plan_id         BIGINT NOT NULL REFERENCES planeaciones(id) ON DELETE CASCADE,
  tipo            material_tipo NOT NULL,
  contenido_md    TEXT NOT NULL,      -- editable por el docente
  metadata_json   JSONB,              -- info adicional (formato export, rubrica dimensiones, etc.)
  created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_planeaciones_usuario ON planeaciones(usuario_id);
CREATE INDEX IF NOT EXISTS idx_planeaciones_tipo ON planeaciones(tipo);
CREATE INDEX IF NOT EXISTS idx_contenidos_base_lookup ON contenidos_base(grado, campo_formativo);
CREATE INDEX IF NOT EXISTS idx_plan_bloques_plan ON plan_bloques_texto(plan_id);
CREATE INDEX IF NOT EXISTS idx_materiales_plan ON materiales(plan_id);
