library(data.table)

gc() #free unused memory

data = fread("C:/Users/emiba/Documents/DMenEyF/datasets/competencia_02_fe01.csv.gz")


## --------
## DRIFING
## -------

variables = c('cliente_antiguedad',
              'mrentabilidad',
              'mrentabilidad_annual_',
              'mcomisiones_',
              'mactivos_margen_',
              'mpasivos_margen_',
              'mcuenta_corriente_adicional',
              'mcuenta_corriente',
              'mcaja_ahorro',
              'mcaja_ahorro_adicional',
              'mcaja_ahorro_dolares',
              'mcuentas_saldo',
              'mautoservicio',
              'mtarjeta_visa_consumo',
              'mtarjeta_master_consumo',
              'mprestamos_personales',
              'mprestamos_prendarios',
              'mprestamos_hipotecarios',
              'mplazo_fijo_dolares',
              'mplazo_fijo_pesos',
              'minversion1_pesos',
              'minversion1_dolares',
              'minversion2',
              'mpayroll',
              'mpayroll2',
              'mcuenta_debitos_automaticos',
              'mttarjeta_visa_debitos_automaticos_',
              'mttarjeta_master_debitos_automaticos',
              'mpagodeservicios',
              'mpagomiscuentas',
              'mcajeros_propios_descuentos',
              'mtarjeta_visa_descuentos',
              'mtarjeta_master_descuentos',
              'mcomisiones_mantenimiento',
              'mcomisiones_otras',
              'mforex_buy',
              'mforex_sell',
              'mtransferencias_recibidas',
              'mtransferencias_emitidas',
              'mextraccion_autoservicio',
              'mcheques_depositados',
              'mcheques_emitidos',
              'mcheques_depositados_rechazados',
              'mcheques_emitidos_rechazados',
              'matm',
              'matm_other',
              'Master_mfinanciacion_limite',
              'Master_msaldototal',
              'Master_msaldopesos',
              'Master_msaldodolares',
              'Master_mconsumospesos',
              'Master_mconsumosdolares',
              'Master_mlimitecompra',
              'Master_madelantopesos',
              'Master_madelantodolares',
              'Master_mpagado',
              'Master_mpagospesos',
              'Master_mpagosdolares',
              'Master_mconsumototal',
              'Master_mpagominimo',
              'Visa_mfinanciacion_limite',
              'Visa_msaldototal',
              'Visa_msaldopesos',
              'Visa_msaldodolares',
              'Visa_mconsumospesos',
              'Visa_mconsumosdolares',
              'Visa_mlimitecompra',
              'Visa_madelantopesos',
              'Visa_madelantodolares',
              'Visa_mpagado',
              'Visa_mpagospesos',
              'Visa_mpagosdolares',
              'Visa_mconsumototal',
              'Visa_mpagominimo',
              'tc_mfinanciacion_mayor',
              'tc_mfinanciacion_menor',
              'tc_mlimitecompra_mayor',
              'tc_mlimitecompra_menor',
              'tc_mpagominimo_mayor',
              'tc_mpagominimo_menor',
              'tc_mfinanciacion_limite_suma',
              'tc_msaldototal_suma',
              'tc_msaldopesos_suma',
              'tc_msaldodolares_suma',
              'tc_mconsumospesos_suma',
              'tc_mconsumosdolares_suma',
              'tc_mlimitecompra_suma',
              'tc_madelantopesos_suma',
              'tc_madelantodolares_suma',
              'tc_mpagado_suma',
              'tc_mpagospesos_suma',
              'tc_mpagosdolares_suma',
              'tc_mconsumototal_suma',
              'tc_mpagominimo_suma',
              'm_margen_suma',
              'm_ccorrientes_suma',
              'm_cahorro_suma',
              'mtarjetas_consumo_suma',
              'mprestamos_suma',
              'mplazo_fijo_suma',
              'minversion_suma',
              'mpayroll_suma',
              'm_debitos_automaticos_suma',
              'm_descuentos_suma',
              'mcomisiones_suma',
              'mtransferencias_resta',
              'm_extracciones_transf_suma',
              'm_movimientos_positivos_suma',
              'm_movimientos_negativos_suma',
              'Visa_consumo_div_limite',
              'Master_consumo_div_limite',
              'tc_consumo_div_limite',
              'tc_consumo_div_saldo',
              'tc_pagado_div_saldo',
              'prestamos_saldo_div',
              'descuentos_saldo_div',
              'comisiones_saldo_div',
              'extracciones_saldo_div',
              'mpositivos_negativos_div')


for (var in variables)
{
  data[, paste0(var, "_perc") := round((rank(.SD)/.N)*100,0), by=foto_mes, .SDcols = var]  #compute percentiles
  data[, paste0(var):=NULL]  #delete original variable
  
}


## ---------------------------
## CARNARITOS PARA FEATURE IMP
## ---------------------------

cant_carnaritos = 30

for (i in 1:cant_carnaritos)
{
  data[, paste0("carnarito",i) := runif(.N)]
  
}


#fwrite("C:/Users/epugnalo/OneDrive - Telefonica/Documents/Data Mining UBA/2C - DM en Economica y Finanzas/datasets/competencia_02_crudo.csv.gz")
fwrite(data, "C:/Users/emiba/Documents/DMenEyF/datasets/competencia_02_fe02.csv.gz")

