-- MUNICIPIOS
-- Se observaron múltiples caracteres en las columnas de Municipio y Departamento, por lo que se usa REPLACE y TRIM para facilitar posteriormente el uso de los datos para su visualización.
UPDATE Municipios
SET 
	Municipio = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Municipio, '>', ''), '&', ''), '!', ''), '#', ''), '?', ''), '*', ''), '''', '')),
    Departamento = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Departamento, '>', ''), '&', ''), '!', ''), '#', ''), '?', ''), '*', ''), '''', '')),
	Superficie = ROUND(Superficie, 4);
	
	
SELECT DISTINCT Departamento FROM Municipios