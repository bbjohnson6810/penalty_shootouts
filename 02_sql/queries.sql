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
       COUNT(DISTINCT(match)) num_matches,
       ROUND(COUNT(DISTINCT match) FILTER (WHERE attacker_home = 1 AND match_winner = 1) :: numeric / COUNT(DISTINCT match),3) home_win_freq
     , ROUND(COUNT(DISTINCT match) FILTER (WHERE attacker_home = 0 AND match_winner = 1) :: numeric / COUNT(DISTINCT match),3) away_win_freq
  FROM penalties
 WHERE neutral_stadium = 0
 GROUP BY tournament

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

-- 4. How does scoring probability differ in a home, away, or neutral stadium?
SELECT neutral_stadium, attacker_home, ROUND(AVG(goal)*100,2) score_prob
FROM penalties
GROUP BY neutral_stadium, attacker_home;

-- 5. How does scoring probability differ between best-of-five and sudden death rounds?
SELECT sudden_death, ROUND(AVG(goal)*100,2) score_prob
FROM penalties
GROUP BY sudden_death;