-- 1. Rank players within each country by win rate (compare RANK() and DENSE_RANK())
	WITH player_win_rates AS (																				-- Using CTE to pre-calculate win rates since PostgreSQL 
		SELECT gi.country, gi.name, 																		-- doesn't allow aggregate functions in OVER() clauses
			   ROUND(COUNT(*) FILTER (WHERE m.winner_id = gi.player_id) * 100.0 / COUNT(*), 2) AS win_rate
		FROM gen_info gi
		JOIN matches m
			ON gi.player_id = m.winner_id OR gi.player_id = m.loser_id
		GROUP BY gi.player_id, gi.country, gi.name
	)

	SELECT country, name, win_rate, 
		   RANK() OVER (
		   		PARTITION BY country
		   		ORDER BY win_rate DESC
		   ) AS rank_win_rate,
		   DENSE_RANK() OVER (
		   		PARTITION BY country
		   		ORDER BY win_rate DESC
		   ) AS dense_rank_win_rate
	FROM player_win_rates
	ORDER BY country, rank_win_rate;
	
-- 2. Compare each player's win rate against opponents rated below them vs. opponents rated above them (at least 16 matches to be eligible)
	WITH player_match_stats AS (
		SELECT gi.name, gi.rating, 
		   COUNT(*) FILTER (WHERE m.winner_id = gi.player_id AND gi.rating > opponent.rating) AS wins_vs_lower,
		   COUNT(*) FILTER (WHERE m.winner_id = gi.player_id AND gi.rating > opponent.rating) + 
		   		COUNT(*) FILTER (WHERE m.loser_id = gi.player_id AND gi.rating > opponent.rating) AS total_vs_lower,
		   ROUND(COUNT(*) FILTER (WHERE m.winner_id = gi.player_id AND gi.rating > opponent.rating) * 100.0 / 					      	-- Calculating win rate against 
		   		NULLIF (															                                                    -- players who are rated lower;
		   			COUNT(*) FILTER (WHERE m.winner_id = gi.player_id AND gi.rating > opponent.rating) + 							    -- NULLIF used so that if there
		   			COUNT(*) FILTER (WHERE m.loser_id = gi.player_id AND gi.rating > opponent.rating), 0), 2) AS win_rate_vs_lower, 	-- are no matches against people
		   COUNT(*) FILTER (WHERE m.winner_id = gi.player_id AND gi.rating < opponent.rating) AS wins_vs_higher,				      	-- rated lower/higher, there
		   COUNT(*) FILTER (WHERE m.winner_id = gi.player_id AND gi.rating < opponent.rating) + 									    -- isn't a divide by 0 error
		   		COUNT(*) FILTER (WHERE m.loser_id = gi.player_id AND gi.rating < opponent.rating) AS total_vs_higher,
		   ROUND(COUNT(*) FILTER (WHERE m.winner_id = gi.player_id AND gi.rating < opponent.rating) * 100.0 / 						-- Calculating win rate against
		   		NULLIF (																                                            -- players who are rated higher
		   			COUNT(*) FILTER (WHERE m.winner_id = gi.player_id AND gi.rating < opponent.rating) + 
		   			COUNT(*) FILTER (WHERE m.loser_id = gi.player_id AND gi.rating < opponent.rating), 0), 2) AS win_rate_vs_higher
		   			
		FROM gen_info gi
		JOIN matches m
			ON gi.player_id = m.winner_id OR gi.player_id = m.loser_id
		JOIN gen_info opponent								   		-- Self JOIN used to access both the winner's and loser's ratings in the same row
    		ON opponent.player_id = (CASE							-- CASE dynamically determines the opponent's player_id for each match:
    	    	WHEN m.winner_id = gi.player_id THEN m.loser_id			-- If our current player won, then our opponent is the loser
    	    	ELSE m.winner_id								  	 	-- If our current player lost, then our opponent is the winner
 		 	END)
  	  	GROUP BY gi.player_id, gi.name, gi.rating
		HAVING COUNT(*) >= 16
	)
	
	SELECT name, rating, wins_vs_lower, total_vs_lower, win_rate_vs_lower, wins_vs_higher, total_vs_higher, win_rate_vs_higher
	FROM player_match_stats
	ORDER BY rating DESC;
	
-- 3. What percentile of the rating distribution does each player fall into within their playstyle?
	SELECT gi.name, p.playstyle, gi.rating, 
		   ROUND((1 - PERCENT_RANK() OVER (												    -- "1 - PERCENT_RANK()" inverts scale: top players score near 100 instead of 0
		   		PARTITION BY p.playstyle									             	-- ::numeric casting is necessary because PERCENT_RANK() returns double
		   		ORDER BY rating DESC))::numeric * 100, 2) AS percent_rank_score,			-- precision, which ROUND() doesn't accept
		   NTILE(100) OVER (			         -- NTILE(n) buckets players into n equal groups, determined by rating
		   		PARTITION BY p.playstyle
		   		ORDER BY rating DESC) AS rating_percentile,
		   NTILE(4) OVER (
		   		PARTITION BY p.playstyle
		   		ORDER BY rating DESC) AS rating_quartile
	FROM gen_info gi
	JOIN preferences p
		USING(player_id);

-- 4. For each rubber, how does its cost and spin compare to the average for its type?
	SELECT name, type, cost,
		   ROUND((AVG(cost) OVER (PARTITION BY type))::numeric, 2) AS avg_cost,
		   ROUND((cost - AVG(cost) OVER (PARTITION BY type))::numeric, 2) AS cost_diff, 			-- No "ORDER BY" in window functions for both 4 and 5: 
		   spin,
		   ROUND((AVG(spin) OVER (PARTITION BY type))::numeric, 2) AS avg_spin,
		   ROUND((spin - AVG(spin) OVER (PARTITION BY type))::numeric, 2) AS spin_diff			-- Adding this would create an average that would expand row by row 
	FROM rubber_info																			-- rather than a fixed group-level average
	ORDER BY type, rubber_id;

-- 5. For each blade, how does its speed and stiffness compare to the average for its composition?
	SELECT name, composition, speed,
		   ROUND((AVG(speed) OVER (PARTITION BY composition))::numeric, 2) AS avg_speed,
		   ROUND((speed - AVG(speed) OVER (PARTITION BY composition))::numeric, 2) AS speed_diff,
		   stiffness, 
		   ROUND((AVG(stiffness) OVER (PARTITION BY composition))::numeric, 2) AS avg_stiffness,
		   ROUND((stiffness - AVG(stiffness) OVER (PARTITION BY composition))::numeric, 2) AS stiffness_diff
	FROM blade_info
	ORDER BY composition, blade_id;
