# para correr el Google Cloud
#   8 vCPU
#  64 GB memoria RAM


# limpio la memoria
rm(list = ls()) # remove all objects
gc() # garbage collection

require("data.table")
require("lightgbm")


# defino los parametros de la corrida, en una lista, la variable global  PARAM
#  muy pronto esto se leera desde un archivo formato .yaml
PARAM <- list()
PARAM$experimento <- "C3_Modelo_Final_Mejores_OB"

PARAM$input$dataset <- "./datasets/competencia_02_fe03.csv.gz"

PARAM$input$mejores_ob <- "~/buckets/b1/datasets/Mejores_Modelos_OB.csv"

# meses donde se entrena el modelo
PARAM$input$training <- c(201906, 201907, 201908, 201909, 201910, 201911, 201912, 202008, 202009, 202010, 
                          202011, 202012, 202101, 202102, 202103,202104, 202105,202106,202107)

PARAM$input$future <- c(202109) # meses donde se aplica el modelo

PARAM$finalmodel$semilla <- 673787

# hiperparametros optimos de BO
PARAM$finalmodel$optim$num_iterations <- 0
PARAM$finalmodel$optim$learning_rate <- 0
PARAM$finalmodel$optim$feature_fraction <- 0
PARAM$finalmodel$optim$min_data_in_leaf <- 0
PARAM$finalmodel$optim$num_leaves <- 0
PARAM$finalmodel$optim$bagging_fraction <- 0
PARAM$finalmodel$optim$pos_bagging_fraction <- 0
PARAM$finalmodel$optim$neg_bagging_fraction <- 0
PARAM$finalmodel$optim$baggin_freq <- 0
PARAM$finalmodel$optim$feature_fraction_bynode <- 0


# Hiperparametros FIJOS de  lightgbm
PARAM$finalmodel$lgb_basicos <- list(
  boosting = "gbdt", # puede ir  dart  , ni pruebe random_forest
  objective = "binary",
  metric = "custom",
  first_metric_only = TRUE,
  boost_from_average = TRUE,
  feature_pre_filter = FALSE,
  force_row_wise = TRUE, # para reducir warnings
  verbosity = -100,
  max_depth = -1L, # -1 significa no limitar,  por ahora lo dejo fijo
  min_gain_to_split = 0.0, # min_gain_to_split >= 0.0
  min_sum_hessian_in_leaf = 0.001, #  min_sum_hessian_in_leaf >= 0.0
  lambda_l1 = 0.0, # lambda_l1 >= 0.0
  lambda_l2 = 0.0, # lambda_l2 >= 0.0
  max_bin = 31L, # lo debo dejar fijo, no participa de la BO

  bagging_fraction = 1.0, # 0.0 < bagging_fraction <= 1.0
  pos_bagging_fraction = 1.0, # 0.0 < pos_bagging_fraction <= 1.0
  neg_bagging_fraction = 1.0, # 0.0 < neg_bagging_fraction <= 1.0
  is_unbalance = FALSE, #
  scale_pos_weight = 1.0, # scale_pos_weight > 0.0

  drop_rate = 0.1, # 0.0 < neg_bagging_fraction <= 1.0
  max_drop = 50, # <=0 means no limit
  skip_drop = 0.5, # 0.0 <= skip_drop <= 1.0

  extra_trees = TRUE, # Magic Sauce

  seed = PARAM$finalmodel$semilla
)

PARAM$hyperparametertuning$POS_ganancia <- 273000
PARAM$hyperparametertuning$NEG_ganancia <- -7000



#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Aqui empieza el programa
setwd("~/buckets/b1")

# cargo el dataset donde voy a entrenar
dataset <- fread(PARAM$input$dataset, stringsAsFactors = TRUE)

# cargamos el dataset con los mejores hiperparametros de OB
mejores_modelos_ob <- fread(PARAM$input$mejores_ob)


# Catastrophe Analysis  -------------------------------------------------------
# deben ir cosas de este estilo
#   dataset[foto_mes == 202006, active_quarter := NA]

# Data Drifting
# por ahora, no hago nada



# Feature Engineering Historico  ----------------------------------------------
#   aqui deben calcularse los  lags y  lag_delta
#   Sin lags no hay paraiso ! corta la bocha
#   https://rdrr.io/cran/data.table/man/shift.html


#--------------------------------------

# paso la clase a binaria que tome valores {0,1}  enteros
# set trabaja con la clase  POS = { BAJA+1, BAJA+2 }
# esta estrategia es MUY importante
dataset[, clase01 := ifelse(clase_ternaria %in% c("BAJA+2", "BAJA+1"), 1L, 0L)]

#--------------------------------------

