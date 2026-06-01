################### Short term survival known fate model ###########################
# author: Cassidy Waldrep and Madeline Ward
# last updated: 4/20/2026

## packages
library(tidyverse)
library(nimble)
library(nimbleHMC)
library(coda)

data_model <- read_csv("nimblemodeldata_apr2026.csv") 

#-------------------------------------------------------------------------#
###### BAYESIAN MODEL IN NIMBLE  ###################
#-------------------------------------------------------------------------#

## indexing --------------------------------------------------------------------

# total number of data points
nobs <- nrow(data_model)

# number of individuals in study
nind <- length(unique(data_model$bandnum_index))

# number of years in study
# nyear <- length(unique(data_model$year))

# number of banders
nbander <- length(unique(data_model$bander_name))

# number of days
nday <- length(unique(data_model$day_index))

# number of state / provincial agences

nstate <- length(unique(data_model$state_index))

nage <- length(unique(data_model$age_index))

data_model$bander_index_new <- data_model$bander_index

# these can be manipulated to specifically code one of the banders to be the reference category

data_model$bander_index_new[data_model$bander_index == 26] <- 54
data_model$bander_index_new[data_model$bander_index == 54] <- 26

# specify GLMMs in BUGS language ----------------------------------------------

model_code <- nimbleCode({
  
  ## priors -------------------------------------------------------------------
  
  ### Beta coefficients  ------------------------------------------------------
  
  
  for(b in 1:(nbander - 1)) { # Leave out last bander
    beta_bander_tmp[b] ~ dnorm(0, sd = 1.5)
  }
  beta_bander_tmp[nbander] <- - sum(beta_bander_tmp[1:(nbander - 1)]) 
  
  for(b in 1:nbander) {
    beta_bander[b] <- beta_bander_tmp[b]
  }
  
  for(d in 1:(nday-1)) {
    beta_day_tmp[d] ~ dnorm(0, sd = 1.5)
  }
  beta_day_tmp[nday] <- -sum(beta_day_tmp[1:(nday - 1)])
  
  for(d in 1:nday) {
    beta_day[d] <- beta_day_tmp[d]
  }
  
  alpha ~ dnorm(5, sd = 2) # Intercept term - overall mean logit(survival)
  beta_mean_mintemp_prev5 ~ dnorm(0, sd = 1.5) 
  beta_weight ~ dnorm(0, sd = 1.5) 
  beta_age[1] ~ dnorm(0, sd = 1.5) 
  beta_age[2] <- - beta_age[1]

  # ### Random Effects ---------------------------------------------------------

  for(s in 1:nstate) {
    eps_state[s] ~ dnorm(0, sd = sd_state)
  }
  
  # mu_state ~ dnorm(0, sd = 1.5)
  sd_state ~ dexp(1)
  
  ## likelihoods --------------------------------------------------------------
  
  for (m in 1:nobs) {
    
    # random part 
    
    survival[m] ~ dbern(p[m])
    p[m] <- z[m]^interval[m]
    
    # link function 
    
    logit(z[m]) <- alpha + beta_bander[bander_index[m]] + 
      beta_day[day_index[m]] +
      beta_mean_mintemp_prev5*mean_mintemp_prev5[m] + 
      beta_weight*weight[m] +
      beta_age[age_cat[m]] +
      eps_state[state_index[m]]
  }
})


# set up NIMBLE model ---------------------------------------------------------

# initial values

nimble_inits <- function(){
  bander_inits <- rnorm(nbander - 1, 0, 1)
  day_inits <- rnorm(nday - 1, 0, 1)
  age_inits <- rnorm(1, 0, 1)
  list(beta_bander_tmp = c(bander_inits, -sum(bander_inits)),
       beta_day_tmp = c(day_inits, -sum(day_inits)),
       beta_age = c(age_inits, -age_inits),
       beta_mean_mintemp_prev5 = rnorm(1, 0, 1),
       beta_weight = rnorm(1, 0, 1),
       sd_state = runif(1, 0.01, 0.4),
       alpha = rnorm(1, 5, 1))
}

# constants
nimble_constants <- list(
  nobs = nobs,
  nday = nday,
  nbander = nbander,
  nstate = nstate,
  bander_index = data_model$bander_index_new,
  day_index = data_model$day_index, 
  age_cat = data_model$age_index,
  state_index = data_model$state_index,
  interval = data_model$interval,
  mean_mintemp_prev5 = as.numeric(data_model$mean_mintemp_prev5_scaled),
  weight = as.numeric(data_model$PCA_weight_scaled)
)

# data
nimble_data <- list(
  survival = data_model$survived
)

# run NIMBLE model in series ---------------------------
nc <- 3

# build model
model <- nimbleModel(code = model_code, 
                     constants = nimble_constants,  
                     data =  nimble_data, 
                     buildDerivs = T)

# configure MCMC
mcmc_Conf  <- configureHMC(model, print = F)
mcmc_Conf$setMonitors(c("alpha", "beta_age", "beta_bander", "beta_day", "beta_mean_mintemp_prev5", "beta_weight", "eps_state", "sd_state"))

# build MCMC
modelMCMC  <- buildMCMC(mcmc_Conf)

# compile model and MCMC
Cmodel     <- compileNimble(model)
CmodelMCMC <- compileNimble(modelMCMC, project = model)

# run model
samples <- runMCMC(CmodelMCMC,
                   niter = 10000,
                   nburnin = 2000,
                   thin = 10,
                   nchains = nc,
                   samplesAsCodaMCMC = T)