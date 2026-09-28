-- 1. Top 10 players in terms of win rate, with a minimum of 16 matches played
	SELECT gi.player_id, gi.name,
    	   COUNT(*) FILTER (WHERE m.winner_id = gi.player_id) AS wins,	
    	   		-- ^ Count how many times a specific player has won by checking if gi.player_id matches m.winner_id
    	   COUNT(*) AS total_matches,
    	   ROUND(COUNT(*) FILTER (WHERE m.winner_id = gi.player_id) * 100.0 / COUNT(*), 2) AS win_rate
	FROM gen_info gi
	JOIN matches m 
    	ON gi.player_id = m.winner_id OR gi.player_id = m.loser_id
	GROUP BY gi.player_id, gi.name
	HAVING COUNT(*) >= 16
	ORDER BY win_rate DESC
	LIMIT 10;
 
-- 2. Average ratings of players using each playstyle (at least 10 players), grouped by country
	SELECT gi.country, p.playstyle, COUNT(gi.player_id) AS player_count, ROUND(AVG(rating)::numeric, 2) AS avg_rating
	FROM gen_info gi
	JOIN preferences p
		USING (player_id)
	GROUP BY country, playstyle
	HAVING COUNT(gi.player_id) >= 10
	ORDER BY avg_rating DESC;
	
-- 3. Most commonly used rubber brand by players rated 2400 or above
	SELECT ri.brand, 
		   COUNT(*) FILTER (WHERE e.fh_rubber_id = ri.rubber_id) AS forehand_users,
		   COUNT(*) FILTER (WHERE e.bh_rubber_id = ri.rubber_id) AS backhand_users,
		   COUNT(*) FILTER (WHERE e.fh_rubber_id = ri.rubber_id) + COUNT(*) FILTER (WHERE e.bh_rubber_id = ri.rubber_id) AS total_rubber_uses
		   		-- ^ Just doing "COUNT(*) AS total_rubber_uses" will undercount uses where a player is using the same brand on both sides
	FROM rubber_info ri
	JOIN equipment e
		ON e.fh_rubber_id = ri.rubber_id OR e.bh_rubber_id = ri.rubber_id
	JOIN gen_info gi 
		ON e.player_id = gi.player_id
	WHERE gi.rating >= 2400
	GROUP BY ri.brand
	ORDER BY total_rubber_uses DESC;
