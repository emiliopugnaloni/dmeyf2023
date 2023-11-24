library(data.table)
gc() #free unused memory

data <- fread("~/buckets/b1/datasets/competencia_03_v2.csv.gz")
setorder(data, foto_mes, numero_de_cliente)

# ------------
# FE Historico
# ------------

## A todas Lags (1,3,6,9), Moving Average (3,6,9) y Tendencia (3,6,9)

cols <- setdiff(names(data), c("numero_de_cliente", "foto_mes", "clase_ternaria"))


for (i in c(1,3,6,9))
{
  print(paste0(format(Sys.time(),"%H:%M:%S")," empezando lags: ",i)) 
  
  lag_names <- paste(cols, "_lag", i, sep = "")
  ma_names <- paste(cols, "_ma", i, sep = "")
  tend_names <- paste(cols, "_tend_ma", i, sep = "")
  
  data[, (lag_names) := shift(.SD, i), by=numero_de_cliente, .SDcols = cols]
  
  if (i!= 1){
    
    print(paste0(format(Sys.time(),"%H:%M:%S")," empezando ma: ",i)) 
    
    data[, (ma_names) := frollmean(.SD, n = i, align = "right"), by = numero_de_cliente, .SDcols = cols]
    data[, (ma_names) := round(.SD,2), .SDcols = ma_names]
    
    print(paste0(format(Sys.time(),"%H:%M:%S")," empezando tendencias: ",i)) 
    data[, (tend_names) := (.SD-mget(paste(cols, "_ma", i, sep = ""))), .SDcols = cols]
    data[, (tend_names) := round(.SD,2), .SDcols = tend_names]
    
  }
  

}

fwrite(data, "~/buckets/b1/datasets/competencia_03_v2_fe.csv.gz")



