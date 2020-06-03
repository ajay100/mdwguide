--Update 10 existing records
UPDATE T
SET [LatestRecordedPopulation] = LatestRecordedPopulation + 1000
FROM (SELECT TOP 10 * from [Application].[Cities]) T

--Insert New Test record
INSERT INTO [Application].[Cities]
	(
        [CityName]
        ,[StateProvinceID]
        ,[Location]
        ,[LatestRecordedPopulation]
        ,[LastEditedBy]
	)
    VALUES
    (
		'NewCity' + CONVERT(char(8), getdate(), 112)
        ,1
        ,NULL
        , 1000
        ,1
	)
;


