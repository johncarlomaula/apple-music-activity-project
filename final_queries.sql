/*
Here are the final queries used to produce the two final datasets.
*/

-- Final query to produce listening_activity.csv 
SELECT song_name, artist_name, media_duration,  play_duration, event_timestamp
FROM play_activity
WHERE end_reason_type = 'NATURAL_END_OF_TRACK' AND
	  YEAR(event_timestamp) >= 2020 AND
      play_duration >= (media_duration / 5);

-- Final query to produce music_breakdown.csv
WITH filtered_plays AS (
	SELECT song_name, artist_name, media_duration,  play_duration, event_timestamp
	FROM play_activity
	WHERE end_reason_type = 'NATURAL_END_OF_TRACK' AND
		  YEAR(event_timestamp) >= 2020 AND
		  play_duration >= (media_duration / 5)),
play_counts AS (
	SELECT MAX(song_name) AS song, MAX(artist_name) AS artist, MAX(media_duration) AS song_length, COUNT(song_name) AS play_count
	FROM filtered_plays
	GROUP BY song_name, artist_name)
SELECT DISTINCT p.song, p.artist, MAX(p.play_count) AS play_count, MAX(p.song_length) AS song_length, MAX(l.album) AS album, 
                MAX(l.genre) AS genre, MAX(l.track_year) AS track_year
FROM play_counts AS p INNER JOIN library AS l ON p.song = l.title AND p.artist = l.artist
GROUP BY song, artist
ORDER BY play_count DESC;