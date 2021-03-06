library(parallel)
library(lattice) # lo mismo aplica con este paquete
library(reshape2) # recuerda instalar paquetes antes de intentar su uso
g <- function(x, y) { 
    return((((x + 0.5)^4 - 30 * x^2 - 20 * x + (y + 0.5)^4 - 30 * y^2 - 20 * y) ) )
}

bval = -g(5,5)
localsearch <- function(nr){
    #x <- runif(2, low, high)
    #y <- runif(1, low, high)
    ti <- Temp
    cpos <- runif(2, low, high)
    bestpos <- cpos
    bestval <- -g(cpos[1], cpos[2])
    tray = c(nr, 0, cpos,bestval, 0)
    tb= 0
    for (tiempo in 1:tmax) {
        d <- runif(1, 0, step)
        op = rbind(c(max(cpos[1] - d, low), cpos[2]),
                   c( min(cpos[1] + d, high), cpos[2]),
                   c(cpos[1], max(cpos[2] - d, low)),
                   c(cpos[1], min(cpos[2] + d,high))
                   ,c(min(cpos[1] + d, high), min(cpos[2] + d, high))
                   ,c(max(cpos[1] - d, low), min(cpos[2] + d, high))
                   ,c(max(cpos[1] - d, low),max(cpos[2] - d, low))
                   ,c(min(cpos[1] + d, high),max(cpos[2] - d, low))
                   )
        posibles = -g(op[,1], op[,2])
        #npos = which( posibles == min(posibles) )
        npos = sample(1:nrow(op), 1)
        nuevo = posibles[npos]
        delta = bestval - nuevo
        if (delta > 0)
        { # minimizamos
            bestpos <- op[npos,]
            cpos <- bestpos
            bestval <- nuevo
            tb = tiempo
        }
        else
        {            
            if(runif(1) < exp(delta/ti))
            {
                ti = ti * epsi
                cpos <- op[npos,]
            }
        }        
        tray <- c(tray, c(nr , tiempo , cpos,  bestval,tb) )
    }
    return (tray)
}


rep = 100
low <- -6
high <- 5
tmax <- 100
step <- 0.3
Temp = 90
epsi = 1 - 0.1
#print(Temp)
#trayectoria <<- data.frame(rep, sec, xr, yr , zr)
v <- seq(low, high, abs(high-low)/500)
w <-  v
#z <- outer(v, w, g)
z= outer(v,w,function(q,r){g(q,r)})
dimnames(z) <- list(v, w)
d <- melt(z)
names(d) <- c("v", "w", "z")
nombr = c("rep","paso","x","y","z","tb")
cluster = makeCluster(detectCores(logical=FALSE))
clusterExport(cluster, "low")
clusterExport(cluster, "high")
clusterExport(cluster, "tmax")
clusterExport(cluster, "step")
clusterExport(cluster, "g")
clusterExport(cluster, "Temp")
clusterExport(cluster, "epsi")
rs = data.frame(t(matrix(parSapply(cluster, 1:rep, localsearch), nrow=length(nombr))))
#rs = parSapply(cluster, 1:rep, localsearch)
colnames(rs) = nombr

alp= aggregate(rs$tb, by=list(rep=rs$rep), FUN=max)

#alp= rs[ rs$paso== tmax,]
#bs = rs[bp,]
bpp = min(rs[rs$z==min(rs$z),]$rep)
bp = rs[rs$rep== bpp,]



titl = paste("Gráfica de superficie Míninmo en g(",bp[bp$paso==tmax,]$x,", ", bp[bp$paso==tmax,]$y,") = ", round(bp[bp$paso==tmax,]$z,2)," Separación: ", round((bval- bp[bp$paso==tmax,]$z)/bval*100,2), "% Iteraciones ", bp[bp$paso==tmax,]$tb ,sep="")
png("p7_Tarea_1_E2.png", width=1000, height=1000)
levelplot(z~ v * w , data = d,  xlab = list(label="Coordenada X", cex=2), ylab = list(label="Coordenada Y", cex=2), main=list(label=titl, cex=2), col.regions=rev(cm.colors(100)), scales=list(x=list(cex=2),y=list(cex=2)), colorkey=list(labels=list(cex=2)) )
trellis.focus("panel", 1, 1, highlight=FALSE)
if(rep>=10)
{
    mues = sample(1:rep, round(log(rep,2)))
} else
{
    mues = 1:rep
}
#lpoints(x=lp$x, y = lp$y, pch=17, col=8)
for(re in mues)
{
    ax = rs[rs$rep == re,]
    mb = max(ax$tb)
    llines(x=ax$x, y = ax$y, pch=16, col=2)
    lpoints(x=ax[ax$paso==0,]$x, y = ax[ax$paso==0,]$y, pch=18, cex=2, col=2)
}

lpoints(x=bp[bp$paso==0,]$x, y = bp[bp$paso==0,]$y, pch=18, col=4, cex=2)
llines(x=bp$x, y = bp$y, pch=16, col=4)
for(re in 1:rep){
    lpoints(x = rs[rs$rep ==alp[alp$rep==re,]$rep & rs$paso==alp[alp$rep==re,]$x,]$x, y = rs[rs$rep ==alp[alp$rep==re,]$rep & rs$paso==alp[alp$rep==re,]$x,]$y, pch=16, col=3, cex=2)

}
trellis.unfocus()
graphics.off()
stopCluster(cluster)
