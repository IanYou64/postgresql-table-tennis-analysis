# postgresql-table-tennis-analysis
A PostgreSQL portfolio project analyzing a synthetic table tennis dataset, built to demonstrate a wide range of database techniques across tiers of increasing complexity.

## Database Schema
| Table | Description | Records |
| --- | --- | --- |
| gen_info | Player demographics, career longevity, rating | 10,000 |
| preferences | Hand, grip, and playstyle | 10,000 |
| equipment | Blade and rubber assignments | 10,000 |
| rubber_info | Rubber specifications | 152 |
| blade_info | Blade specifications | 106 |
| matches | Match results by sets won and tournament played | ~ 120,000 |

## Schema Diagram
<img width="3893" height="6756" alt="image" src="https://github.com/user-attachments/assets/210f5c38-154d-4f9b-82c1-3547694976fc" />

## Database
All data was synthetically generated from scratch using Python and incorporates many real-life trends (percentages of players using certain grips and brands depending on their demographics, rubber types depending on playstyle, player ratings depending on career length, etc.). Tournaments are divided into four levels: Club Leagues, Regional Opens, National Championships, and International WTT Majors, roughly corresponding to player rating ranges. All matches are best of 7 sets.

## Tier 1: Core Aggregations and JOINs
**Skills Demonstrated:** Aggregation, Multi-table JOIN, compound *OR* JOIN conditions, *FILTER*, *GROUP BY*, *HAVING*, *ORDER BY*

1. Top 10 players by win rate (min of 16 matches)
   - Joins gen_info and matches using a compound OR condition to capture each player's full match history as both winner and loser
   - Use *FILTER(WHERE...)* to conditionally count wins using *COUNT()*
   - Use *ORDER BY win_rate DESC* and *LIMIT 10* to list only the top 10
  
2. Average ratings of players using each playstyle (with at least 10 players), grouped by country
   - Joins preferences to segment rating averages by both country and playstyle simultaneously
  
3. Most commonly used rubber brand by players rated 2400 or above
   - Joins across three tables: rubber_info, equipment, and gen_info
   - Forehand and backhand uses are counted separately before they are summed. This avoids double-counting players who use the same brand on both sides

## Tier 2: Window Functions
**Skills Demonstrated:** _RANK(), DENSE_RANK(), PERCENT_RANK(), NTILE(), AVG() OVER_, self JOIN, CTE, _NULLIF()_, ::numeric casting

1. Rank players within each country by win rate using both _RANK()_ and _DENSE_RANK()_
   - Use CTE to pre-calculate win rates since PostgreSQL doesn't allow aggregate functions in _OVER()_ clauses
   - _RANK()_ skips ranking numbers in the case of a tie, while _DENSE_RANK()_ doesn't skip
  
2. Compare each player's win rates against opponents ranked higher than them vs those ranked lower (min of 16 matches)
   - Self JOIN on gen_info to access both players' ratings in the same row
   - _CASE_ dynamically determines the opponent's player_id for each match
   - _NULLIF()_ is used to prevent divide by 0 errors in cases where players only faced people rated higher/lower than them

3. Each player's percentile of the rating distribution within their playstyle
   - _PARTITION BY_ p.playstyle ensures players are ranked relative to others in their own playstyle category
   - _NTILE(4)_ and _NTILE(100)_ are included in the same query to show that the function accepts any bucket count

4. Compare each rubber's cost and spin relative to the average for its type
   - _AVG() OVER (PARTITION BY type)_ computes a fixed group-level average for all rubbers of the same type
   - _cost_diff_ and _spin_diff_ show deviation from the type average: positive means above average, negative means below
   - _::numeric_ cast required because _AVG()_ on integer columns returns double precision in PostgreSQL, which _ROUND()_ does not accept directly
  
5. Compare each blade's speed and stiffness relative to the average for its composition
   - Same _AVG() OVER_ pattern from query 4 applied to blade_info, partitioned by composition rather than type

## Tier 3: CTEs and Subqueries
**Skills Demonstrated:** _RANK(), DENSE_RANK(), PERCENT_RANK(), NTILE(), AVG() OVER_, self JOIN, CTE, _NULLIF()_, ::numeric casting
