suppressMessages(library(doParallel))
suppressMessages(library(ggplot2))
library(parallel)
primo <- function(n) {
    if (n == 1 || n == 2) {
        return(TRUE)
    }
    if (n %% 2 == 0) {
        return(FALSE)
    }
    for (i in seq(3, max(3, ceiling(sqrt(n))), 2)) {
        if (n>i && (n %% i) == 0) {
            return(FALSE)
        }
    }
    return(TRUE)
}

primax= function(n)
{
    ln = rev(seq(3, n, 2))
    resu = numeric()
    for (i in ln) 
    {
        if (primo(i)) 
	{
            return(i)
        }
    }
    return(3)
}


 
desde <- 50000
hasta <-  100000
maxp = primax(desde + 2*(hasta-desde)+1)

original <- desde:hasta
invertido <- hasta:desde
pares = seq(desde, desde + 2*(hasta-desde),2)
impares = seq(desde+1, desde + 1 + 2*(hasta-desde),2)
maxprimo = rep(maxp,(hasta-desde))


mediumi = c(rbind(rep(maxp,floor((hasta-desde)/2)), rep(2,(hasta-desde)/2 ) ))
mediumi2 = c(rbind(rep(maxp,floor((hasta-desde)/4)), rep(2,(hasta-desde)/4 ),rep(maxp,floor((hasta-desde)/4)), rep(2,(hasta-desde)/4 ) ))
mediuma = c(rep(2,(hasta-desde)/2 ),rep(maxp,floor((hasta-desde)/2)))
mediumd = c(rep(maxp,floor((hasta-desde)/2)), rep(2,(hasta-desde)/2 ))
replicas <- 30
type = FALSE
cores = detectCores() - 1
name= paste(desde,"_",hasta,"R",replicas,"C",cores, sep="" )

