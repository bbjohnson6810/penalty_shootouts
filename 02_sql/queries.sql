---------------------------------------------------------------------------
-- PostgreSQL queries to get summary statistics on penalty shootout data --
---------------------------------------------------------------------------

-----------------------------
--- general summary stats ---
-----------------------------

-- 1. What is the avg number of shots taken (between both teams) per match?

SELECT ROUND(AVG(total_shots),2) avg_shots
FROM (SELECT COUNT(*) total_shots
      FROM penalties
      GROUP BY match) count_shots;

-- 2. Do shootouts tend to run longer in any particular tournament?
SELECT tournament, ROUND(AVG(total_shots),2) avg_shots
FROM (SELECT tournament, match, COUNT(*) total_shots
      FROM penalties
      GROUP BY tournament, match
      ORDER BY tournament, match) count_shots
GROUP BY tournament

-- 3. How strong is home field advantage?
SELECT ROUND(COUNT(DISTINCT match) FILTER (WHERE attacker_home = 1 AND match_winner = 1) :: numeric / COUNT(DISTINCT match),3) home_win_freq
     , ROUND(COUNT(DISTINCT match) FILTER (WHERE attacker_home = 0 AND match_winner = 1) :: numeric / COUNT(DISTINCT match),3) away_win_freq
  FROM penalties
 WHERE neutral_stadium = 0

-- 4. How does home field advantage vary between tournaments?
SELECT tournament,
       COUNT(DISTINCT(match)) num_matches
     , ROUND(COUNT(DISTINCT match) FILTER (WHERE attacker_home = 1 AND match_winner = 1) :: numeric / COUNT(DISTINCT match),3) home_win_freq
     , ROUND(COUNT(DISTINCT match) FILTER (WHERE attacker_home = 0 AND match_winner = 1) :: numeric / COUNT(DISTINCT match),3) away_win_freq
  FROM penalties
 WHERE neutral_stadium = 0
 GROUP BY tournament

-- 5. How does the probability of winning differ between the first and second team?
SELECT ROUND(COUNT(DISTINCT match) FILTER (WHERE take_first = 1 AND match_winner = 1) :: numeric / COUNT(DISTINCT match),3) team1_win_freq
     , ROUND(COUNT(DISTINCT match) FILTER (WHERE take_first = 0 AND match_winner = 1) :: numeric / COUNT(DISTINCT match),3) team2_win_freq
  FROM penalties

-- 6. What proportion of shootouts make it to the 5th shot?
SELECT COUNT(DISTINCT match)
FROM (SELECT match, take_first, MAX(shot_order)
      FROM penalties
      GROUP BY match, take_first
      HAVING MAX(shot_order) >=5 
      ORDER BY match, take_first DESC) five_plus

-- 7. How often does the second team make it to the 5th shot?
SELECT COUNT(DISTINCT match)
FROM (SELECT match, take_first, MAX(shot_order)
      FROM penalties
      WHERE take_first = 0
      GROUP BY match, take_first
      HAVING MAX(shot_order) >=5 
      ORDER BY match, take_first DESC) five_plus

-- 8. Which team sees more high-stakes scenarios?
SELECT take_first 
    , SUM(must_survive + could_win) high_stakes
    , COUNT(*) - SUM(must_survive + could_win) low_stakes
    , ROUND(SUM(must_survive + could_win)::numeric / COUNT(*),3) high_freq
    , ROUND((COUNT(*) - SUM(must_survive + could_win))::numeric / COUNT(*),3) low_freq
FROM penalties
GROUP BY take_first
ORDER BY take_first DESC;


----------------------------------
--- general shot probabilities ---
----------------------------------

-- 1. What is the overall probability of scoring a penalty kick?
SELECT ROUND(AVG(goal)*100,2)
FROM penalties;

-- 2. How does scoring vary by tournament?
SELECT tournament, ROUND(AVG(goal)*100,2) score_prob
FROM penalties
GROUP BY tournament
ORDER BY score_prob DESC;

-- 2. How does scoring probability vary by take order?
SELECT ROUND(AVG(goal)*100,2)
FROM penalties
GROUP BY take_first;

-- 3. How does scoring probability vary by tournament and take order?
SELECT tournament, take_first, ROUND(AVG(goal)*100,2) score_prob
FROM penalties
GROUP BY tournament, take_first
ORDER BY tournament, take_first DESC;

-- 4. How does scoring probability vary with each shot?
SELECT COUNT(*) n, take_first, shot_order, ROUND(AVG(goal)*100,2) score_prob
FROM penalties
GROUP BY take_first, shot_order
ORDER BY shot_order, take_first DESC;

-- 5. How does scoring probability differ in a home, away, or neutral stadium?
SELECT neutral_stadium, attacker_home, ROUND(AVG(goal)*100,2) score_prob
FROM penalties
GROUP BY neutral_stadium, attacker_home;

-- 6. How does scoring probability differ between best-of-five and sudden death rounds?
SELECT sudden_death, ROUND(AVG(goal)*100,2) score_prob
FROM penalties
GROUP BY sudden_death;

-- 7. What is the probability of scoring a 'basic' shot: a best-of-five shot that has neither a win nor a loss immediately on the line?
SELECT ROUND(AVG(goal)*100,2)
FROM penalties
WHERE must_survive = 0 AND could_win = 0 AND sudden_death = 0;

-- 8. What is the probability of scoring a shot that could immediately win the match?
SELECT ROUND(AVG(goal)*100,2)
FROM penalties
WHERE could_win = 1;

-- 9. What is the probability of scoring a shot that must score to avoid an immediate loss?
SELECT ROUND(AVG(goal)*100,2)
FROM penalties
WHERE must_survive = 1;

-- 10. How does scoring probability differ between could-win scenarios in best-of-five vs. sudden death rounds?
    SELECT could_win, sudden_death, ROUND(AVG(goal)*100,2)
    FROM penalties
    WHERE must_survive = 0
    GROUP BY could_win, sudden_death
    ORDER BY could_win, sudden_death;

-- 11. How does scoring probability differ between must-survive scenarios in best-of-five vs. sudden death rounds?
SELECT must_survive, sudden_death, ROUND(AVG(goal)*100,2)
FROM penalties
GROUP BY must_survive, sudden_death
ORDER BY must_survive, sudden_death;


