-- Access apple music database
USE apple_music;

-- View play activity table
SELECT *
FROM play_activity;

-- View library table
SELECT *
FROM library;

/*
After looking at the dataset, I noticed that tracks with multiple artists primarily
have the artists separated by a comma in the play_activity table while artists are
separated by an & in the library table.

Since the song titles and artists will be used to join the two tables, I decided 
to replace the comma with an & in the play_activity table.
*/

-- Replace commas with an '&' in the play activity table
UPDATE play_activity
SET artist_name = REPLACE(artist_name, ',', ' &');

-- Check for songs with multiple artists in the play_activity table
SELECT DISTINCT artist_name, song_name
FROM play_activity
WHERE artist_name LIKE '%,%' OR artist_name LIKE '%&%'
ORDER BY artist_name;

-- Check for songs with multiple artists in the library table
SELECT DISTINCT title, artist
FROM library
WHERE artist LIKE '%,%' OR artist LIKE '%&%'
ORDER BY artist;

/*
Next, I changed the song length and play duration from milliseconds to seconds and
updated the column names to reflect the new units.
*/

-- Add new columns to the play_activity table
ALTER TABLE play_activity
	ADD media_duration DOUBLE,
    ADD play_duration DOUBLE;

-- Convert units from milliseconds to seconds
UPDATE play_activity
SET media_duration = media_duration_ms / 1000,
	play_duration = play_duration_ms / 1000;

-- Drop old columns
ALTER TABLE play_activity
	DROP COLUMN play_duration_ms,
	DROP COLUMN media_duration_ms;
    
-- Verify changes
SELECT *
FROM play_activity;


/*
Finally, I converted the timestamps from string type to date type.
*/

-- Check results of query to convert date strings to date object
SELECT release_date, REPLACE(REPLACE(release_date, 'T', ' '), 'Z', ''), 
	   STR_TO_DATE(REPLACE(REPLACE(release_date, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s') AS release_date_v2
FROM library;

-- Convert release_date to date type in the library table
UPDATE library
SET release_date = STR_TO_DATE(REPLACE(REPLACE(release_date, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s')
WHERE release_date != '';

-- Verify changes
SELECT release_date
FROM library;

-- Convert timestamp to a datetime type in the play_activity table
UPDATE play_activity
SET event_timestamp = CAST(REPLACE(REPLACE(event_timestamp, 'T', ' '), 'Z', '') AS DATETIME)
WHERE event_timestamp != '';

-- Verify changes
SELECT event_timestamp
FROM play_activity;
