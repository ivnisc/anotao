-- Este archivo es solo para referencia y documentación
-- Ejecuta estas consultas en la interfaz SQL de Supabase para actualizar tu esquema

-- Actualizar la tabla notes para incluir el campo rut_id
ALTER TABLE notes ADD COLUMN IF NOT EXISTS rut_id TEXT;

-- Crear un índice para mejorar las búsquedas por rut_id y slug
CREATE INDEX IF NOT EXISTS idx_notes_rut_slug ON notes(rut_id, slug);

-- Ejemplo de la estructura completa de la tabla (para referencia)
-- CREATE TABLE notes (
--   id SERIAL PRIMARY KEY,
--   title TEXT NOT NULL DEFAULT 'Sin título',
--   content TEXT,
--   slug TEXT NOT NULL,
--   rut_id TEXT,
--   created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
--   updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
--   UNIQUE(rut_id, slug)
-- );

-- Función para actualizar automáticamente el campo updated_at
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que llama a la función anterior
DROP TRIGGER IF EXISTS set_timestamp ON notes;
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON notes
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp(); 