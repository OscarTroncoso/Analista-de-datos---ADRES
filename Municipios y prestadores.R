# Llamado de librerias -----
library(RSQLite)
library(readr)
library(tidyverse)
library(tseries)
library(ggplot2)
library(gridExtra)
library(dplyr)
library(lmtest)
library(car)
library(DBI)
library(sandwich)

# Base de datos en SQLite -----
Municipios_raw <- read_csv("C:/Users/oscar/Downloads/Prueba técnica - Adres/Municipios_raw.csv")
Prestadores_raw <- read_csv("C:/Users/oscar/Downloads/Prueba técnica - Adres/Prestadores_raw.csv")

# Base de datos SQLite3 -----
# Conexión a la base de datos

DB = dbConnect(RSQLite::SQLite(), "Municipios y prestadores.sqlite")

# Cargar las tablas de datos a la base de datos
dbWriteTable(DB, "Municipios", Municipios_raw)
dbWriteTable(DB, "Prestadores", Prestadores_raw)

# Query de Municipios -----
dbExecute(DB, "
UPDATE Municipios
SET 
    Municipio = UPPER(SUBSTR(TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Municipio, '>', ''), '&', ''), '!', ''), '#', ''), '?', ''), '*', ''), '''', ''), '%', '')), 1, 1)) || LOWER(SUBSTR(TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Municipio, '>', ''), '&', ''), '!', ''), '#', ''), '?', ''), '*', ''), '''', ''), '%', '')), 2)),
    Departamento = UPPER(SUBSTR(TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Departamento, '>', ''), '&', ''), '!', ''), '#', ''), '?', ''), '*', ''), '''', ''), '%', '')), 1, 1)) || LOWER(SUBSTR(TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Departamento, '>', ''), '&', ''), '!', ''), '#', ''), '?', ''), '*', ''), '''', ''), '%', '')), 2)),
    Superficie = ROUND(Superficie, 4)
")

