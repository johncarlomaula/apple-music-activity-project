-- Access apple music database
USE apple_music;

/*
The first dataset I want is the play activity table with the following criteria:
	1. The event must have taken place in 2020 or after
	2. The listening duration must be at least 20% of the song's length
	3. The song must have ended naturally
    
This will be exported to a file called 'listening_activity.csv'
*/

SELECT song_name, artist_name, media_duration,  play_duration, event_timestamp
FROM play_activity
WHERE end_reason_type = 'NATURAL_END_OF_TRACK' AND
	  YEAR(event_timestamp) >= 2020 AND
      play_duration >= (media_duration / 5);
      
/*
Next, I want to determine the play counts of each songs. Although the library table contains
the play counts, it's inaccurate due to a reset I did in the beginning of 2021. To remedy 
this, I decided to calculate play count based on the number of instances in the play activity 
table. 

The downside of this is that it does not include songs that are not available on Apple Music. 
Fortunately, there are only a few songs, that I played a lot that is not available in Apple
Music. Thus, I can manually add it to the final dataset.
*/      
      
SELECT MAX(song_name) AS song, MAX(artist_name) AS artist, COUNT(song_name) AS play_count
FROM play_activity
GROUP BY song_name, artist_name
ORDER BY play_count DESC;

/*
The resulting query include instances where I scrubbed a song, played only a specific part, ect. 
Thus, I will apply the criteria from the first query when calculating the play counts.
*/

WITH filtered_plays AS (
	SELECT song_name, artist_name, media_duration,  play_duration, event_timestamp
	FROM play_activity
	WHERE end_reason_type = 'NATURAL_END_OF_TRACK' AND
		  YEAR(event_timestamp) >= 2020 AND
		  play_duration >= (media_duration / 5))
SELECT MAX(song_name) AS song, MAX(artist_name) AS artist, COUNT(song_name) AS play_count
FROM filtered_plays
GROUP BY song_name, artist_name
ORDER BY play_count DESC;

/*
I want to verify that these play counts are accurate. I can use the play count from the library
table to do this. Since I reset the play counts in 2021, I can filter it to songs that were
released after the reset.
*/

SELECT title, artist, play_count, track_year
FROM library
WHERE track_year >= 2021
ORDER BY play_count DESC;

/*
TOP 3 SONGS:
1. Hold On by Adele at 256 vs 224
2. Easier Said by Kacey Musgraves at 229 vs 218
3. Kind of Girl by MUNA at 209 vs 177

There are some differences between the play counts from the library table and the play 
count calculated from the play_activity table. However, the play counts from the library 
table are less conservative. That is, listening to 1 second of a song or scrubbing 
to the end will increase the play count. Thus, I decided to proceed with the play counts
from the play_activity table.
*/

WITH filtered_plays AS (
	SELECT song_name, artist_name, media_duration,  play_duration, event_timestamp
	FROM play_activity
	WHERE end_reason_type = 'NATURAL_END_OF_TRACK' AND
		  YEAR(event_timestamp) >= 2020 AND
		  play_duration >= (media_duration / 5)),
play_counts AS (
	SELECT MAX(song_name) AS song, MAX(artist_name) AS artist, COUNT(song_name) AS play_count
	FROM filtered_plays
	GROUP BY song_name, artist_name)
SELECT p.song, p.artist, p.play_count, l.album, l.genre, l.track_year, l.track_duration
FROM play_counts AS p INNER JOIN library AS l ON p.song = l.title AND p.artist = l.artist
ORDER BY play_count DESC;

/*
The resulting queries have several duplicates for each song. Thus, I decided to 
select distinct instances.
*/

WITH filtered_plays AS (
	SELECT song_name, artist_name, media_duration,  play_duration, event_timestamp
	FROM play_activity
	WHERE end_reason_type = 'NATURAL_END_OF_TRACK' AND
		  YEAR(event_timestamp) >= 2020 AND
		  play_duration >= (media_duration / 5)),
play_counts AS (
	SELECT MAX(song_name) AS song, MAX(artist_name) AS artist, MAX(media_duration) AS song_length, 
		   COUNT(song_name) AS play_count
	FROM filtered_plays
	GROUP BY song_name, artist_name)
SELECT DISTINCT p.song, p.artist, p.play_count AS play_count, p.song_length, l.album, l.genre, l.track_year
FROM play_counts AS p INNER JOIN library AS l ON p.song = l.title AND p.artist = l.artist
ORDER BY play_count DESC;

/*
There are still some duplicate queries due to the album titles. One way to fix this is to select just one
of the duplicated instances by doing another group by on song and artist.

The final result of this query will be exported to a file called 'music_breakdown.csv'
*/

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

/*
After reviewing the dataset, I took the opportunity to manually update it to be more accurate like
changing album titles and adding songs I know I played significantly.

1. Change the album from 'thank u, next - Single' to 'thank u, next' for the song 'thank u, next'
2. Added songs that are not available on Apple Music
3. Added 'Save Your Tears (Remix)' by The Weeknd & Ariana Grande
*/

SELECT *
FROM library
WHERE album = 'Chromatica';

SELECT *
FROM library
WHERE album = '30';

SELECT *
FROM library
WHERE title = 'Save Your Tears'
