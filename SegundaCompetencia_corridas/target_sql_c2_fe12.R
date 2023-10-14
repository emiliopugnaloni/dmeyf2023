library(data.table)

gc() #free unused memory

data = fread("~/buckets/b1/datasets/competencia_02_fe01.csv.gz")


## ----------------
## Nuevas Variables
## ----------------

data[, m_movimientos_neto := m_movimientos_positivos_suma - m_movimientos_negativos_suma]


## --------
## DRIFING
## -------

variables = c('m_movimientos_positivos_suma',
              'm_movimientos_negativos_suma')

for (var in variables)
{
  data[, paste0(var, "_perc") := round((rank(.SD)/.N)*100,0), by=foto_mes, .SDcols = var]  #compute percentiles
  data[, paste0(var):=NULL]  #delete original variable
  
}




# ------------
# FE Historico
# ------------


## A todas Lag -1

cols <- setdiff(names(data), c("numero_de_cliente", "foto_mes"))

# Loop through columns and create lag variables
for (col in cols) {
  lag_names <- paste0(col, "_lag1")
  data[, (lag_names) := shift(.SD, 1), by = numero_de_cliente, .SDcols = col]
}

data[, clase_ternaria_lag1:= NULL] #eliminamos el lag de la clase ternaria



# TENDENCIA PARA ALGUNAS

cols <- c('ctrx_quarter',
          'm_movimientos_negativos_suma_perc',
          'mcaja_ahorro',
          'cpayroll_trx',
          'm_movimientos_positivos_suma_perc',
          'mpayroll',
          'mpositivos_negativos_div',
          'mtarjeta_visa_consumo',
          'mrentabilidad_annual_',
          'm_cahorro_suma',
          'mcuentas_saldo',
          'm_ccorrientes_suma',
          'tc_msaldopesos_suma',
          'c_tarjetas_transacciones_suma',
          'mprestamos_suma',
          'mprestamos_personales',
          'mtarjetas_consumo_suma',
          'm_margen_suma',
          'mpayroll_suma',
          'comisiones_saldo_div',
          'mpasivos_margen_',
          'mcuenta_corriente',
          'mcomisiones_mantenimiento',
          'mautoservicio',
          'tc_cconsumos_suma',
          'mnegativos_saldo_div',
          'chomebanking_transacciones',
          'tc_mpagominimo_suma',
          'mrentabilidad',
          'mactivos_margen_',
          'mcomisiones_suma',
          'tc_consumo_div_saldo',
          'ccomisiones_mantenimiento',
          'tc_fvencimiento_mayor',
          'Master_mconsumosdolares',
          'mtransferencias_recibidas',
          'cprestamos_personales',
          'ccomisiones_otras_',
          'mtransferencias_resta',
          'm_extracciones_transf_suma',
          'tc_mfinanciacion_menor',
          'm_debitos_automaticos_suma',
          'mcomisiones_',
          'Master_mconsumospesos',
          'Visa_mfinanciacion_limite',
          'Master_madelantopesos',
          'mcomisiones_otras',
          'cproductos',
          'mcaja_ahorro_dolares',
          'tc_mlimitecompra_suma',
          'tc_mpagominimo_mayor',
          'm_movimientos_neto'
          )





for (i in c(2,3,4,6))
{
  lag_names <- paste(cols, "_lag", i, sep = "")
  ma_names <- paste(cols, "_ma", i, sep = "")
  ma_names_r <- paste(cols, "_ma_round_", i, sep = "")

  
  data[, (lag_names) := shift(.SD, i), by=numero_de_cliente, .SDcols = cols]
  data[, (ma_names) := frollmean(.SD, n = i, align = "right"), by = numero_de_cliente, .SDcols = cols]
  
}

#redondeamos columnas
ma_columns <- grep("_ma", names(data), value = TRUE)
data[, (ma_columns) := lapply(.SD, round), .SDcols = ma_columns]

#traemos media movil de lag -3
ma3_columns <- grep("_ma3", names(data), value = TRUE)
ma3_lag3_columns <- paste(ma3_columns, "_lag3", sep = "")
data[, (ma3_lag3_columns) := .SD - shift(.SD, i), by = numero_de_cliente, .SDcols = ma3_columns]


#medidas de tendencia
tend_names <- paste(cols, "_tend_ma3", sep = "")
data[, (tend_names) := round(.SD / frollmean(.SD, n = 3, align = "right"),2), by = numero_de_cliente, .SDcols = cols]

#medidas de tendencia
tend_names <- paste(cols, "_tend_ma6", sep = "")
data[, (tend_names) := round(.SD / frollmean(.SD, n = 6, align = "right"),2), by = numero_de_cliente, .SDcols = cols]


fwrite(data, "~/buckets/b1/datasets/competencia_02_fe12.csv.gz")

