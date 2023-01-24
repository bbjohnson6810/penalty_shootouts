#!/usr/bin/env python
# coding: utf-8

# Penalty shootout data setup
# This script adds 'sudden death', 'could win', and 'must survive' data columns, tallies running scores, and identifies match winners 
# from an input csv dataframe of penalty kicks, with an updated dataframe output into a new csv file
# usage: python add_columns_to_pk_df.py [path to input csv] > [path to output csv]


# dependencies
import pandas as pd
import numpy as np
import sys


# read in the csv file
pk = pd.read_csv(sys.argv[1])

# remove rows with unknown shot values
pk = pk[pk['goal'].notna()]

# check that each shot has one recorded outcome
shot_sums = pk[['goal','missed','saved']].sum(axis=1)
check_index = shot_sums[shot_sums != 1].index.tolist()
if check_index == []:
   sys.stderr.write('All raw data are scored correctly. Processing data...')

else:
   sys.stderr.write('Check the following shots (by index), which were input incorrectly:  \n')
   sys.stderr.write(f'{check_index}')


# create a column to score whether a given shot is taken during 'sudden death' rounds
pk['sudden_death'] = np.where(pk['shot_order'] > 5, 1, 0)


# function to determine whether a given shot could win the match

def could_win(df):
    
    # subsets for each team
    team_1 = df[df['take_first'] == 1] # the team that takes first
    team_2 = df[df['take_first'] == 0] # the team that takes second

    # count how many shots were taken by each team
    team_1_shots_taken = len(team_1)
    team_2_shots_taken = len(team_2)

    # vector of goal outcomes for each team
    team_1_goals = team_1['goal'].tolist()
    team_2_goals = team_2['goal'].tolist()

    
    ## could-win rules for the team that takes first ##
    
    shots_remaining = 5   # shot counter
    team_1_could_win = [] # empty vector to fill with could-win results

    for shot, outcome in enumerate(team_1_goals, start=1):

        # best-of-five rules for the team that takes first
        if shot <= 5:

            # team 1 score before the nth shot
            team_1_goals_so_far = sum(team_1_goals[:shot-1])

            # team 2 score before the nth shot (after team 1's nth shot, before team 2's nth shot)
            team_2_goals_so_far = sum(team_2_goals[:shot-1])

            # determine if the next goal could produce an insurmountable lead
            if (team_1_goals_so_far + 1) > (team_2_goals_so_far + shots_remaining):

                team_1_could_win.append(1)

            else:

                team_1_could_win.append(0)

            # update number of remaining shots
            shots_remaining -= 1

        # sudden death rules for team 1
        else:

            # there is no circumstance in which the first team can win sudden death on their own kick
            team_1_could_win.append(0)

    ## could-win rules for the team that takes second ##

    # new shot counters: in this scenario we're counting after team 1 has already taken, 
    # so the shot counter begins at 4 remaining shots for team 1
    team_1_shots_remaining = 4   
    team_2_shots_remaining = 5
    team_2_could_win = [] # empty vector to fill with could-win results


    for shot, outcome in enumerate(team_2_goals, start=1):

        # best-of-five rules for the team that takes second
        if shot <= 5:

            # team 1 score AFTER the nth shot
            team_1_goals_so_far = sum(team_1_goals[:shot])

            # team 2 score before the nth shot (after team 1's nth shot, before team 2's nth shot)
            team_2_goals_so_far = sum(team_2_goals[:shot-1])

            # determine if the next goal could produce an insurmountable lead
            if (team_2_goals_so_far + 1) > (team_1_goals_so_far + team_1_shots_remaining):

                team_2_could_win.append(1)

            else:

                team_2_could_win.append(0)

            # update number of remaining shots
            team_1_shots_remaining -= 1
            team_2_shots_remaining -= 1

        # sudden death rules for team 2
        else:

            # if the first team misses, then the second team's shot could win the match
            if team_1_goals[shot-1] == 0:

                team_2_could_win.append(1)

            else:

                team_2_could_win.append(0)

    # concatenate could-win results for both teams
    could_win = team_1_could_win + team_2_could_win

    # save could-win results to the original dataframe
    df['could_win'] = could_win
    
    return df


