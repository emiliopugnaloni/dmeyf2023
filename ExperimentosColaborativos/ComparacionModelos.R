
setwd("C:/Users/epugnalo/OneDrive - Telefonica/Documents/Data Mining UBA/2C - DM en Economica y Finanzas/dmeyf2023/ExperimentosColaborativos/")


#Levantamos los archivos con las ganancias por envios

gan_Baseline <- fread("resultados_ganancia_baseline.csv")
gan_FeatureSelection <- fread("resultados_ganancia_feature_selection.csv")

# Agrupamos por la cantidad de envios, sacamos la media y el desvio

gan_Baseline_resumen <- gan_Baseline[, .(mean=mean(gan_acum), sd= sd(gan_acum), count=.N), by=Envios]
gan_Baseline_resumen <- gan_Baseline_resumen[, `:=` (LI = mean-3*sd, LS = mean+3*sd)]

gan_FeatureSelection_resumen <- gan_FeatureSelection[, .(mean=mean(gan_acum), sd= sd(gan_acum), count=.N), by=Envios]
gan_FeatureSelection_resumen <- gan_FeatureSelection_resumen[, `:=` (LI = mean-3*sd, LS = mean+3*sd)]



# ggplot() +
#   geom_smooth(data = ganancias_semilla, aes(x = Envios, y = gan_acum), level=0.95, color = "blue") +
#   #geom_smooth(data = ganancias_semilla_2, aes(x = Envios, y = gan_acum), method = "lm", se = FALSE, color = "red") +
#   labs(x = "X-axis", y = "Y-axis", title = "Comparing Ganancias de Modelos con IC 90%")

#Vemos las ganancias y los umbrales de IC

ggplot() +
  geom_line(data = gan_Baseline_resumen, aes(x = Envios, y = mean, color = "Baseline"), size=1) +
  geom_line(data = gan_Baseline_resumen, aes(x = Envios, y = LI), color = "lightblue") +
  geom_line(data = gan_Baseline_resumen, aes(x = Envios, y = LS), color = "lightblue") +
  
  geom_line(data = gan_FeatureSelection_resumen, aes(x = Envios, y = mean, color = "Feature_Selection"), size=1) +
  geom_line(data = gan_FeatureSelection_resumen, aes(x = Envios, y = LI), color = "pink") +
  geom_line(data = gan_FeatureSelection_resumen, aes(x = Envios, y = LS), color = "pink") +  
  
  
  labs(x = "Envios", y = "Y Values", title = "Your Title") +
  scale_color_manual(name = "Legend", values = c("Baseline" = "blue", "LI" = NA, "LS" = NA, "Feature_Selection" = "pink", "LI" = NA, "LS" = NA), 
                     labels = c("Baseline", "Feature_Selection"))




ggplot() +
  geom_density(data = ganancias_semilla[Envios==12000,], aes(x = gan_acum)) 





