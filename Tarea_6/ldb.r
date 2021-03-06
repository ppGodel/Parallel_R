puntos = 20
n = 1.5
umbral = 0.2
prob = sample(c(0,1),n,TRUE,c(0.5,0.5))
datos = data.frame(x=runif(puntos,0,n),y=runif(puntos,0,n), estado=sample(c(0,1),puntos,TRUE,c(0.8,0.2)))
ordatos = datos[order(datos$x),]
print(ordatos)
salida <- paste("p6_t", "A", ".png", sep="")
tiempo <- paste("Paso", "A")
png(salida)
plot(n, type="n", main=tiempo, xlim=c(0, n), ylim=c(0, n), xlab="x", ylab="y")

aS =ordatos[ordatos$estado == 0,]
aI =ordatos[ordatos$estado == 1,]
#aR =ordatos[ordatos$estado == 1,]
if (nrow(aS) > 0) {
    points(aS$x, aS$y, pch=15, col="chartreuse3", bg="chartreuse3")
}
if (nrow(aI) > 0) {
    points(aI$x, aI$y, pch=16, col="firebrick2", bg="firebrick2")
}
#if (nrow(aR) > 0) {
#    points(aR$x, aR$y, pch=17, col="goldenrod", bg="goldenrod")
#}
graphics.off()
cercanos= data.frame(i=numeric(),x=numeric(),y=numeric(), estado=numeric())
for(i in 1:puntos){
    ap = cbind(i,ordatos[i,])
    if(nrow(cercanos) > 0){
        cercanos= cercanos[which(cercanos$x>(ap$x-umbral)),]
        d = sqrt((rep(ap$x, nrow(cercanos))-cercanos$x)**2)+((rep(ap$y,nrow(cercanos))-cercanos$y)**2)
        if(length(which(d<umbral)) > 0){
            li = cercanos[which(d<umbral),]            
            if(ap$estado == 1){
                if( length(which(li$estado==0))  > 0){
                    aux = li[which(li$estado == 0),]
                    ordatos[aux$i,]$estado = 0.5
                }
            }
            if(ap$estado == 0) {
                if( length(which(li$estado==1))  >0){
                    ordatos[ap$i,]$estado = 2
                }
            }
        }
        
        
    }
    cercanos = rbind(cercanos,ap)
}

salida <- paste("p6_t", "F", ".png", sep="")
tiempo <- paste("Paso", "F")
png(salida)
plot(n, type="n", main=tiempo, xlim=c(0, n), ylim=c(0, n), xlab="x", ylab="y")

aS =ordatos[ordatos$estado == 0,]
aI =ordatos[ordatos$estado == 1,]
aR =ordatos[ordatos$estado == 0.5,]
aV =ordatos[ordatos$estado == 2,]
if (nrow(aS) > 0) {
    points(aS$x, aS$y, pch=15, col="chartreuse3", bg="chartreuse3")
}
if (nrow(aI) > 0) {
    points(aI$x, aI$y, pch=16, col="firebrick2", bg="firebrick2")
}
if (nrow(aR) > 0) {
    points(aR$x, aR$y, pch=17, col="goldenrod", bg="goldenrod")
}
if (nrow(aV) > 0) {
    points(aV$x, aV$y, pch=18, col="blue", bg="blue")
}
graphics.off()
print(ordatos)
