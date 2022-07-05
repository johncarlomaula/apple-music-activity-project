/*
Project: Music Consumption
Author: John Carlo Maula
*/

-- Access the music database
USE music;

/*

I converted the timestamp column from a string to a a date type. 

*/

-- Convert date strings to date object
SELECT Event_Start_Timestamp, REPLACE(REPLACE(Event_Start_Timestamp, 'T', ' '), 'Z', ''), 
	   STR_TO_DATE(REPLACE(REPLACE(Event_Start_Timestamp, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s') AS Start_Timestamp
FROM play_activity;

/*

I filtered the songs to contain only instances on or after 2020 with a listening
duration of at least 20% and where the song ended naturally.

The resulting dataset will be exported to a file called 'music_activity.csv'.

*/

WITH FilteredPlays AS (
	SELECT Song_Name, Artist_Name, Media_Duration_In_Seconds AS Song_Length, Play_Duration_Seconds AS Play_Duration, End_Reason_Type,
		   STR_TO_DATE(REPLACE(REPLACE(Event_Start_Timestamp, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s') AS Start_Timestamp
	FROM play_activity
	WHERE End_Reason_Type = 'NATURAL_END_OF_TRACK') 
SELECT Song_Name, Artist_Name, Song_Length, Play_Duration, Start_Timestamp
FROM FilteredPlays
WHERE Play_Duration >= (Song_Length / 20) AND YEAR(Start_Timestamp) >= 2020;


/*

There are duplicate entries resulting from the same songs belonging in different albums.
I decided to select the first instance of these duplicates since either instance is acceptable.
The resulting dataset will be saved in a filed called 'music_breakdown.csv'.

*/

-- Remove duplicates in separate albums
WITH FilteredPlays AS (
	SELECT Song_Name, Artist_Name, Media_Duration_In_Seconds AS Song_Length, Play_Duration_Seconds AS Play_Duration, End_Reason_Type,
		   STR_TO_DATE(REPLACE(REPLACE(Event_Start_Timestamp, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s') AS Start_Timestamp
	FROM play_activity
	WHERE End_Reason_Type = 'NATURAL_END_OF_TRACK'),
FilteredPlayCounts AS (
	SELECT MAX(Song_Name) AS Song, MAX(Artist_Name) AS Artist, COUNT(Song_Name) AS Play_Count, 
		   MAX(Song_Length) AS Length, SUM(Play_Duration) AS Time_Listened
    FROM FilteredPlays
	WHERE YEAR(Start_Timestamp) >= 2020 AND Play_Duration >= (Song_Length / 20)
	GROUP BY Song_Name, Artist_Name) 
SELECT DISTINCT f.Song, f.Artist, MAX(f.Play_Count) AS Play_Count, MAX(f.Length) AS Length, ROUND(MAX(f.Time_Listened), 3) AS Time_Listened, 
				MAX(t.Album) AS Album, MAX(t.Genre) AS Genre, MAX(t.Track_Year) AS Track_Year
FROM FilteredPlayCounts AS f INNER JOIN track_information AS t ON f.Song = t.Title AND f.Artist = t.Artist
GROUP BY Song, Artist
ORDER BY MAX(Play_Count) DESC;







