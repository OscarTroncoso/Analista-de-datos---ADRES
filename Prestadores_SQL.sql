-- PRESTADORES 
-- Actualiza la primera letra de cada palabra a mayúscula y el resto a minúsculas para las columnas especificadas
UPDATE Prestadores
SET 
    muni_nombre = UPPER(SUBSTR(muni_nombre, 1, 1)) || LOWER(SUBSTR(muni_nombre, 2)),
    nombre_prestador = UPPER(SUBSTR(nombre_prestador, 1, 1)) || LOWER(SUBSTR(nombre_prestador, 2)),
    clase_persona = UPPER(SUBSTR(clase_persona, 1, 1)) || LOWER(SUBSTR(clase_persona, 2)),
    rep_legal = UPPER(SUBSTR(rep_legal, 1, 1)) || LOWER(SUBSTR(rep_legal, 2)),
    razon_social = UPPER(SUBSTR(razon_social, 1, 1)) || LOWER(SUBSTR(razon_social, 2)),
    email = UPPER(SUBSTR(email, 1, 1)) || LOWER(SUBSTR(email, 2)),
    direccion = UPPER(SUBSTR(direccion, 1, 1)) || LOWER(SUBSTR(direccion, 2)),
	-- Convierte las fechas a formato MM/DD/YYYY si tienen una longitud de 8 caracteres
    fecha_radicacion = CASE WHEN LENGTH(fecha_radicacion) = 8 THEN 
        SUBSTR(fecha_radicacion, 5, 2) || '/' || 
        SUBSTR(fecha_radicacion, 7, 2) || '/' || 
        SUBSTR(fecha_radicacion, 1, 4) 
    ELSE fecha_radicacion END,
    fecha_vencimiento = CASE WHEN LENGTH(fecha_vencimiento) = 8 THEN 
        SUBSTR(fecha_vencimiento, 5, 2) || '/' || 
        SUBSTR(fecha_vencimiento, 7, 2) || '/' || 
        SUBSTR(fecha_vencimiento, 1, 4)
    ELSE fecha_vencimiento END;

-- Agrega nuevas columnas para almacenar la fecha, la hora y el periodo del reporte REPS
ALTER TABLE Prestadores
ADD fecha_REPS TEXT;

ALTER TABLE Prestadores
ADD hora_REPS TEXT;

ALTER TABLE Prestadores
ADD periodo_REPS TEXT;

-- Actualiza las nuevas columnas con los datos extraídos de la columna fecha_corte_REPS
UPDATE Prestadores
SET 
    fecha_REPS = SUBSTR(fecha_corte_REPS, 19, 3) || '/' || SUBSTR(fecha_corte_REPS, 23, 2) || '/' || SUBSTR(fecha_corte_REPS, 26, 4),
    hora_REPS = SUBSTR(fecha_corte_REPS, 31, 4),
    periodo_REPS = SUBSTR(fecha_corte_REPS, 35, 2)
WHERE fecha_corte_REPS LIKE 'Fecha corte REPS:%';

-- Crea una nueva tabla sin tido_codigo que no tiene información ni fecha_corte_REPS que fue transaformada anteriormente y transfiere los datos existentes
CREATE TABLE New_Prestadores AS 
SELECT 
    depa_nombre,
    muni_nombre,
    codigo_habilitacion,
    nombre_prestador,
    nits_nit,
    razon_social,
    clpr_codigo,
    clpr_nombre,
    ese,
    direccion,
    telefono,
    fax,
    email,
    nivel,
    caracter,
    habilitado,
    fecha_radicacion,
    fecha_vencimiento,
    dv,
    clase_persona,
    naju_codigo,
    naju_nombre,
    numero_sede_principal,
    fecha_REPS,
    hora_REPS,
    periodo_REPS,
    telefono_adicional,
    email_adicional,
    rep_legal
FROM Prestadores;

DROP TABLE Prestadores;
ALTER TABLE New_Prestadores RENAME TO Prestadores;