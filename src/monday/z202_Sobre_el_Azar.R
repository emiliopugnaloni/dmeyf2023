##
## Sobre el Azar
##
## ---------------------------
## Step 1: El simple y viejo Train / Test
## ---------------------------
##
## If you torture the data long enough, it will confess.
## --- Ronald Coase
##

# nolint: indentation_linter.

# Limpiamos el entorno
rm(list = ls())
gc(verbose = FALSE)

# Librerías necesarias
require("data.table")
require("rpart")
require("ROCR")
require("ggplot2")


# Poner la carpeta de la materia de SU computadora local
setwd("C:/Users/emiba/Documents/DMenEyF")
# Poner sus semillas
semillas <- c(673787,673789,673811,673817,673837)

# Cargamos el dataset
dataset <- fread("./datasets/competencia_01.csv")

# Nos quedamos solo con el 202101
dataset <- dataset[foto_mes == 202103]
# Creamos una clase binaria
dataset[, clase_binaria := ifelse(
                            clase_ternaria == "BAJA+2",
                                "evento",
                                "noevento"
                            )]
# Borramos el target viejo
dataset[, clase_ternaria := NULL]

# Seteamos nuestra primera semilla
set.seed(semillas[1])

# Particionamos de forma estratificada
in_training <- caret::createDataPartition(dataset$clase_binaria,
                     p = 0.70, list = FALSE) 
dtrain  <-  dataset[in_training, ]
dtest   <-  dataset[-in_training, ]

## Preguntas
## - ¿Por qué separamos en train/test?
## - Son números aleatorios los que nos dan las computadoras
## - ¿Por qué usamos semillas?
## - ¿Qué es una partición estratificada?
## - ¿Tiene realemente alguna ventaja la partición estratificada ?
# no tanto porque tenemos 900 de la clase baja. 900 es un numero grande, por proba, casi que va a quedar igual que sin estratificar
## ---------------------------
## Step 2: Armando el primer modelo particionado
## ---------------------------

# Medimos cuanto tarda nuestro modelo en ajustar
start_time <- Sys.time()
modelo <- rpart(clase_binaria ~ .,
                data = dtrain,
                xval = 0,
                cp = 0,
                minsplit = 20,
                minbucket = 1,
                maxdepth = 5)
print(Sys.time() - start_time)

pred_testing <- predict(modelo, dtest, type = "prob")

## Preguntas:
## - ¿Qué tan importante mirar las métricas de train?

## ---------------------------
## Step 3: Mirando la ganancia
## ---------------------------

# Armamos una función que nos calcule la ganancia, usando el punto de corte de
# 0.025
ganancia <- function(probabilidades, clase) {
  return(sum(
    (probabilidades >= 0.025) * ifelse(clase == "evento", 273000, -7000))
  )
}

# La ganancia en testing NORMALIZADA
print(ganancia(pred_testing[, "evento"], dtest$clase_binaria) / 0.3)

## Actividad:
## Comparta el número que le dio de ganancia y cuanto error estima que
## puede haber con el resto de sus compañeros

## ---------------------------
## Step 4: Probando más muchas más semillas
## ---------------------------

# Almacenaremos los resultados en una tabla
resultados_n_gan <- c()

# Calcule en función del tiempo de ejecución anterior, cuantos árboles puede
# hacer en 5 minutos y ponga ese número en la siguiente variable
n <- 100

set.seed(semillas[1])
t0 <- Sys.time()
for (i in 1:n) {

    in_training <- caret::createDataPartition(dataset[, get("clase_binaria")],
                            p = 0.70, list = FALSE)
    dtrain  <-  dataset[in_training, ]
    dtest   <-  dataset[-in_training, ]

    modelo <- rpart(clase_binaria ~ .,
                    data = dtrain,
                    xval = 0,
                    cp = 0,
                    minsplit = 20,
                    minbucket = 1,
                    maxdepth = 5)

    pred_testing <- predict(modelo, dtest, type = "prob")

    gan <- ganancia(pred_testing[, "evento"], dtest$clase_binaria) / 0.3

    resultados_n_gan <- c(resultados_n_gan, gan)
}
print(Sys.time() - t0)

## Preguntas:
## ¿Cree que puede cambiar mucho la ganancia en **test** para dos semillas
## distintas?
#porque se hacen split distintos

## ---------------------------
## Step 5: Analizando el azar de las semillas
## ---------------------------

# La menor ganancia conseguida en test
print(min(resultados_n_gan))

# La mayor ganancia
print(max(resultados_n_gan))

# La media de la ganancia
print(mean(resultados_n_gan))

# Veamos la dispersión de la ganancia
ggplot() + aes(resultados_n_gan) + geom_density()

## Preguntas
## Buscamos separar los conjuntos de datos para hacer robustos nuestros modelos
## y nos damos cuenta que las `semillas` pueden distorsionar enormemente 
## las métricas reales (si es que existen).
## - ¿Por qué se produce semejante dispersión?
## - ¿Cuál considera que es el "valor real"? el promedio esata mas cerca
## 
##   Dicho de otra forma, si aplicara el mismo modelo a un nuevo conjunto de 
##   datos, ¿cuál sería el esperado?

