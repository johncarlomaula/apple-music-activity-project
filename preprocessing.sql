-- Use database
USE music;


/*

First, I looked at the list of columns to determine which variables I will need.

There are 7 variables of interest from the play_activity table 
and 8 variables of interest from the track_information table.

*/

-- View structure of the play_activity table
DESCRIBE play_activity;

-- View structure of the track_information table
DESCRIBE track_information;

-- View desired columns of the play_activity table
SELECT Artist_Name, Song_Name, Play_Duration_Milliseconds, End_Reason_Type, Media_Duration_In_Milliseconds, Event_Start_Timestamp
FROM play_activity;

-- View desired columns of the track_information table
SELECT Title, Artist, Album, Genre, Track_Year, Track_Duration, Track_Play_Count, Skip_Count
FROM track_information;


/*

After looking at the desired columns, I compared the tracks with multiple artists from
the play_activity table to the tracks in the track_information table.

I discovered that artists are primarily separated by a comma in the play_activity table
while artists are primarily separated by an & in the track_information table.

I decided to replace the comma with an & in the play_activity table.

*/

-- Check for songs with multiple artists in the play_activity table
SELECT DISTINCT Artist_Name, Song_Name
FROM play_activity
WHERE Artist_Name LIKE '%,%' OR Artist_Name LIKE '%&%'
ORDER BY Artist_Name;

-- Check for songs with multiple artists in the track_information table
SELECT DISTINCT Artist, Title
FROM track_information
WHERE Artist LIKE '%,%' OR Artist LIKE '%&%'
ORDER BY Artist;

-- Replace commas with & in the table
UPDATE play_activity
SET Artist_Name = REPLACE(Artist_Name, ',', ' &');

                            
/*

Next, I changed the song length from milliseconds to seconds and updated the 
column name to reflect the new unit.

I also calculated the listening duration by taking the difference between the
end position and start position.

*/

-- Add new columns for the converted data
ALTER TABLE play_activity
	ADD Media_Duration_In_Seconds DOUBLE,
	ADD Play_Duration_Seconds DOUBLE;

-- Convert units from milliseconds to seconds
UPDATE play_activity
SET Media_Duration_In_Seconds = Media_Duration_In_Milliseconds / 1000,
	Play_Duration_Seconds = Play_Duration_Milliseconds / 1000;
    
-- Check new columns
SELECT Artist_Name, Media_Duration_In_Milliseconds, Media_Duration_In_Seconds, Play_Duration_Milliseconds, Play_Duration_Seconds
FROM play_activity;



