library(parallel)
library(testit) # para pruebas, recuerda instalar antes de usar
ks <- c(1,5,10,15,20,25,50,100,200)*1000
duracion <- 20
replicas =  30
impresion = FALSE
tiempos = numeric()
rotura <- function(x) {
    return (1 / (1 + exp((c - x) / d)))
}
union <- function(x) {
    return (exp(-x / c))
}
romperse <- function(tam, cuantos) {
    if (tam > 1) { # no tiene caso romper si no se puede
        romper <- round(rotura(tam) * cuantos) # independientes
        resultado <- rep(tam, cuantos - romper) # los demas
        if (romper > 0) {
            if(tam>2){
               rot = sample(1:(tam-1), romper, replace=TRUE)
            }else{
                rot <- rep(1,romper)
            }
            nrot = rep(tam, romper)-rot            
            resultado <-c(resultado,rot,nrot)
            #for (cumulo in 1:romper) { # agregar las rotas
            #    t <- 1
            #    if (tam > 2) { # sample no jala con un solo valor
            #        t <- sample(1:(tam-1), 1)
            #    }
            #    resultado <- c(resultado, t, tam - t)
            #}
        }
    } else {
        resultado <- rep(1, cuantos)
    }
    assert(sum(resultado) == tam * cuantos) # no hubo perdidas
    return(resultado)
}
unirse <- function(tam, cuantos) {
    unir <- round(union(tam) * cuantos) # independientes
    if (unir > 0) {
        division <- c(rep(-tam, unir), rep(tam, cuantos - unir))
        assert(sum(abs(division)) == tam * cuantos)
        return(division)
    } else {
        return(rep(tam, cuantos))
    }
}
cluster = makeCluster(detectCores(logical=FALSE))

for(k in ks)
n <- 30*k
originales <- rnorm(k)
cumulos <- originales - min(originales) + 1
cumulos <- round(n * cumulos / sum(cumulos))
assert(min(cumulos) > 0)
diferencia <- n - sum(cumulos)
if (diferencia > 0) {
    for (i in 1:diferencia) {
        p <- sample(1:k, 1)
        cumulos[p] <- cumulos[p] + 1
    }
} else if (diferencia < 0) {
    for (i in 1:-diferencia) {
        p <- sample(1:k, 1)
        if (cumulos[p] > 1) {
            cumulos[p] <- cumulos[p] - 1
        }
    }
}
assert(length(cumulos[cumulos == 0]) == 0) # que no haya vacios
assert(sum(cumulos) == n)
c <- median(cumulos) # tamanio critico de cumulos
d <- sd(cumulos) / 4 # factor arbitrario para suavizar la curva

freq <- as.data.frame(table(cumulos))
names(freq) <- c("tam", "num")
freq$tam <- as.numeric(levels(freq$tam))[freq$tam]
digitos <- floor(log(duracion, 10)) + 1


for(replica in 1:replicas){
    tempo = proc.time()[3]
    for (paso in 1:duracion) {
        assert(sum(cumulos) == n)
        cumulos <- integer()
    #clusterExport(cluster, "assert")
    ##clusterExport(cluster, "freq")
    #clusterExport(cluster, "d")
    #clusterExport(cluster, "c")
    #clusterExport(cluster, "rotura")
    #clusterExport(cluster, "romperse")
    #t1= proc.time()[3]
    #cumulos <- unlist(parRapply(cluster, freq, function(urna){ 
    #    romperse(urna[1],urna[2])
    #    }))
        for (i in 1:dim(freq)[1]) { # fase de rotura
            urna <- freq[i,]
            if (urna$tam > 1) { # no tiene caso romper si no se puede
                cumulos <- c(cumulos, romperse(urna$tam, urna$num))
            } else {
                cumulos <- c(cumulos, rep(1, urna$num))
            }
        }
    #print(paste("r",nrow(freq), proc.time()[3]- t1))
        assert(sum(cumulos) == n)
        assert(length(cumulos[cumulos == 0]) == 0) # que no haya vacios
        freq <- as.data.frame(table(cumulos)) # actualizar urnas
        names(freq) <- c("tam", "num")
        freq$tam <- as.numeric(levels(freq$tam))[freq$tam]
        assert(sum(freq$num * freq$tam) == n)
        cumulos <- integer()
    ##clusterExport(cluster, "freq")
    #clusterExport(cluster, "union")
    #clusterExport(cluster, "unirse")
    #t1= proc.time()[3]
    #cumulos <- unlist(parRapply(cluster, freq, function(urna){
    #    unirse(urna[1],urna[2])
    #    }))
        for (i in 1:dim(freq)[1]) { # fase de union
            urna <- freq[i,]
            cumulos <- c(cumulos, unirse(urna$tam, urna$num))
        }
    #print(paste("u",nrow(freq), proc.time()[3]- t1))
    
        assert(sum(abs(cumulos)) == n)
        assert(length(cumulos[cumulos == 0]) == 0) # que no haya vacios
        juntarse <- -cumulos[cumulos < 0]
        cumulos <- cumulos[cumulos > 0]
        assert(sum(cumulos) + sum(juntarse) == n)
    #t1= proc.time()[3]
        nt <- length(juntarse)
    
        if (nt > 0) {
            if (nt > 1) {
                juntarse <- sample(juntarse)
                clusterExport(cluster, "juntarse")
                cumulos <- c(cumulos,unlist(parSapply(cluster, 1:floor(nt / 2), function(x){
                    juntarse[2*x-1] + juntarse[2*x]
                })))
            #for (i in 1:floor(nt / 2) ) {
            #    cumulos <- c(cumulos, juntarse[2*i-1] + juntarse[2*i])
            #}
            }
            if (nt %% 2 == 1) {
                cumulos <- c(cumulos, juntarse[nt])
            }
        }
        assert(sum(cumulos) == n)
        freq <- as.data.frame(table(cumulos))
        names(freq) <- c("tam", "num")
        freq$tam <- as.numeric(levels(freq$tam))[freq$tam]
        assert(sum(freq$num * freq$tam) == n)
    #print(paste("l",nrow(freq), proc.time()[3]- t1))
        if(impresion){
            tl <- paste(paso, "", sep="")
            while (nchar(tl) < digitos) {
                tl <- paste("0", tl, sep="")
            }
            png(paste("p8_ct", tl, ".png", sep=""), width=300, height=300)
            tope <- 50 * ceiling(max(cumulos) / 50)
            hist(cumulos, breaks=seq(0, tope, 50), 
                 main=paste("Paso", paso, "con ambos fen\u{00f3}menos"), freq=FALSE,
                 ylim=c(0, 0.05), xlab="Tama\u{00f1}o", ylab="Frecuencia relativa")
            graphics.off()
        }
    }
    tiempos <- rbind(tiempos,c(replica,k,proc.time()[3] - tempo))
}
stopCluster(cluster)
colnames(tiempos)=c("Tiempo")
print(tiempos)
write.csv(tiempos, "tiemposp.csv")
png(paste("tiempo","line", ".png", sep=""), width=1200, height=900)
plot(tiempos, type="o")
graphics.off()
png(paste("tiempo","bxplt", ".png", sep=""), width=1200, height=900)
boxplot(tiempos)
graphics.off()