# Query de Prestadores -----
## Actualiza las columnas a capitalización adecuada
dbExecute(DB, "
UPDATE Prestadores
SET 
    muni_nombre = UPPER(SUBSTR(muni_nombre, 1, 1)) || LOWER(SUBSTR(muni_nombre, 2)),
    nombre_prestador = UPPER(SUBSTR(nombre_prestador, 1, 1)) || LOWER(SUBSTR(nombre_prestador, 2)),
    clase_persona = UPPER(SUBSTR(clase_persona, 1, 1)) || LOWER(SUBSTR(clase_persona, 2)),
    rep_legal = UPPER(SUBSTR(rep_legal, 1, 1)) || LOWER(SUBSTR(rep_legal, 2)),
    razon_social = UPPER(SUBSTR(razon_social, 1, 1)) || LOWER(SUBSTR(razon_social, 2)),
    email = UPPER(SUBSTR(email, 1, 1)) || LOWER(SUBSTR(email, 2)),
    direccion = UPPER(SUBSTR(direccion, 1, 1)) || LOWER(SUBSTR(direccion, 2)),
    fecha_radicacion = CASE WHEN LENGTH(fecha_radicacion) = 8 THEN 
        SUBSTR(fecha_radicacion, 5, 2) || '/' || 
        SUBSTR(fecha_radicacion, 7, 2) || '/' || 
        SUBSTR(fecha_radicacion, 1, 4) 
    ELSE fecha_radicacion END,
    fecha_vencimiento = CASE WHEN LENGTH(fecha_vencimiento) = 8 THEN 
        SUBSTR(fecha_vencimiento, 5, 2) || '/' || 
        SUBSTR(fecha_vencimiento, 7, 2) || '/' || 
        SUBSTR(fecha_vencimiento, 1, 4)
    ELSE fecha_vencimiento END
")

## Agrega nuevas columnas
dbExecute(DB, "ALTER TABLE Prestadores ADD fecha_REPS TEXT")
dbExecute(DB, "ALTER TABLE Prestadores ADD hora_REPS TEXT")
dbExecute(DB, "ALTER TABLE Prestadores ADD periodo_REPS TEXT")

# Actualiza las nuevas columnas DB los datos extraídos
dbExecute(DB, "
UPDATE Prestadores
SET 
    fecha_REPS = SUBSTR(fecha_corte_REPS, 19, 3) || '/' || SUBSTR(fecha_corte_REPS, 23, 2) || '/' || SUBSTR(fecha_corte_REPS, 26, 4),
    hora_REPS = SUBSTR(fecha_corte_REPS, 31, 4),
    periodo_REPS = SUBSTR(fecha_corte_REPS, 35, 2)
WHERE fecha_corte_REPS LIKE 'Fecha corte REPS:%'
")

## Crea una nueva tabla y transfiere los datos
dbExecute(DB, "
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
FROM Prestadores
")

## Elimina la tabla original y renombra la nueva
dbExecute(DB, "DROP TABLE Prestadores")
dbExecute(DB, "ALTER TABLE New_Prestadores RENAME TO Prestadores")

# Importación de datos -----
Municipios = dbReadTable(DB, "Municipios")
Prestadores = dbReadTable(DB, "Prestadores")
Merge_db = merge(Prestadores, Municipios, 
                 by.x = 'muni_nombre', by.y = 'Municipio') 

# Proceso -----
# Análisis descriptivo
Des_stat_Municipios = summary(Municipios)
Des_stat_Prestadores = summary(Prestadores)

# Visualización de datos
## Municipios
### Población
Pob_Pobmun = ggplot(Municipios, aes(x=Poblacion)) +
  geom_histogram(binwidth = 5000) +  
  theme_minimal() +
  xlim(c(0, 300000)) +
  labs(title = 'Distribución de la población en municipios', x = 'Población', 
       y = 'Frecuencia')


### Índice de ruralidad
Rur_Cant = ggplot(Municipios, aes(x=Irural)) +
  geom_histogram(binwidth = 2) +
  theme_minimal() +
  labs(title = 'Distribución del índice de ruralidad', 
       x = 'Índice de ruralidad', y = 'Cantidad')


### Superficie
Sup_Freq = ggplot(Municipios, aes(x=Superficie)) +
  geom_histogram(binwidth = 100) +
  theme_minimal() +
  xlim(c(0, 10000)) +
  labs(title = 'Distribución de la superficie de municipios', 
       x = 'Superficie', y = 'Frecuencia')


## Prestadores
### Clasificación del prestador
Clas_Cant_Prov = ggplot(Prestadores, aes(x = clpr_nombre)) +
  geom_bar() +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 20)) +
  theme_minimal() +
  theme(axis.text.x = element_text(hjust = 1, vjust = 1)) +
  labs(title = 'Cantidad de prestadores por clasificación', 
       x = 'Clasificación del prestador', y = 'Cantidad')

### Ubicación geográfica
Dept_Cant = ggplot(Prestadores, aes(x = depa_nombre)) +
  geom_bar() +
  theme_minimal() +
  labs(title = 'Cantidad de prestadores por departamento', 
       x = 'Departamento', y = 'Cantidad') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

### Entidad económica solidaria (ese)
ese_data = table(Prestadores$ese)
ese_df = as.data.frame(ese_data)

Ese_graph = ggplot(ese_df, aes(x = '', y = Freq, fill = Var1)) +
  geom_bar(width = 1, stat = 'identity') +
  coord_polar('y') +
  theme_minimal() +
  labs(title = 'Distribución de entidades económicas solidarias (ESE)', 
       x = '', y = '')

## Merge
### Prestadores por población del municipio
Merge_db_summary = Merge_db %>%
  group_by(muni_nombre) %>%
  summarise(Numero_de_Prestadores = n(),
            Poblacion = mean(Poblacion))

Pobmun_Numpres= ggplot(Merge_db_summary, 
  aes(x = Poblacion, y = Numero_de_Prestadores)) +
  geom_point() +
  theme_minimal() +
  labs(title = 'Número de prestadores por población del municipio', 
       x = 'Población del municipio', y = 'Número de prestadores')


# Modelamiento de datos y maching learning
## Preparación de las variables
Merge_db_OLS = Merge_db %>%
  group_by(muni_nombre, Region) %>%
  summarise(
    numero_prestadores = n(),
    Poblacion = mean(Poblacion, na.rm = TRUE),
    Irural = mean(Irural, na.rm = TRUE),
    Superficie = mean(Superficie, na.rm = TRUE),
    .groups = "drop"
  )

## Creación de variables dummies para Region y modelo OLS
OLS_model = lm(numero_prestadores ~ Poblacion + Irural + Superficie + 
                   factor(Region), data = Merge_db_OLS)
OLS_robust_model = coeftest(OLS_model, vcov = vcovHC(OLS_model, type = "HC1"))

## Supuestos de regresión
### Normalidad en los residuales - Jarque Bera
Residuos_OLS = OLS_model$residuals
JB_test = jarque.bera.test(Residuos_OLS)  

### Independencia de los residuales - Box Pierce
DB_test = dwtest(OLS_model)

### Test de multicolinealidad - VIF
VIF_test = vif(OLS_model)

### Test de homosedasticidad - Breusch Pagan
BP_test = bptest(OLS_model)

### Gráfico de dispersión de los residuos contra los valores ajustados
Valores_ajustados = fitted(OLS_model)
data_for_plot = data.frame(Residuos = Residuos_OLS, 
                            ValoresAjustados = Valores_ajustados)

Res_Resadj = ggplot(data_for_plot, aes(x = ValoresAjustados, y = Residuos)) +
  geom_point(alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  theme_minimal() +
  labs(title = "Gráfico de dispersión de residuos vs. valores ajustados",
       x = "Valores Ajustados",
       y = "Residuos")

# Salidas -----
# Datos                       # Se da una visualización breve de los datos
print(head(Municipios))         
print(head(Prestadores))
print(head(Merge_db))

# Exploración de datos        # Tipos de variables y datos principales
str(Municipios)
str(Prestadores)

# Análisis descriptivo        # Estadística descriptiva de los datos
print(Des_stat_Municipios)
print(Des_stat_Prestadores)

# Visualización de datos
## Se establece de manera gráfica la relación entre las variables de entre su 
## misma base de datos y también de forma relacionada 
Grid1 = grid.arrange(Pob_Pobmun, Sup_Freq, ncol = 2)
grid.arrange(Grid1, Rur_Cant, ncol = 1)

Grid2 = grid.arrange(Clas_Cant_Prov, Ese_graph, ncol = 2)
grid.arrange(Grid2, Dept_Cant, ncol = 1)

print(Pobmun_Numpres)


# Modelamiento de datos
print(JB_test)                # Resultado test de normalidad en los residuales
print(DB_test)                # Resultado test de no autocorrelación
print(VIF_test)               # Resultado test de multicolinealidad
print(BP_test)                # Resultado test de homosedasticidad
summary(OLS_model)            # Resultado del modelo de OLS
print(OLS_robust_model)       # Resultado del modelo robusto de OLS
Res_Resadj                    # Gráfica de los errores - Homosedasticidad

# Cerrar conexión
dbDisconnect(DB)
