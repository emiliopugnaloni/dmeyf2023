library(data.table)

gc() #free unused memory

data = fread("~/buckets/b1/datasets/competencia_02_fe02.csv.gz")
setorder(data, foto_mes, numero_de_cliente)


#---------------------
# ELIMINAMOS CARNARITOS
# ---------------------

data[,  grep("carnarito", names(data)):=NULL]  #eliminar columnas basadas en patron

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


# TENDENCIA PARA ALGUNAS

cols <- c('ctrx_quarter',
          'm_movimientos_negativos_suma_perc',
          'mcaja_ahorro_perc',
          'cpayroll_trx',
          'm_movimientos_positivos_suma_perc',
          'mpayroll_perc',
          'mpositivos_negativos_div_perc',
          'mtarjeta_visa_consumo_perc',
          'mrentabilidad_annual__perc',
          'm_cahorro_suma_perc',
          'mcuentas_saldo_perc',
          'm_ccorrientes_suma_perc',
          'tc_msaldopesos_suma_perc',
          'c_tarjetas_transacciones_suma',
          'mprestamos_suma_perc',
          'mprestamos_personales_perc',
          'mtarjetas_consumo_suma_perc',
          'm_margen_suma_perc',
          'mpayroll_suma_perc',
          'comisiones_saldo_div_perc',
          'mpasivos_margen__perc',
          'mcuenta_corriente_perc',
          'mcomisiones_mantenimiento_perc',
          'mautoservicio_perc',
          'tc_cconsumos_suma',
          'mnegativos_saldo_div',
          'chomebanking_transacciones',
          'tc_mpagominimo_suma_perc',
          'mrentabilidad_perc',
          'mactivos_margen__perc',
          'mcomisiones_suma_perc',
          'tc_consumo_div_saldo_perc',
          'ccomisiones_mantenimiento',
          'tc_fvencimiento_mayor',
          'Master_mconsumosdolares_perc',
          'mtransferencias_recibidas_perc',
          'cprestamos_personales',
          'ccomisiones_otras_',
          'mtransferencias_resta_perc',
          'm_extracciones_transf_suma_perc',
          'tc_mfinanciacion_menor_perc',
          'm_debitos_automaticos_suma_perc',
          'mcomisiones__perc',
          'Master_mconsumospesos_perc',
          'Visa_mfinanciacion_limite_perc',
          'Master_madelantopesos_perc',
          'mcomisiones_otras_perc',
          'cproductos',
          'mcaja_ahorro_dolares_perc',
          'tc_mlimitecompra_suma_perc',
          'tc_mpagominimo_mayor_perc')



for (i in c(3,6,9))
{
  lag_names <- paste(cols, "_lag", i, sep = "")
  delta_names <- paste(cols, "_delta", i, sep = "")
  ma_names <- paste(cols, "_ma", i, sep = "")

  
  data[, (lag_names) := shift(.SD, i), by=numero_de_cliente, .SDcols = cols]
  data[, (delta_names) := .SD - shift(.SD, i), by = numero_de_cliente, .SDcols = cols]
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


fwrite(data, "~/buckets/b1/datasets/competencia_02_fe03.csv.gz")

