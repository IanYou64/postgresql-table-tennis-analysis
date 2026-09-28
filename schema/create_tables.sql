CREATE TABLE public.gen_info (
	player_id int4 NOT NULL,
	"name" varchar(100) NULL,
	country varchar(100) NULL,
	career_years int4 NULL,
	rating int4 NULL,
	CONSTRAINT gen_info_pkey PRIMARY KEY (player_id)
);

CREATE TABLE public.preferences (
	player_id int4 NULL,
	hand varchar(50) NULL,
	grip varchar(50) NULL,
	playstyle varchar(50) NULL
  	CONSTRAINT preferences_pkey PRIMARY KEY (player_id),
  	CONSTRAINT preferences_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.gen_info(player_id)
);

CREATE TABLE public.rubber_info (
	rubber_id varchar(50) NULL,
	brand varchar(50) NULL,
	"name" varchar(50) NULL,
	"type" varchar(50) NULL,
	"cost" float4 NULL,
	sponge_hardness int4 NULL,
	spin int4 NULL,
	speed int4 NULL,
	"control" int4 NULL
  	CONSTRAINT rubber_info_pkey PRIMARY KEY (rubber_id)
);

CREATE TABLE public.blade_info (
	blade_id varchar(50) NULL,
	brand varchar(50) NULL,
	"name" varchar(50) NULL,
	handle varchar(50) NULL,
	playstyle varchar(50) NULL,
	composition varchar(50) NULL,
	ply_count int4 NULL,
	"cost" float4 NULL,
	speed int4 NULL,
	"control" int4 NULL,
	stiffness int4 NULL,
	hardness int4 NULL,
	consistency int4 NULL
  	CONSTRAINT blade_info_pkey PRIMARY KEY (blade_id)
);

CREATE TABLE public.equipment (
    player_id int4 NOT NULL,
    playstyle varchar(50) NULL,
    blade_id varchar(50) NULL,
    fh_rubber_id varchar(50) NULL,
    bh_rubber_id varchar(50) NULL,
    CONSTRAINT equipment_pkey PRIMARY KEY (player_id),
    CONSTRAINT equipment_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.gen_info(player_id),
    CONSTRAINT equipment_blade_fkey FOREIGN KEY (blade_id) REFERENCES public.blade_info(blade_id),
    CONSTRAINT equipment_fh_rubber_fkey FOREIGN KEY (fh_rubber_id) REFERENCES public.rubber_info(rubber_id),
    CONSTRAINT equipment_bh_rubber_fkey FOREIGN KEY (bh_rubber_id) REFERENCES public.rubber_info(rubber_id)
);

CREATE TABLE public.matches (
	match_id int4 NULL,
	winner_id int4 NULL,
	loser_id int4 NULL,
	winner_sets int4 NULL,
	loser_sets int4 NULL,
	tournament varchar(50) NULL
  	CONSTRAINT matches_pkey PRIMARY KEY (match_id),
  	CONSTRAINT matches_winner_fkey FOREIGN KEY (winner_id) REFERENCES public.gen_info(player_id),
  	CONSTRAINT matches_loser_fkey FOREIGN KEY (loser_id) REFERENCES public.gen_info(player_id)
);
