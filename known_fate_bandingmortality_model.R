################### Bayesian analysis for banding mortality ###########################
# author: Cassidy Waldrep and Madeline Ward
# last updated: 9/25/2025

## packages
library(tidyverse)
library(nimble)
library(factoextra)
library(parallel)
library(nimbleHMC)
library(coda)
library(janitor)
library(MCMCvis)
library(readxl)


data_model <- read_csv("nimblemodeldata.csv")

#-------------------------------------------------------------------------#
###### BAYESIAN MODEL IN NIMBLE  ###################
#-------------------------------------------------------------------------#

## indexing --------------------------------------------------------------------

# total number of data points
nobs <- nrow(data_model)

# number of individuals in study
nind <- length(unique(data_model$bandnum_index))

# number of banders
nbander <- length(unique(data_model$bander_index))

# number of days
nday <- length(unique(data_model$day_index))

# number of state / provincial agencies
nstate <- length(unique(data_model$state_index))


# Nimble model code  ----------------------------------------------

model_code <- nimbleCode({
  
  ## priors -------------------------------------------------------------------
  
  ### Beta coefficients  ------------------------------------------------------
  
  
  for(b in 1:nbander) {
    beta_bander[b] ~ dnorm(0, sd = 1.5)
  }
  
  beta_mean_mintemp_prev5 ~ dnorm(0, sd = 1.5) 
  beta_weight ~ dnorm(0, sd = 1.5) 
  
  for(d in 1:nday) {
    beta_day[d] ~ dnorm(0, sd = 1.5)
  }
  
   
 ### Random Effects ---------------------------------------------------------

  for(s in 1:nstate) {
    eps_state[s] ~ dnorm(0, sd = sd_state)
  }
    sd_state ~ dexp(1)
  
  ## likelihoods --------------------------------------------------------------
    
  for (m in 1:nobs) {
    
    # random part 
    
    survival[m] ~ dbern(p[m])
    p[m] <- z[m]^interval[m]
    
    # link function 
    
    logit(z[m]) <- beta_bander[bander_index[m]] + 
      beta_day[day_index[m]] +
      beta_mean_mintemp_prev5*mean_mintemp_prev5[m] + 
      beta_weight*weight[m] +
      eps_state[state_index[m]]
  }
})


# set up NIMBLE model ---------------------------------------------------------

# constants
nimble_constants <- list(
  nobs = nobs,
  nday = nday,
  nbander = nbander,
  nstate = nstate,
  bander_index = data_model$bander_index,
  day_index = data_model$day_index, 
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

# configure HMC
mcmc_Conf  <- configureHMC(model, print = F)
mcmc_Conf$addMonitors(c("eps_state"))

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