# los campos que se van a utilizar
campos_buenos <- setdiff(colnames(dataset), c("clase_ternaria", "clase01"))

#--------------------------------------


# establezco donde entreno
dataset[, train := 0L]
dataset[foto_mes %in% PARAM$input$training, train := 1L]

#--------------------------------------
# creo las carpetas donde van los resultados
# creo la carpeta donde va el experimento
dir.create("./exp/", showWarnings = FALSE)
dir.create(paste0("./exp/", PARAM$experimento, "/"), showWarnings = FALSE)

# Establezco el Working Directory DEL EXPERIMENTO
setwd(paste0("./exp/", PARAM$experimento, "/"))


# dejo los datos en el formato que necesita LightGBM
dtrain <- lgb.Dataset(
  data = data.matrix(dataset[train == 1L, campos_buenos, with = FALSE]),
  label = dataset[train == 1L, clase01]
)


#creamos dataset para guardar los resultados
data_predicciones <- data.table(numero_de_cliente = dataset[foto_mes == PARAM$input$future, numero_de_cliente])


for (i in length(resultados_ob$num_iterations))
{
  
  #definimos los paremtros
  PARAM$finalmodel$optim$num_iterations <- mejores_modelos_ob[i]$num_iterations
  PARAM$finalmodel$optim$learning_rate <- mejores_modelos_ob[i]$learning_rate
  PARAM$finalmodel$optim$feature_fraction <- mejores_modelos_ob[i]$feature_fraction
  PARAM$finalmodel$optim$min_data_in_leaf <- mejores_modelos_ob[i]$min_data_in_leaf
  PARAM$finalmodel$optim$num_leaves <- mejores_modelos_ob[i]$num_leaves
  PARAM$finalmodel$optim$bagging_fraction <- mejores_modelos_ob[i]$bagging_fraction
  PARAM$finalmodel$optim$pos_bagging_fraction <- mejores_modelos_ob[i]$pos_bagging_fraction
  PARAM$finalmodel$optim$neg_bagging_fraction <- mejores_modelos_ob[i]$neg_bagging_fraction
  PARAM$finalmodel$optim$baggin_freq <- mejores_modelos_ob[i]$baggin_freq
  PARAM$finalmodel$optim$feature_fraction_bynode <- mejores_modelos_ob[i]$feature_fraction_bynode
  
  # genero el modelo
  param_completo <- c(PARAM$finalmodel$lgb_basicos,
                    PARAM$finalmodel$optim)
  
  modelo <- lgb.train(
    data = dtrain,
    param = param_completo,
  )
  
  #--------------------------------------
  # ahora imprimo la importancia de variables
  tb_importancia <- as.data.table(lgb.importance(modelo))
  archivo_importancia <- paste0("impo_M",i,",txt")
  
  fwrite(tb_importancia,
         file = archivo_importancia,
         sep = "\t"
  )
  
  #--------------------------------------
  
  
  # aplico el modelo a los datos sin clase
  dapply <- dataset[foto_mes == PARAM$input$future]
  
  # aplico el modelo a los datos nuevos
  prediccion <- predict(
    modelo,
    data.matrix(dapply[, campos_buenos, with = FALSE])
  )
  
  # genero la tabla de entrega
  tb_entrega <- dapply[, list(numero_de_cliente, foto_mes)]
  tb_entrega[, prob := prediccion]
  
  # grabo las probabilidad del modelo
  archivo_prediccion <- paste0("prediccion_M",i,".txt")
  fwrite(tb_entrega,
         file = archivo_prediccion,
         sep = "\t"
  )
  
  # ordeno por probabilidad descendente
  setorder(tb_entrega, -prob)
  
  
  # genero archivos con los  "envios" mejores
  # deben subirse "inteligentemente" a Kaggle para no malgastar submits
  # si la palabra inteligentemente no le significa nada aun
  # suba TODOS los archivos a Kaggle
  # espera a la siguiente clase sincronica en donde el tema sera explicado
  
  cortes <- seq(9000, 14000, by = 500)
  for (envios in cortes) {
    tb_entrega[, Predicted := 0L]
    tb_entrega[1:envios, Predicted := 1L]
    
    nombre_archivo <- paste0(PARAM$experimento, "_M",i, "_", envios, ".csv")
    fwrite(tb_entrega[, list(numero_de_cliente, Predicted)],
           file = nombre_archivo,
           sep = ","
    )
  }
  
  
  ## Genero la nueva columna en el dataset con todas las predicciones y guardo (por las dudas)
  data_predicciones[,paste0("M",i)] <- prediccion
  fwrite(data_predicciones, file = "tabla_predicciones_modelos.csv",  sep = ",")
  
}

cat("\n\nLa generacion de los archivos para Kaggle ha terminado\n")