# function to determine whether a given shot must be scored to survive

def must_survive(df):
    
    # subsets for each team
    team_1 = df[df['take_first'] == 1] # the team that takes first
    team_2 = df[df['take_first'] == 0] # the team that takes second

    # count how many shots were taken by each team
    team_1_shots_taken = len(team_1)
    team_2_shots_taken = len(team_2)

    # vector of goal outcomes for each team
    team_1_goals = team_1['goal'].tolist()
    team_2_goals = team_2['goal'].tolist()

    
    ## must-survive rules for the team that takes first ##
    
    shots_remaining = 5   # shot counter
    team_1_must_survive = [] # empty vector to fill with must-survive results

    for shot, outcome in enumerate(team_1_goals, start=1):

        # best-of-five rules for the team that takes first
        if shot <= 5:

            # team 1 score before the nth shot
            team_1_goals_so_far = sum(team_1_goals[:shot-1])

            # team 2 score before the nth shot (after team 1's nth shot, before team 2's nth shot)
            team_2_goals_so_far = sum(team_2_goals[:shot-1])

            # determine if the next shot must be converted to survive
            if team_1_goals_so_far + shots_remaining == team_2_goals_so_far:

                team_1_must_survive.append(1)

            else:

                team_1_must_survive.append(0)

            # update number of remaining shots
            shots_remaining -= 1

        # sudden death rules for team 1
        else:

            # there is no circumstance in which the first team can lose sudden death on their own kick
            team_1_must_survive.append(0)

    ## must-survive rules for the team that takes second ##

    # new shot counters: in this scenario we're counting after team 1 has already taken, 
    # so the shot counter begins at 4 remaining shots for team 1
    team_1_shots_remaining = 4   
    team_2_shots_remaining = 5
    team_2_must_survive = [] # empty vector to fill with could-win results


    for shot, outcome in enumerate(team_2_goals,start=1):

        # best-of-five rules for the team that takes second
        if shot <= 5:

            # team 1 score AFTER the nth shot
            team_1_goals_so_far = sum(team_1_goals[:shot])

            # team 2 score before the nth shot (after team 1's nth shot, before team 2's nth shot)
            team_2_goals_so_far = sum(team_2_goals[:shot-1])

            # determine if the next shot must be converted to survive
            if team_2_goals_so_far + team_2_shots_remaining == team_1_goals_so_far:

                team_2_must_survive.append(1)

            else:

                team_2_must_survive.append(0)

            # update number of remaining shots
            team_1_shots_remaining -= 1
            team_2_shots_remaining -= 1

        # sudden death rules for team 2
        else:

            # if the first team scores, then the second team must score to survive
            if team_1_goals[shot-1] == 1:

                team_2_must_survive.append(1)

            else:

                team_2_must_survive.append(0)

    # concatenate must-survive results for both teams
    must_survive = team_1_must_survive + team_2_must_survive

    # save must-survive results to the original dataframe
    df['must_survive'] = must_survive
    
    return df


# function to track the running score before each shot is taken

def running_score(df):
    
    team_1 = df[df['take_first'] == 1] # the team that takes first
    team_2 = df[df['take_first'] == 0] # the team that takes second

    # vector of goal outcomes for each team
    team_1_goals = team_1['goal'].tolist()
    team_2_goals = team_2['goal'].tolist()

    # lists to store running scores
    team_1_running_score = []
    team_2_running_score = []

    for shot, outcome in enumerate(team_1_goals, start=0):

        # team 1 score before the nth shot
        team_1_goals_so_far = sum(team_1_goals[:shot])
        team_1_running_score.append(team_1_goals_so_far)

    for shot, outcome in enumerate(team_2_goals, start=0):

        # team 2 score before the nth shot (after team 1's nth shot, before team 2's nth shot)
        team_2_goals_so_far = sum(team_2_goals[:shot])
        team_2_running_score.append(team_2_goals_so_far)

    df['running_score'] = team_1_running_score + team_2_running_score

    return df


