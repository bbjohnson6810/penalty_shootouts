# dependencies


# read in data
pk<-read.csv("~/Documents/datasci_projects/pk_shootouts/penalty_shootouts/00_data/02_processed/pks.csv",header=T)
pk<-pk[pk$shot_order<=9,]
pk$take_first <- as.factor(pk$take_first)
pk$shot_order <- as.factor(pk$shot_order)
# Bayesian model to summarize shot probabilities

shootout_model <- function(data = c(), # input: a vector of successes/failures (1s and 0s)
                           beta_params = c(1, 1), # shape parameters for the prior probability beta distribution (1,1 = flat prior)
                           n_draws = 10000, # sets the number of random samples for the posterior distribution
                           show_plot = F) # optional plot of the model's progress - gets messy with large inputs (>~20)
{
  # convert input data to true/false
  data <- as.logical(data)
  
  # vector of 1% quantiles, used to setup the beta distribution
  proportion_success <- seq(0, 1, length.out = 101)
  
  # data indices to plot, deliberately maxed out at sampling 12 data elements to avoid messy figures
  data_indices <- round(seq(0, length(data), length.out = min(length(data) + 1, 12)))
  
  # apply a function to each shot (each element of 'data')
  post_curves <- map_dfr(data_indices, function(i) {
    
    # assign labels to each plotted shot
    value <- ifelse(i == 0, "Prior", ifelse(data[i], "Goal", "No Goal"))
    label <- paste0("n = ", i)
    
    # model a probability density function for each iteration through the data to the i'th shot
    probability <- dbeta(proportion_success, beta_params[1] + 
                           sum(data[seq_len(i)]), beta_params[2] + sum(!data[seq_len(i)]))
    probability <- probability/max(probability)
    
    # save probabilities to a dataframe
    tibble(value, label, proportion_success, probability)
  })
  
  # set graph labels
  post_curves$label <- fct_rev(factor(post_curves$label, levels = paste0("n = ", data_indices)))
  
  # set graph values
  post_curves$value <- factor(post_curves$value, levels = c("Prior", "Goal", "No Goal"))
  
  # plot density curves for the first 20 data points
  p <- ggplot(post_curves, aes(x = proportion_success, y = label, height = probability, fill = value)) + 
    geom_joy(stat = "identity", color = "white", alpha = 0.8, panel_scaling = TRUE, size = 1) + 
    scale_y_discrete("", expand = c(0.01, 0)) + scale_x_continuous("Probability of scoring") + 
    scale_fill_manual(values = hcl(120 * 2:0 + 15, 100, 65), name = "", drop = FALSE, 
                      labels = c("Prior   ", "Goal   ", "No Goal   ")) + theme_light(base_size = 18) + 
    theme(legend.position = "top")
  
  if (show_plot) {
    print(p)
  }
  
  # return a random sample
  invisible(rbeta(n_draws, beta_params[1] + sum(data), beta_params[2] + sum(!data)))
}

shootout_model(data = c(1,0,1,0,1))

t1<-shootout_model(data=pk$goal)


get_priors <- function(data = c(), # input: a vector of successes/failures (1s and 0s)
                       beta_params = c(1, 1), # shape parameters for the prior probability beta distribution (1,1 = flat prior)
                       n_draws = 10000) # sets the number of random samples for the posterior distribution
{
  # convert input data to true/false
  data <- as.logical(data)

  # return a random sample from the posterior distribution shaped by the data
  invisible(rbeta(n_draws, beta_params[1] + sum(data), beta_params[2] + sum(!data)))
}

goal_prior <- get_priors(pk$goal)
miss_prior <- get_priors(pk$miss)
save_prior <- get_priors(pk$save)

rbinom(n=100, size=1, prob = median(goal_prior))

# add a prior probability
# assume a goal is more likely to be scored than not
# without further info, assume it's equally likely a goal will be scored between 50-100% of the time

goal_prob <- runif(n = 10000, min = 0.5, max = 1)
n_goals <- rbinom(n = 10000, size = 1, prob = goal_prob)

prior_df <- data.frame(goal_prob, n_goals)

p = ggplot(prior_df, aes(n_goals, goal_prob)) + geom_point(alpha=0.3)
ggMarginal(p, type = "histogram")

# update the model with data
mean(pk$goal) # 0.723

posterior_df <- prior_df[prior_df$goal_prob > 0.672 & prior_df$goal_prob < 0.772,]
hist(posterior_df$n_goals)

hist(rbinom(nrow(posterior_df), size = 1, prob =  posterior_df$goal_prob))


team_1<-pk[pk$take_first==1,]
team_2<-pk[pk$take_first==0,]
by(pk[pk$take_first==1,],pk[pk$take_first==1,]$shot_order,mean)

team_1_probs <- tapply(team_1$goal,team_1$shot_order,mean)
names(team_1_probs) <- paste0("team_1_", 1:9)
team_2_probs <- tapply(team_2$goal,team_2$shot_order,mean)
names(team_2_probs) <- paste0("team_2_", 1:9)

# Bayes' Theorem
# input: 
bayes_th <- function(pA,   # p(A): probability of the event of interest
                      pB,  # p(B): probability of conditional event
                      pBA) # p(A*B): probability of B given A
  {
  pAB <- pA * pBA / pB
  return(pAB) # returns the probability of A given B
}

table(team_1[team_1$shot_order==1,]$goal,team_2[team_2$shot_order==1,]$goal)[1,2] 

# calculate empirical frequencies of goals conditional on prior shots
# for example: 'what is the prob of the 2nd team scoring given the first team scored the opening shot?'
whatif_goal <- function(team_of_interest, # take order (1 or 2) of the team taking the shot of interest
                        shot_of_interest, # shot order of the shot of interest
                        conditional_team, # take order of the team taking the conditional shot
                        conditional_shot) # shot order of the conditional shot

{
  # subset the data to focus on the team/shot of interest
  if (team_of_interest == 1){
    shot_2 <- team_1[team_1$shot_order == shot_of_interest,]$goal
  } else if (team_of_interest == 2){
    shot_2 <- team_2[team_2$shot_order == shot_of_interest,]$goal
  }
  
  # subset the data to focus on the conditional team/shot
  if (conditional_team == 1){
    shot_1 <- team_1[team_1$shot_order == conditional_shot,]$goal
  } else if (conditional_team == 2){
    shot_1 <- team_2[team_2$shot_order == conditional_shot,]$goal
  }
  
  # create a contingency table
  x_tab <- proportions(table(shot_1, shot_2), margin = 1)
  print(x_tab)
  
  # return a vector of empirical frequencies for each combination of outcomes
  goal_freqs <- x_tab[4:1]
  
  # assign names to each frequency (here using 'miss' to cover non-goals: both misses and saves)
  names(goal_freqs) <- c('P(goal|goal)', 'P(goal|miss)', 'P(miss|goal)', 'P(miss|miss)')
  invisible(goal_freqs)
}

xx<-whatif_goal(1,2,1,1); xx
