

set.seed(102191)

# calcula cuantos encestes logra una jugadora con indice de enceste prob
# que hace qyt tiros libres

ftirar <- function(prob, qty) {
  return(sum(runif(qty) < prob))
}


# defino loa jugadoras
taurasi <- 0.85
peloton <- rep(0.6, 99) # jugadores identicos
jugadoras <- c(taurasi, peloton)




for (i in 1:10) {
  vaciertos <- mapply(ftirar, jugadoras, 100) # cada jugadora tira 100 tiros
  mejor_ronda <- which.max(vaciertos)  #el indicde de la mejor de la ronda
  aciertos_torneo <- vaciertos[mejor_ronda]  #los aciertos de la mejor

  aciertos_segunda <- ftirar(jugadoras[mejor_ronda], 100)  #los aciertos de la mejor la 2da vez que tira

  cat(aciertos_torneo, "\t", aciertos_segunda, "\n")
}