## ---------------------------
## Step 6: Tratando de corregir la dispersión
## ---------------------------

# Veamos si tomar el promedio de 5 árboles nos ayuda a reducir la dispersión
cantidad_arboles <- 5

resultados_n_mcv <- c()
set.seed(semillas[1])

for (i in 1:50) 
    resultados_n_mcv <- c(resultados_n_mcv, mean(sample(resultados_n_gan, cantidad_arboles)))

# La menor ganancia conseguida en test
print(min(resultados_n_mcv))

# La mayor ganancia
print(max(resultados_n_mcv))

# La media de la ganancia
print(mean(resultados_n_mcv))

# Veamos la dispersión de la ganancia
ggplot() + aes(resultados_n_mcv) + geom_density()

## NOTA: Esta técnica es conocida como Montecarlo Cross Validation
##  se entrenar varios modelo con distintas semillas y se mide la performance media

## Preguntas
## - ¿Qué efecto observa cuando se toma como medición el promedio de 5 árboles?
## - ¿Desapareció el error?
## - ¿Si se hubieran tomado más valores que efectos esperaría?
## - ¿Que ventaja y desventaja ve en esta técnica comparada al Cross Validation?

## ---------------------------
## Step 7: Midiendo nuestras semillas
## ---------------------------

resultados_mis_semillas <- c()

t0 <- Sys.time()
for (s in semillas) {
    set.seed(s)
    in_training <- caret::createDataPartition(dataset[, get("clase_binaria")],
                            p = 0.70, list = FALSE)
    dtrain  <-  dataset[in_training, ]
    dtest   <-  dataset[-in_training, ]

    modelo <- rpart(clase_binaria ~ .,
                    data = dtrain,
                    xval = 0,
                    cp = 0,
                    minsplit = 20,
                    minbucket = 1,
                    maxdepth = 5)

    pred_testing <- predict(modelo, dtest, type = "prob")

    gan <- ganancia(pred_testing[, "evento"], dtest$clase_binaria) / 0.3

    resultados_mis_semillas <- c(resultados_mis_semillas, gan)

}
print(Sys.time() - t0)

print(mean(resultados_mis_semillas))

## Preguntas
## - ¿Cuán lejos se encontró la media de sus semillas respecto a los resultados
##    anteriores?
## - ¿Usaría semillas que le den un valor promedio más alto?
## - ¿Usaría más semillas?
## - ¿Que ventaja y desventaja ve en usar más semillas?

## ---------------------------
## Step 8: Buscando un mejor modelo
## ---------------------------

resultados_grid_search <- data.table()

# Complete los valores que se van a combinar para cada parámetro a explorar

for (cp in c(-1, 0.01)) { 
for (md in c(5, 10, 15, 30)) {  #max depth
for (ms in c(1, 50, 500, 1000)) {  #min split
for (mb in c(1, as.integer(ms / 2))) { #min bucket (se define en funcion del min split en este caso)

    t0 <- Sys.time()
    gan_semillas <- c()
    for (s in semillas) {
        set.seed(s)
        in_training <- caret::createDataPartition(dataset[,
                        get("clase_binaria")],
                                p = 0.70, list = FALSE)
        dtrain  <-  dataset[in_training, ]
        dtest   <-  dataset[-in_training, ]

        modelo <- rpart(clase_binaria ~ .,
                        data = dtrain,
                        xval = 0,
                        cp = cp,
                        minsplit = ms,
                        minbucket = mb,
                        maxdepth = md)

        pred_testing <- predict(modelo, dtest, type = "prob")
        gan <- ganancia(pred_testing[, "evento"], dtest$clase_binaria) / 0.3

        gan_semillas <- c(gan_semillas, gan)
    }
    tiempo <-  as.numeric(Sys.time() - t0, units = "secs")

    resultados_grid_search <- rbindlist(list(
                                resultados_grid_search,
                                data.table(
                                    tiempo = tiempo,
                                    cp = cp,
                                    mb = mb,
                                    ms = ms,
                                    md = md,
                                    gan = mean(gan_semillas)) # se puede agregar el sd?
                                ))
}
}
}
}

# Visualizo los parámetros de los mejores parámetros
print(resultados_grid_search[gan == max(gan), ])

## TAREA:
## Una vez que tenga sus mejores parámetros, haga una copia del script
## rpart/z101_PrimerModelo.R, cambie los parámetros dentro del script,
## ejecutelo y suba a Kaggle su modelo.

## Preguntas
## - ¿Cuál es la diferencia entre **test** y **validation**?
## - ¿Cuántas veces podemos usar el conjunto de **test** sin
##   convertirlo en **validation**?
##
## La GRAN pregunta:
## - ¿Qué otra cosita de la materia tiene una partición 70 / 30?
## - Todo lo que hemos visto ¿Va a afectar a esa cosita?.