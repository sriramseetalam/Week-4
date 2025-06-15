CREATE PROCEDURE AllocateElectives
AS
BEGIN
    DECLARE @StudentId INT, @SubjectId NVARCHAR(50), @Preference INT, @GPA FLOAT;

    CREATE TABLE #SortedStudents (
        StudentId INT,
        GPA FLOAT
    );

    INSERT INTO #SortedStudents (StudentId, GPA)
    SELECT StudentId, GPA
    FROM StudentDetails
    ORDER BY GPA DESC;

    DECLARE student_cursor CURSOR FOR
    SELECT StudentId, GPA
    FROM #SortedStudents;

    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @StudentId, @GPA;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Allotted BIT = 0;
        
        DECLARE preference_cursor CURSOR FOR
        SELECT SubjectId, Preference
        FROM StudentPreference
        WHERE StudentId = @StudentId
        ORDER BY Preference;

        OPEN preference_cursor;
        FETCH NEXT FROM preference_cursor INTO @SubjectId, @Preference;

        WHILE @@FETCH_STATUS = 0 AND @Allotted = 0
        BEGIN
            IF EXISTS (SELECT 1 FROM SubjectDetails WHERE SubjectId = @SubjectId AND RemainingSeats > 0)
            BEGIN
                INSERT INTO Allotments (SubjectId, StudentId) VALUES (@SubjectId, @StudentId);

                UPDATE SubjectDetails SET RemainingSeats = RemainingSeats - 1 WHERE SubjectId = @SubjectId;

                SET @Allotted = 1;
            END

            FETCH NEXT FROM preference_cursor INTO @SubjectId, @Preference;
        END

        CLOSE preference_cursor;
        DEALLOCATE preference_cursor;

        IF @Allotted = 0
        BEGIN
            INSERT INTO UnallotedStudents (StudentId) VALUES (@StudentId);
        END

        FETCH NEXT FROM student_cursor INTO @StudentId, @GPA;
    END

    CLOSE student_cursor;
    DEALLOCATE student_cursor;

    DROP TABLE #SortedStudents;
END;

EXEC AllocateElectives;

SELECT * FROM Allotments;
-- Check UnallotedStudents
SELECT * FROM UnallotedStudents;
