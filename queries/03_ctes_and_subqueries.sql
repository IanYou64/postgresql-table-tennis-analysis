-- 1. How does the upset rate vary across tournament levels — and which tournament produces the most upsets?
	WITH match_ratings AS (																		    -- CTE 1 used to flag upsets and handle JOINing
		SELECT m.match_id, m.tournament, m.winner_id, m.loser_id, 
			   gi_winner.rating AS winner_rating, gi_loser.rating AS loser_rating, 
			   (CASE WHEN gi_winner.rating < gi_loser.rating THEN 1 ELSE 0 END) AS is_upset		-- CASE adds 1 if the match is an upset and 0 if it isn't
		FROM matches m
		JOIN gen_info gi_winner
			ON m.winner_id = gi_winner.player_id
		JOIN gen_info gi_loser
			ON m.loser_id = gi_loser.player_id
	), 
	
	tournament_upset_rates AS (									-- CTE 2 used to cleanly calculate stats before getting to main query
		SELECT tournament,
			   COUNT(*) AS total_matches,
			   SUM(is_upset) AS total_upsets,								              -- Use SUM() to add all the 1s found in the first CTE's CASE clause
			   ROUND(100.0 * SUM(is_upset) / COUNT(*), 2) AS upset_rate		-- COUNT() includes all non-NULL values of is_upset, which is always either 0 or 1,
		FROM match_ratings													                    -- meaning it would have been the same as total_matches
		GROUP BY tournament
	)

	SELECT tournament, total_upsets, total_matches, upset_rate
	FROM tournament_upset_rates
	ORDER BY upset_rate DESC;

-- 2. Which career year brackets win their matches most convincingly on average?
	WITH player_stats AS (
		SELECT gi.player_id, gi.name, gi.career_years, 
			CASE													                    -- Groups players by career_year
				WHEN career_years BETWEEN 0 AND 4 	THEN '0-4'
				WHEN career_years BETWEEN 5 AND 9 	THEN '5-9'
				WHEN career_years BETWEEN 10 AND 14 THEN '10-14'
				ELSE '15+' END AS career_year_bracket,
			COUNT(*) FILTER (WHERE m.winner_id = gi.player_id) AS is_wins,		-- Same format as Window Functions, Query 2
			ROUND(AVG(m.winner_sets - m.loser_sets) FILTER (WHERE m.winner_id = gi.player_id), 3) AS avg_set_diff
		FROM gen_info gi
		JOIN matches m
			ON m.winner_id = gi.player_id OR m.loser_id = gi.player_id
		GROUP BY gi.player_id, gi.name, gi.career_years
	)
	
	SELECT career_year_bracket, 
		   COUNT(*) AS player_count,
		   SUM(is_wins) AS total_wins,
		   ROUND(AVG(avg_set_diff), 3) AS bracket_avg_set_diff, 
		   ROUND((SELECT AVG(avg_set_diff) FROM player_stats), 3) AS global_avg_set_diff	-- Included this subquery for viewers' quick comparisons between
	FROM player_stats																		                                -- bracket_avg_set_diff and this
	GROUP BY career_year_bracket
	ORDER BY bracket_avg_set_diff DESC; 

-- 3. Which combination of playstyle, grip, and hand produces the highest win rate?
	SELECT playstyle, grip, hand,
		   COUNT(*) AS player_count,
		   ROUND(AVG(win_rate), 2) AS avg_win_rate
	FROM (													                -- Used derived table as an alternative to CTE since this subquery is a SINGLE-USE stepping stone
		SELECT player_id, playstyle, grip, hand,		 	-- (a CTE would do the same thing)
			   ROUND(COUNT(*) FILTER (WHERE m.winner_id = gi.player_id)*100.0 / COUNT(*), 2) AS win_rate
		FROM gen_info gi
		JOIN matches m
			ON gi.player_id = m.winner_id OR gi.player_id = m.loser_id
		JOIN preferences p
			USING(player_id)
		GROUP BY gi.player_id, p.playstyle, p.grip, p.hand
	) AS player_stats
	GROUP BY playstyle, grip, hand
	ORDER BY avg_win_rate DESC;

-- 4. For each rubber, how many rubbers of the same type are faster but less controlled, and how many are harder but spinnier?
	SELECT r1.name, r1.type,
		   (SELECT COUNT(*) FROM rubber_info r2			-- Used to see whether faster rubbers of the same type sacrifice control
		   	WHERE r2.TYPE = r1.TYPE AND r2.speed > r1.speed AND r2.CONTROL < r1.CONTROL) AS faster_and_less_controlled, 
		   (SELECT COUNT(*) FROM rubber_info r3			-- Used to see whether harder rubbers of the same type generates more spin
		    WHERE r3.TYPE = r1.TYPE AND r3.sponge_hardness > r1.sponge_hardness AND r3.spin > r1.spin) AS harder_and_spinnier
	FROM rubber_info r1
	ORDER BY type, harder_and_spinnier, faster_and_less_controlled;

-- 5. For each blade, how many blades of the same playstyle are stiffer but less controlled, and how many blades of the same composition are more consistent?
	SELECT b1.name, b1.playstyle, b1.composition, 
		   (SELECT COUNT(*) FROM blade_info b2
		   	WHERE b2.playstyle = b1.playstyle AND b2.stiffness > b1.stiffness AND b2.control < b1.control) AS stiffer_and_less_controlled, 
		   (SELECT COUNT(*) FROM blade_info b3
		    WHERE b3.composition = b1.composition AND b3.consistency > b1.consistency) AS same_composition_and_more_consistent
	FROM blade_info b1
	ORDER BY playstyle, composition, stiffer_and_less_controlled, same_composition_and_more_consistent;
