/*
Project: Music Consumption
Author: John Carlo Maula
*/

-- Access the music database
USE music;


-- View desired columns of the play_activity table
SELECT Artist_Name, Song_Name, Play_Duration_Seconds, End_Reason_Type, 
	   Media_Duration_In_Seconds, Event_Start_Timestamp
FROM play_activity;


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

Next, I  calculated the play count of each song. 

However, I wanted to filter my data to contain only instances on or after 2020
with a listening a listening duration of at least 20% and where the song ended naturally.

*/

-- Calculate play count
SELECT MAX(Song_Name) AS Song, MAX(Artist_Name) AS Artist, COUNT(Song_Name) AS Play_Count
FROM play_activity
GROUP BY Song_Name;

-- Filter by year and end reason type and duration length of greater than a fifth of the song length 
WITH FilteredPlays AS (
	SELECT Song_Name, Artist_Name, Media_Duration_In_Seconds AS Song_Length, Play_Duration_Seconds AS Play_Duration, End_Reason_Type,
		   STR_TO_DATE(REPLACE(REPLACE(Event_Start_Timestamp, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s') AS Start_Timestamp
	FROM play_activity
	WHERE End_Reason_Type = 'NATURAL_END_OF_TRACK') 
SELECT Song_Name, Artist_Name, Song_Length, Play_Duration, Start_Timestamp
FROM FilteredPlays
WHERE Play_Duration >= (Song_Length / 20) AND YEAR(Start_Timestamp) = 2021;

-- Calculate play count with filters
WITH FilteredPlays AS (
	SELECT Song_Name, Artist_Name, Media_Duration_In_Seconds AS Song_Length, Play_Duration_Seconds AS Play_Duration, End_Reason_Type,
		   STR_TO_DATE(REPLACE(REPLACE(Event_Start_Timestamp, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s') AS Start_Timestamp
	FROM play_activity
	WHERE End_Reason_Type = 'NATURAL_END_OF_TRACK') 
SELECT MAX(Song_Name) AS Song, MAX(Artist_Name) AS Artist, COUNT(Song_Name) AS Play_Count, 
	   MAX(Song_Length) AS Length, SUM(Play_Duration) AS Time_Listened
FROM FilteredPlays
WHERE YEAR(Start_Timestamp) = 2021 AND Play_Duration >= (Song_Length / 20)
GROUP BY Song_Name, Artist_Name
ORDER BY Play_Count DESC;



/* 

I wanted to check if the play counts are close to the recorded play counts in the track_information table.
I specifically looked at songs that were released in 2021 and were last played in 2021.

*/

-- Verify play count with songs last played in 2021
WITH CountVerification AS (
	SELECT Title, Artist, Album, Genre, Track_Play_Count,
	STR_TO_DATE(REPLACE(REPLACE(Last_Played_Date, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s') AS Last_Played,
    STR_TO_DATE(REPLACE(REPLACE(Release_Date, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s') AS Release_Date
	FROM track_information)
SELECT *
FROM CountVerification
WHERE YEAR(Last_Played) = 2021 AND YEAR(Release_Date) = 2021
ORDER BY Track_Play_Count DESC
LIMIT 25;


/*

Since the play counts are faily close, I can proceed to the next step.
From the track_information table, I want to obtain the album, genre, and track_year of the songs.

*/

-- Obtain track information: Album, Genre, Track Year
WITH FilteredPlays AS (
	SELECT Song_Name, Artist_Name, Media_Duration_In_Seconds AS Song_Length, Play_Duration_Seconds AS Play_Duration, End_Reason_Type,
		   STR_TO_DATE(REPLACE(REPLACE(Event_Start_Timestamp, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s') AS Start_Timestamp
	FROM play_activity
	WHERE End_Reason_Type = 'NATURAL_END_OF_TRACK'),
FilteredPlayCounts AS (
	SELECT MAX(Song_Name) AS Song, MAX(Artist_Name) AS Artist, COUNT(Song_Name) AS Play_Count, 
		   MAX(Song_Length) AS Length, SUM(Play_Duration) AS Time_Listened
    FROM FilteredPlays
	WHERE YEAR(Start_Timestamp) = 2021 AND Play_Duration >= (Song_Length / 20)
	GROUP BY Song_Name, Artist_Name) 
SELECT DISTINCT f.Song, f.Artist, f.Play_Count, f.Length, f.Time_Listened, t.Album, t.Genre, t.Track_Year
FROM FilteredPlayCounts AS f INNER JOIN track_information AS t ON f.Song = t.Title AND f.Artist = t.Artist
ORDER BY Play_Count DESC;


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



