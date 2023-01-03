CREATE TABLE penalties (
    index INT,
    match INT,
    tournament VARCHAR(3),
    year INT,
    round VARCHAR(8),
    attacker_team VARCHAR(50),
    gk_team VARCHAR(50),
    attacker VARCHAR(50),
    goalkeeper VARCHAR(50),
    goal SMALLINT,
    missed SMALLINT,
    saved SMALLINT,
    shot_order SMALLINT,
    take_first SMALLINT,
    FT_tie SMALLINT,
    neutral_stadium SMALLINT,
    attacker_home SMALLINT,
    sudden_death SMALLINT,
    could_win SMALLINT,
    must_survive SMALLINT,
    match_winner SMALLINT,
    UNIQUE (index),
    PRIMARY KEY (index)
);


-- upload using psql
-- execute the following on one line in pgAdmin:
-- \copy penalties (index, match, tournament, year, round, attacker_team, gk_team, attacker, goalkeeper, goal, missed, saved, shot_order, take_first, FT_tie, neutral_stadium, attacker_home, sudden_death, could_win, must_survive, match_winner) 
-- FROM '/Users/macondo/Documents/datasci_projects/pk_shootouts/penalty_shootouts/00_data/02_processed/pks.csv'
-- WITH (FORMAT CSV, DELIMITER ',', HEADER);


\copy penalties (index, match, tournament, year, round, attacker_team, gk_team, attacker, goalkeeper, goal, missed, saved, shot_order, take_first, FT_tie, neutral_stadium, attacker_home, sudden_death, could_win, must_survive, match_winner) FROM '/Users/macondo/Documents/datasci_projects/pk_shootouts/penalty_shootouts/00_data/02_processed/pks.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);