#datos = data.frame( Tipo= character(),Nucleos= numeric(0), Time= double(0))
datos = data.frame()
for(core in 0:cores)
{
    print(core)
    pt <-  numeric()
    ot <-  numeric()
    it <-  numeric()
	#at <-  numeric()
	#xt <-  numeric()
	#hat <-  numeric()
	#hdt <-  numeric()
	#hit <-  numeric()
    if(core > 0)
    {
        if(type)
        {
            registerDoParallel(makeCluster(core))
        }
        else
        {
            cluster <- makeCluster(core)
            clusterExport(cluster, "primo")
        }
    }
    #print(paste('nucleos: ', core))
    for (r in 1:replicas)
    {
        if(core == 0)
        {
            ot <- system.time(sapply(original, primo))[3] # de menor a mayor
            it <- system.time(sapply(invertido, primo))[3] # de mayor a menor
            at <- system.time(sapply(sample(original), primo))[3] # orden aleatorio            
	    pt <- system.time(sapply(pares, primo))[3] # pares
	    mt <- system.time(sapply(impares, primo))[3] # impares
            xt <- system.time(sapply(maxprimo, primo))[3] # rep del maximoPrimo
	    hat <- system.time(sapply(mediuma, primo))[3] # mitad pares, mitad maxprimo
	    hdt <- system.time(sapply(mediumd, primo))[3] # mitad maxprimo, mitad pares
	    hit <- system.time(sapply(mediumi, primo))[3] # mitad pares, mitad maxprimo intercalados
	    het <- system.time(sapply(mediumi2, primo))[3] # mitad pares, mitad maxprimo intercalados
        }
        else
        {
            if(type)
            {
		#pt <- system.time(foreach(n = pares, .combine=c) %dopar% primo(n))[3] # de menor a mayor
		#mt <- system.time(foreach(n = impares, .combine=c) %dopar% primo(n))[3] # de menor a mayor
                ot <- system.time(foreach(n = original, .combine=c) %dopar% primo(n))[3] # de menor a mayor
                it <- system.time(foreach(n = invertido, .combine=c) %dopar% primo(n))[3] # de mayor a menor
                at <- system.time(foreach(n = sample(original), .combine=c) %dopar% primo(n))[3] # orden aleatorio
		#xt <- system.time(foreach(n = maxprimo, .combine=c) %dopar% primo(n))[3] # de menor a mayor
                #hat <- system.time(foreach(n = mediuma, .combine=c) %dopar% primo(n))[3] # mitad pares, mitad maxprimo
		#hdt <- system.time(foreach(n = mediumd, .combine=c) %dopar% primo(n))[3]# mitad pares, mitad maxprimo
		#hit <- system.time(foreach(n = mediumi, .combine=c) %dopar% primo(n))[3] # mitad pares, mitad maxprimo
            }
            else
            {
                ot = system.time(parSapply(cluster, original, primo))[3]
                it = system.time(parSapply(cluster, invertido, primo))[3]
                at = system.time(parSapply(cluster, sample(original), primo))[3]
                pt = system.time(parSapply(cluster, pares, primo))[3]
		mt = system.time(parSapply(cluster, impares, primo))[3]
		xt = system.time(parSapply(cluster, maxprimo, primo))[3]
		hat <- system.time(parSapply(cluster, mediuma, primo))[3] # mitad pares, mitad maxprimo
		hdt <- system.time(parSapply(cluster, mediumd, primo))[3]# mitad pares, mitad maxprimo
		hit <- system.time(parSapply(cluster, mediumi, primo))[3] # mitad pares, mitad maxprimo
                het <- system.time(parSapply(cluster, mediumi, primo))[3] # mitad pares, mitad maxprimo
            }
        }
        if(length(datos)==0)
        {
            datos = c('Ordenado',  core, ot)
        }
        else
        {
            datos = rbind(datos,c('Ordenado',  core, ot))
        }	    
        datos = rbind(datos,c('Reverso',   core, it))
        datos = rbind(datos,c('Aleatorio', core, at))
        datos = rbind(datos,c('Pares', core, pt))
        datos = rbind(datos,c('Impares', core, mt))
        datos = rbind(datos,c('MaxPrimo', core, xt))
        datos = rbind(datos,c('MedioIntercalado', core, hit))
        datos = rbind(datos,c('MedioAscendente', core, hat))
        datos = rbind(datos,c('MedioDescendete', core, hdt))
        datos = rbind(datos,c('MedioIntercalado2', core, het))
        print(paste('ot: ', ot, 'it: ', it,'at: ', at, 'pt: ', pt, 'mt: ', mt, 'xt: ', xt, 'hit: ', hit, 'hat: ', hat, 'hdt: ', hdt, 'het: ', het))
                                        #print(paste('hit: ', hit, 'hat: ', hat, 'hdt: ', hdt))
	}
	
	if(core > 0)
    	{
		if(type)
		{
			stopImplicitCluster()	
		}
		else
		if(!type)
		{
			stopCluster(cluster)
		}
	}
}
stopImplicitCluster()
colnames(datos)= c('Tipo', 'Nucleos', 'Time')
print(typeof(datos))
datos = as.data.frame(datos)
write.csv(datos, file=paste("datos", name, ".csv", sep=""))
#ggplot(data = datos[which(datos$Time<0.6),], aes(x=factor(Nucleos), y=Time)) + geom_boxplot(aes(fill=Tipo))
png(paste("boxplotComplete",name,".png", sep=""), width = 960, height = 960, units = "px", pointsize = 12)
ggplot(data = datos, aes(x=factor(Nucleos), y=as.numeric(paste(Time)))) + labs( x="Núcleos", y="Tiempo" ) + geom_boxplot(aes(fill=Tipo))
graphics.off()
png(paste("boxplotbyType",name,".png", sep=""), width = 960, height = 960, units = "px", pointsize = 12, bg = "white")
ggplot(data = datos, aes(x=factor(Nucleos), y=as.numeric(paste(Time)))) + labs( x="Núcleos", y="Tiempo" ) + geom_boxplot(aes(fill=Tipo)) + facet_wrap( ~ Tipo, scales="free")
graphics.off()
png(paste("boxplotbyNucleos",name,".png", sep=""), width = 960, height = 960, units = "px", pointsize = 12)
ggplot(data = datos, aes(x=factor(Nucleos), y=as.numeric(paste(Time)))) + labs( x="Núcleos", y="Tiempo" ) + geom_boxplot(aes(fill=Tipo)) + facet_wrap( ~ factor(Nucleos), scales="free")
graphics.off()