# function to track the running goal difference before each shot is taken

def running_dif(df):
    
    # subsets for each team
    team_1 = df[df['take_first'] == 1] # the team that takes first
    team_2 = df[df['take_first'] == 0] # the team that takes second

    # vector of goal outcomes for each team
    team_1_goals = team_1['goal'].tolist()
    team_2_goals = team_2['goal'].tolist()

    # each team's running score
    team_1_running_score = team_1['running_score'].tolist()
    team_2_running_score = team_2['running_score'].tolist()

    # insert a phantom 0 into team 2's running score to align with team 1's perspective
    #team_2_running_score = [0] + team_2_running_score[:-1]

    # lists to hold running differences
    team_1_running_dif = []
    team_2_running_dif = []

    ## current score before team 1's nth shot ##

    # team 1's running score before team 1's nth shot
    team_1_running_score = team_1['running_score'].tolist()

    # team 2's running score from team 1's perspective (before team 1's nth shot)
    team_2_running_score = [0] # start score at 0 to align with team 1's first shot

    for shot, outcome in enumerate(team_2_goals, start=1):

        # team 2 score before team 1's nth shot (after team 2's n-1'th shot)
        team_2_goals_so_far = sum(team_2_goals[:shot])
        team_2_running_score.append(team_2_goals_so_far)

    for shot, current_score in enumerate(team_1_running_score, start=0):

        team_1_current_dif = team_1_running_score[shot] - team_2_running_score[shot]
        team_1_running_dif.append(team_1_current_dif)

        
    ## current score before team 2's nth shot ##

    # team 1's running score from team 2's perspective (after team 1's nth shot, before team 2's nth shot)
    team_1_running_score = []

    team_2_running_score = team_2['running_score'].tolist()

    for shot, outcome in enumerate(team_1_goals, start=1):

        # team 1 score before team 2's nth shot (after team 1's n'th shot)
        team_1_goals_so_far = sum(team_1_goals[:shot])
        team_1_running_score.append(team_1_goals_so_far)

    # team 2's running score from team 2's perspective (before team 2's nth shot)
    for shot, outcome in enumerate(team_2_running_score, start=0):

        # team 2 score before the nth shot (after team 1's nth shot, before team 2's nth shot)
        team_2_current_dif = team_2_running_score[shot] - team_1_running_score[shot]
        team_2_running_dif.append(team_2_current_dif)
    
    df['running_dif'] = team_1_running_dif + team_2_running_dif

    return df    


# function to determine the winner of each match

def winner(df):
    
    # subsets for each team
    team_1 = df[df['take_first'] == 1] # the team that takes first
    team_2 = df[df['take_first'] == 0] # the team that takes second

    # each team's total score
    team_1_score = sum(team_1['goal'])
    team_2_score = sum(team_2['goal'])
    
    # define the match winner and loser
    df['match_winner'] = np.where(team_1_score > team_2_score,
                        [1]*len(team_1) + [0]*len(team_2),
                        [0]*len(team_1) + [1]*len(team_2))
    
    return df


# apply the above functions to each match
pk = pk.groupby('match', as_index = False).apply(could_win)
pk = pk.groupby('match', as_index = False).apply(must_survive)
pk = pk.groupby('match', as_index = False).apply(running_score)
pk = pk.groupby('match', as_index = False).apply(running_dif)
pk = pk.groupby('match', as_index = False).apply(winner)

# rearrange columns
cols = pk.columns.tolist()
new_cols = cols[1:15] + cols[19:len(cols)+1] + cols[15:19]
pk = pk[new_cols]

# Output the dataframe to file
pk.to_csv(sys.stdout, index=True, index_label='shot')