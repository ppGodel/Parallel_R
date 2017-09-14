suppressMessages(library(parallel))

l <- 1.5
n <- 50
pi <- 0.05
pr <- 0.02
v <- l / 30
r <- 0.1
tmax <- 100

data = c(0, 1, 3)
pc = 0.2
pv = 0
probs = c(1 - (pc +pv), pc, pv)
impr = TRUE
inic = proc.time()
agentes <<- data.frame(x = runif(n,0,l), y = runif(n,0,l), dx = runif(n, -v, v), dy = runif(n, -v, v), estado  = sample(data, n, replace=TRUE, probs)  )
epidemia <- integer()
inmunes <- integer()
saludables <- integer()
digitos <- floor(log(tmax, 10)) + 1

#cluster = makeCluster(detectCores(logical=FALSE) - 1)
#clusterExport(cluster, "l")
#clusterExport(cluster, "v")
#clusterExport(cluster, "pi")
#assign = parSapply(cluster, 1:n, asignacion)

procesaContagio  <- function(y)
{
    #contagio por linea de barrido
    ordatos = agentes[order(agentes$x),] #ordenar los datos por el eje x
    cercanos= data.frame(i=numeric(),x=numeric(),y=numeric(), estado=numeric()) # los más cercanos a la linea de barrido que tal ue su distancia a la linea de barrido es menor al umbral
    for(i in 1:n){ #recorrido de los puntos ordenados
        ap = cbind(i,ordatos[i,]) #actual point
        if(nrow(cercanos) > 0){ # si hay puntos cercanos a la linea de barrido
            #actualizamos los cercanos al nuevo putno de la linea
            cercanos= cercanos[which(cercanos$x>(ap$x-r)),] 
            #calculo de la distancia de los cercanos al punto actual en la linea de barrido
            d = sqrt((rep(ap$x, nrow(cercanos))-cercanos$x)**2)+((rep(ap$y,nrow(cercanos))-cercanos$y)**2)
            md = which(d<r)
            #si hay alguien en el rango del umbral
            if(any(md > 0)){
                dist = d[md]
                li = cbind(cercanos[md,] , dist )            
                if(ap$estado == 1){
                    if( any(li$estado==0) ){
                        aux = li[which(li$estado == 0),]
                        probc <- ( runif(nrow(aux)) < (rep(r, nrow(aux)) - aux$dist) / rep(r, nrow(aux)) )
                        #print(length(which(probc !=0)))
                        ordatos[aux$i,]$estado = ifelse(probc,1,0)                       
                    }
                    if (runif(1) < pr) {
                        ordatos[ap$i,]$estado = 2 # recupera
                    }
                }
                if(ap$estado == 0) {
                    if( any(li$estado==1) ){                        
                        if( runif(1) > 0.5**(length(which(li$estado==1))) ){
                            ordatos[ap$i,]$estado = 1
                        }
                    }
                }
            }
            
            
        }
        cercanos = rbind(cercanos,ap) #agregar punto actual a cercanos.
    }
    agentes$estado <<- ordatos[order(as.numeric(row.names(ordatos))),]$estado
    agentes$x <<- agentes$x + agentes$dx 
    agentes$y <<- agentes$y + agentes$dy
    if( any(agentes$x > l) ){
        agentes[which(agentes$x > l),]$x <<- agentes[which(agentes$x > l),]$x - l
    }
    if( any(agentes$x < 0) ){
        agentes[which(agentes$x < 0),]$x <<- agentes[which(agentes$x < 0),]$x + l
    }
    if( any(agentes$y > l) ){
        agentes[which(agentes$y > l),]$y <<- agentes[which(agentes$y > l),]$y - l
    }
    if( any(agentes$y < 0) ){
        agentes[which(agentes$y < 0),]$y <<- agentes[which(agentes$y < 0),]$y + l
    }
}

for (tiempo in 1:tmax) {
    #print(paste("Tiempo",tiempo))
    infectados <- nrow(agentes[agentes$estado == 1,])
    epidemia <- c(epidemia, infectados)
    recuperados <- nrow(agentes[agentes$estado == 2,])
    inmunes <- c(inmunes, recuperados)
    sanos <- nrow(agentes[agentes$estado == 0,])
    saludables <- c(saludables, sanos)
    
    if (infectados == 0) {
        break
    }
    #print(agentes[1:10,])
    procesaContagio(tiempo)
    aS <- agentes[agentes$estado == 0,]
    aI <- agentes[agentes$estado == 1,]
    aR <- agentes[agentes$estado == 2,]
    if(impr){
        tl <- paste(tiempo, "", sep="")
        while (nchar(tl) < digitos) {
            tl <- paste("0", tl, sep="")
        }
        salida <- paste("p6_t", tl, ".png", sep="")
        tiempo <- paste("Paso", tiempo)
        png(salida)
        plot(l, type="n", main=tiempo, xlim=c(0, l), ylim=c(0, l), xlab="x", ylab="y")
        if (dim(aS)[1] > 0) {
            points(aS$x, aS$y, pch=15, col="chartreuse3", bg="chartreuse3")
        }
        if (dim(aI)[1] > 0) {
            points(aI$x, aI$y, pch=16, col="firebrick2", bg="firebrick2")
        }
        if (dim(aR)[1] > 0) {
            points(aR$x, aR$y, pch=17, col="goldenrod", bg="goldenrod")
        }
        graphics.off()
    }
}

print(proc.time()- inic)
png("p6e.png", width=600, height=300)
plot(1:length(epidemia), 100 * epidemia / n, pch=16 , col="firebrick2", ylim=c(0,100), xlab="Tiempo", ylab="Porcentaje")
points(1:length(inmunes), 100 *inmunes / n, pch=17, col="goldenrod")
points(1:length(saludables), 100 *saludables / n, pch=15, col="chartreuse3")
graphics.off()
