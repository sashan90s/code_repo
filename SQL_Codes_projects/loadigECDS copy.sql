--=================================================================================
--Created by:	Jordan Butler
--Date:			24th March 2023
--Description:	Loads Emergency Care data from staging into the Ods.
--Usage:		EXEC cxsus.usp_LoadEcdsToOds;
--=================================================================================
CREATE PROCEDURE cxsus.usp_LoadEcdsToOds
AS
SET NOCOUNT ON;
DECLARE	 @ProcedureName		SYSNAME = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
		,@StartTime			DATETIME2(0) = SYSDATETIME()
		,@EndTime			DATETIME2(0)
		,@ErrorMessage		VARCHAR(1000)
		,@Inserts			INT = 0
		,@Updates			INT = 0
		,@Deletes			INT = 0
		,@Success			BIT = 0
		,@LogId				INT
		,@InsertUpdateUser	VARCHAR(100) = ORIGINAL_LOGIN()
		,@InsertUpdateTime	DATETIME2(0) = SYSDATETIME()
		,@SourceSystemKey	INT = CAST([$(OdsDbName)].dbo.udf_GetSourceSystemKey('CXSUS') AS INT)
		,@24MonthsAgo		DATE = DATEADD(MONTH, -24, DATEADD(DAY,1,EOMONTH(SYSDATETIME(),-1)));

-- Log the start of the load
EXEC [$(LoggingDbName)].dbo.usp_CreateEtlLog @PackageName			= @ProcedureName
                                            ,@SourceObjectType		= 'Table'
                                            ,@SourceObjectName		= '$(DatabaseName).cxsus.Ecds'
                                            ,@DestinationObjectType = 'Table'
                                            ,@DestinationObjectName = '$(OdsDbName).cxsus.EmergencyCare'
                                            ,@StartTime				= @StartTime
										    ,@LogId					= @LogId OUTPUT;

-- Create a temporary table variable to hold the output actions.
DECLARE @SummaryOfChanges TABLE(Change VARCHAR(20));

BEGIN TRY

	DROP TABLE IF EXISTS #Snomed;

	SELECT   c.ConceptId
	        ,d.Term
	INTO #Snomed
	FROM [$(OdsDbName)].snomed.Concept AS c
		INNER JOIN [$(OdsDbName)].snomed.ConceptDescriptionMapping AS cdm
	   		ON c.ConceptKey = cdm.ConceptKey
		INNER JOIN [$(OdsDbName)].snomed.[Description] AS d
	   		ON cdm.DescriptionKey = d.DescriptionKey
	   		AND d.IsActive = 1
	WHERE c.IsActive = 1;

	CREATE CLUSTERED INDEX IX_Snomed ON #Snomed (ConceptId);

	DROP TABLE IF EXISTS #Ecds;

SELECT	 CDS_Unique_Identifier AS EmergencyCareId
			,@SourceSystemKey AS SourceSystemKey
			,Organisation_Code_Provider AS ProviderCode
			,Department_Type AS DepartmentTypeCode
			,Organisation_Code_Commissioner AS OrganisationCodeCommissioner
			,NHS_Number AS PersonId
			,Age_At_CDS_Activity_Date AS Age
			,CASE Stated_Gender
				WHEN '1' THEN 'Male'
				WHEN '2' THEN 'Female'
				WHEN '9' THEN 'Indeterminate'
				WHEN 'X' THEN 'Not Known'
				ELSE Stated_Gender
			 END AS Gender
			,Local_Patient_Identifier AS LocalPatientIdentifier
			,General_Practice AS GeneralPractice
			,[Site] AS [Site]
			,OA_11 AS OutputArea
			,LSOA_11 AS LowerSuperOutputAreaCode
			,Postcode_District AS PostcodeDistrict
			,Residence_CCG AS ResidenceCcg
			,Ethnic_Category AS EthnicCategory
			,CAST(Accommodation_Status AS BIGINT) AS AccommodationStatus
			,Arrival_Date AS ArrivalDate
			,Arrival_Time AS ArrivalTime
			,Arrival_Planned AS ArrivalPlanned
			,CAST(Arrival_Mode AS BIGINT) AS ArrivalMode
			,CAST(Referral_Request_Date_1 AS DATE) AS ReferredToServiceDate
			,CAST(Referral_Request_Time_1 AS TIME(0)) AS ReferredToServiceTime
			,Initial_Assessment_Date AS InitialAssessmentDate
			,Initial_Assessment_Time AS InitialAssessmentTime
			,Seen_For_Treatment_Date AS SeenForTreatmentDate
			,Seen_For_Treatment_Time AS SeenForTreatmentTime
			,Conclusion_Date AS ConclusionDate
			,Conclusion_Time AS ConclusionTime
			,Departure_Date AS DepartureDate
			,Departure_Time AS DepartureTime
			,Decision_To_Admit_Date AS DecisionToAdmitDate
			,Decision_To_Admit_Time AS DecisionToAdmitTime
			,Decision_To_Admit_Time_Since_Arrival AS DecisionToAdmitTimeSinceArrival
			,Diagnoses_Code AS DiagnosesCode
			,CAST(Diagnoses_Code_1 AS BIGINT) AS DiagnosesCode1
			,CAST(Diagnoses_Code_2 AS BIGINT) AS DiagnosesCode2
			,CAST(Diagnoses_Code_3 AS BIGINT) AS DiagnosesCode3
			,Investigation_Code AS InvestigationCode
			,CAST(Investigation_Code_1 AS BIGINT) AS InvestigationCode1
			,CAST(Investigation_Code_2 AS BIGINT) AS InvestigationCode2
			,Treatment_Code AS TreatmentCode
			,CAST(Treatment_Code_1 AS BIGINT) AS TreatmentCode1
			,CAST(Treatment_Code_2 AS BIGINT) AS TreatmentCode2
			,CAST(Treatment_Code_3 AS BIGINT) AS TreatmentCode3
			,Health_Resource_Group AS HealthResourceGroup
			,Attendance_Category AS AttendanceCategory
			,Ambulance_Incident_Number AS AmbulanceIncidentNumber
			,Conveying_Ambulance_Trust AS ConveyingAmbulanceTrust
			,CAST(Attendance_Source AS BIGINT) AS AttendanceSource
			,Referred_To_Service AS ReferredToService
			,CAST(Referred_To_Service_1 AS BIGINT) AS ReferredToService1
			,CAST(Discharge_Status AS BIGINT) AS DischargeStatus
			,CAST(Destination AS BIGINT) AS DischargeDestination
			,CAST(Chief_Complaint AS BIGINT) AS ChiefComplaint
			,CAST(Acuity AS BIGINT) AS Acuity
			,Comorbidities_Code AS ComorbiditiesCode
			,CAST(Comorbidities_Code_1 AS BIGINT) AS ComorbiditiesCode1
			,CAST(Comorbidities_Code_2 AS BIGINT) AS ComorbiditiesCode2
			,AEC_Related AS AecRelated
			,Equivalent_AE_Investigation_Code AS EquivalentAeInvestigationCode
			,Equivalent_AE_Investigation_Code_1 AS EquivalentAeInvestigationCode1
			,Equivalent_AE_Investigation_Code_2 AS EquivalentAeInvestigationCode2
			,Equivalent_AE_Treatment_Code AS EquivalentAeTreatmentCode
			,Equivalent_AE_Treatment_Code_1 AS EquivalentAeTreatmentCode1
			,Equivalent_AE_Treatment_Code_2 AS EquivalentAeTreatmentCode2
			,Equivalent_AE_Treatment_Code_3 AS EquivalentAeTreatmentCode3
			,CAST(Injury_Intent AS BIGINT) AS InjuryIntentCode
			,CAST(Injury_Mechanism AS BIGINT) AS InjuryMechanismCode
			,CAST(Injury_Date AS DATE) AS InjuryPlaceDate
			,CAST(Injury_Time AS TIME(0)) AS InjuryPlaceTime
			,CAST(Injury_Place AS BIGINT) AS InjuryPlaceCode
			,CAST(Activity_Status AS BIGINT) AS InjuryActivityStatus
			,CAST(Activity_Type AS BIGINT) AS InjuryActivityType
			,Alcohol_Drug_Involvements AS AlcoholDrugInvolvementsCode
			,CAST(Alcohol_Drug_Involvements_1 AS BIGINT) AS AlcoholDrugInvolvementsCode1
			,CAST(Alcohol_Drug_Involvements_2 AS BIGINT) AS AlcoholDrugInvolvementsCode2
			,CAST(Alcohol_Drug_Involvements_3 AS BIGINT) AS AlcoholDrugInvolvementsCode3
			,Tariff AS Tariff
			,Final_Price AS FinalPrice
			,Clinical_Coded_Scored_Assessment_Tool_Type_Code AS ClinicalCodedScoredAssessmentToolTypeCode
			,CAST(Clinical_Coded_Scored_Assessment_Tool_Type_Code_1 AS BIGINT) AS ClinicalCodedScoredAssessmentToolTypeCode1  
			,CAST(Clinical_Coded_Scored_Assessment_Tool_Type_Code_2 AS BIGINT) AS ClinicalCodedScoredAssessmentToolTypeCode2  
			,CAST(Clinical_Coded_Scored_Assessment_Tool_Type_Code_3 AS BIGINT) AS ClinicalCodedScoredAssessmentToolTypeCode3
			,Clinical_Coded_Scored_Assessment_Person_Score AS ClinicalCodedScoredAssessmentPersonScore
			,CAST(Clinical_Coded_Scored_Assessment_Person_Score_1 AS BIGINT) AS ClinicalCodedScoredAssessmentPersonScore1  
			,CAST(Clinical_Coded_Scored_Assessment_Person_Score_2 AS BIGINT) AS ClinicalCodedScoredAssessmentPersonScore2  
			,CAST(Clinical_Coded_Scored_Assessment_Person_Score_3 AS BIGINT) AS ClinicalCodedScoredAssessmentPersonScore3
			,Validation_Timestamp AS ValidationTimestamp
			,Validation_Timestamp_1 AS ValidationTimestamp1  
			,Validation_Timestamp_2 AS ValidationTimestamp2  
			,Validation_Timestamp_3 AS ValidationTimestamp3
			,Clinical_Coded_Findings_Code AS ClinicalCodedFindingsCode  
			,CAST(Clinical_Coded_Findings_Code_1 AS BIGINT) AS ClinicalCodedFindingsCode1  
			,CAST(Clinical_Coded_Findings_Code_2 AS BIGINT) AS ClinicalCodedFindingsCode2  
			,CAST(Clinical_Coded_Findings_Code_3 AS BIGINT) AS ClinicalCodedFindingsCode3
			,Clinical_Coded_Findings_Code_Timestamp AS ClinicalCodedFindingsCodeTimestamp  
			,Clinical_Coded_Findings_Code_Timestamp_1 AS ClinicalCodedFindingsCodeTimestamp1  
			,Clinical_Coded_Findings_Code_Timestamp_2 AS ClinicalCodedFindingsCodeTimestamp2  
			,Clinical_Coded_Findings_Code_Timestamp_3 AS ClinicalCodedFindingsCodeTimestamp3
			,RECORD_ID AS RecordId
			,ROW_NUMBER() OVER (PARTITION BY CDS_Unique_Identifier, Organisation_Code_Provider ORDER BY RECORD_ID DESC) AS RowNum
	INTO #Ecds
	FROM cxsus.Ecds;

	MERGE INTO [$(OdsDbName)].cxsus.EmergencyCare AS TARGET
	USING	(SELECT	 ec.EmergencyCareId
			,ec.SourceSystemKey
			,ec.ProviderCode
			,o.ProviderShortName AS [Provider]
			,ec.DepartmentTypeCode
			,d.AeDepartmentDescriptionShort AS DepartmentType
			,ec.OrganisationCodeCommissioner
			,ec.PersonId
			,ec.Age
			,ec.Gender
			,ec.LocalPatientIdentifier
			,ec.GeneralPractice
			,ec.[Site]
			,ec.OutputArea
			,ec.LowerSuperOutputAreaCode
			,olwm.LocalAuthorityCode
			,olwm.LocalAuthorityName
			,ec.PostcodeDistrict
			,ec.ResidenceCcg
			,po.OrganisationName AS ResidenceCcgDescription
			,ec.EthnicCategory
			,eth.EthnicCategory AS EthnicCategoryDescription
			,ec.AccommodationStatus
			,acoms.Term AS AccommodationStatusDescription
			,ec.ArrivalDate
			,ec.ArrivalTime
			,ec.ArrivalPlanned
			,ec.ArrivalMode
			,am.Term AS ArrivalModeDescription
			,ec.ReferredToServiceDate
			,ec.ReferredToServiceTime
			,ec.InitialAssessmentDate
			,ec.InitialAssessmentTime
			,ec.SeenForTreatmentDate
			,ec.SeenForTreatmentTime
			,ec.ConclusionDate
			,ec.ConclusionTime
			,ec.DepartureDate
			,ec.DepartureTime
			,ec.DecisionToAdmitDate
			,ec.DecisionToAdmitTime
			,ec.DecisionToAdmitTimeSinceArrival
			,ec.DiagnosesCode
			,di.Term AS DiagnosesDescription
			,ec.DiagnosesCode1
			,di1.Term AS DiagnosesDescription1
			,ec.DiagnosesCode2
			,di2.Term AS DiagnosesDescription2
			,ec.DiagnosesCode3
			,di3.Term AS DiagnosesDescription3
			,ec.InvestigationCode
			,i.Term AS InvestigationDescription
			,ec.InvestigationCode1
			,i1.Term AS InvestigationDescription1
			,ec.InvestigationCode2
			,i2.Term AS InvestigationDescription2
			,ec.TreatmentCode
			,t.Term AS TreatmentDescription
			,ec.TreatmentCode1
			,t1.Term AS TreatmentDescription1
			,ec.TreatmentCode2
			,t2.Term AS TreatmentDescription2
			,ec.TreatmentCode3
			,t3.Term AS TreatmentDescription3
			,ec.HealthResourceGroup
			,ec.AttendanceCategory
			,ac.[Description] AS AttendanceCategoryDescription
			,ec.AmbulanceIncidentNumber
			,ec.ConveyingAmbulanceTrust
			,o2.ProviderShortName AS ConveyingAmbulanceTrustDescription
			,ec.AttendanceSource
			,ats.Term AS AttendanceSourceDescription
			,ec.ReferredToService
			,rs.Term AS ReferredToServiceDescription
			,ec.ReferredToService1
			,rs1.Term AS ReferredToService1Description
			,ec.DischargeStatus
			,ds.Term AS DischargeStatusDescription
			,ec.DischargeDestination
			,dd.Term AS DischargeDestinationDescription
			,ec.ChiefComplaint
			,cc.Term AS ChiefComplaintDescription
			,ec.Acuity
			,ay.Term AS AcuityDescription
			,ec.ComorbiditiesCode
			,co.Term AS ComorbiditiesCodeDescription
			,ec.ComorbiditiesCode1
			,co1.Term AS ComorbiditiesCode1Description
			,ec.ComorbiditiesCode2
			,co2.Term AS ComorbiditiesCode2Description
			,ec.AecRelated
			,ec.EquivalentAeInvestigationCode
			,iv.[Description] AS EquivalentAeInvestigationCodeDescription
			,ec.EquivalentAeInvestigationCode1
			,iv1.[Description] AS EquivalentAeInvestigationCode1Description
			,ec.EquivalentAeInvestigationCode2
			,iv2.[Description] AS EquivalentAeInvestigationCode2Description
			,ec.EquivalentAeTreatmentCode
			,tr.AeTreatment AS EquivalentAeTreatmentCodeDescription
			,ec.EquivalentAeTreatmentCode1
			,tr1.AeTreatment AS EquivalentAeTreatmentCode1Description
			,ec.EquivalentAeTreatmentCode2
			,tr2.AeTreatment AS EquivalentAeTreatmentCode2Description
			,ec.EquivalentAeTreatmentCode3
			,tr3.AeTreatment AS EquivalentAeTreatmentCode3Description
			,ec.InjuryIntentCode
			,ii.Term AS InjuryIntentDescription
			,ec.InjuryMechanismCode
			,im.Term AS InjuryMechanismDescription
			,ec.InjuryPlaceDate
			,ec.InjuryPlaceTime
			,ec.InjuryPlaceCode
			,ipc.Term AS InjuryPlaceDescription
			,ec.InjuryActivityStatus
			,ias.Term AS InjuryActivityStatusDescription
			,ec.InjuryActivityType
			,iat.Term AS InjuryActivityTypeDescription
			,ec.AlcoholDrugInvolvementsCode
			,ec.AlcoholDrugInvolvementsCode1
			,ad1.Term AS AlcoholDrugInvolvements1Description
			,ec.AlcoholDrugInvolvementsCode2
			,ad2.Term AS AlcoholDrugInvolvements2Description
			,ec.AlcoholDrugInvolvementsCode3
			,ad3.Term AS AlcoholDrugInvolvements3Description
			,ec.Tariff
			,ec.FinalPrice
			,ec.ClinicalCodedScoredAssessmentToolTypeCode
			,att.Term AS ClinicalCodedScoredAssessmentToolTypeCodeDescription
			,ec.ClinicalCodedScoredAssessmentToolTypeCode1
			,att1.Term AS ClinicalCodedScoredAssessmentToolTypeCode1Description
			,ec.ClinicalCodedScoredAssessmentToolTypeCode2
			,att2.Term AS ClinicalCodedScoredAssessmentToolTypeCode2Description
			,ec.ClinicalCodedScoredAssessmentToolTypeCode3
			,att3.Term AS ClinicalCodedScoredAssessmentToolTypeCode3Description
			,ec.ClinicalCodedScoredAssessmentPersonScore
			,aps.Term AS ClinicalCodedScoredAssessmentPersonScoreDescription
			,ec.ClinicalCodedScoredAssessmentPersonScore1
			,aps1.Term AS ClinicalCodedScoredAssessmentPersonScore1Description
			,ec.ClinicalCodedScoredAssessmentPersonScore2
			,aps2.Term AS ClinicalCodedScoredAssessmentPersonScore2Description
			,ec.ClinicalCodedScoredAssessmentPersonScore3
			,aps3.Term AS ClinicalCodedScoredAssessmentPersonScore3Description
			,ec.ValidationTimestamp
			,ec.ValidationTimestamp1
			,ec.ValidationTimestamp2
			,ec.ValidationTimestamp3
			,ec.ClinicalCodedFindingsCode
			,cfc.Term AS ClinicalCodedFindingsCodeDescription
			,ec.ClinicalCodedFindingsCode1
			,cfc1.Term AS ClinicalCodedFindingsCode1Description
			,ec.ClinicalCodedFindingsCode2
			,cfc2.Term AS ClinicalCodedFindingsCode2Description
			,ec.ClinicalCodedFindingsCode3
			,cfc3.Term AS ClinicalCodedFindingsCode3Description
			,ec.ClinicalCodedFindingsCodeTimestamp
			,ec.ClinicalCodedFindingsCodeTimestamp1
			,ec.ClinicalCodedFindingsCodeTimestamp2
			,ec.ClinicalCodedFindingsCodeTimestamp3
			,HASHBYTES('SHA2_512', CONCAT(	 ec.EmergencyCareId							,'|'
											,ec.SourceSystemKey							,'|'
											,ec.ProviderCode							,'|'
											,o.ProviderShortName						,'|'
											,ec.DepartmentTypeCode						,'|'
											,d.AeDepartmentDescriptionShort				,'|'
											,ec.OrganisationCodeCommissioner			,'|'
											,ec.PersonId								,'|'
											,ec.Age										,'|'
											,ec.Gender									,'|'
											,ec.LocalPatientIdentifier					,'|'
											,ec.GeneralPractice							,'|'
											,ec.[Site]									,'|'
											,ec.OutputArea								,'|'
											,ec.LowerSuperOutputAreaCode				,'|'
											,olwm.LocalAuthorityCode					,'|'
											,olwm.LocalAuthorityName					,'|'
											,ec.PostcodeDistrict						,'|'
											,ec.ResidenceCcg							,'|'
											,po.OrganisationName						,'|'
											,eth.EthnicCategory							,'|'
											,eth.EthnicCategory							,'|'
											,ec.AccommodationStatus						,'|'
											,acoms.Term									,'|'
											,ec.ArrivalDate								,'|'
											,ec.ArrivalTime								,'|'
											,ec.ArrivalPlanned							,'|'
											,ec.ArrivalMode								,'|'
											,am.Term									,'|'
											,ec.ReferredToServiceDate					,'|'
											,ec.ReferredToServiceTime					,'|'
											,ec.InitialAssessmentDate					,'|'
											,ec.InitialAssessmentTime					,'|'
											,ec.SeenForTreatmentDate					,'|'
											,ec.SeenForTreatmentTime					,'|'
											,ec.ConclusionDate							,'|'
											,ec.ConclusionTime							,'|'
											,ec.DepartureDate							,'|'
											,ec.DepartureTime							,'|'
											,ec.DecisionToAdmitDate						,'|'
											,ec.DecisionToAdmitTime						,'|'
											,ec.DecisionToAdmitTimeSinceArrival			,'|'
											,ec.DiagnosesCode							,'|'
											,di.Term									,'|'
											,ec.DiagnosesCode1							,'|'
											,di1.Term									,'|'
											,ec.DiagnosesCode2							,'|'
											,di2.Term									,'|'
											,ec.DiagnosesCode3							,'|'
											,di3.Term									,'|'
											,ec.InvestigationCode						,'|'
											,i.Term										,'|'
											,ec.InvestigationCode1						,'|'
											,i1.Term									,'|'
											,ec.InvestigationCode2						,'|'
											,i2.Term									,'|'
											,ec.TreatmentCode							,'|'
											,t.Term										,'|'
											,ec.TreatmentCode1							,'|'
											,t1.Term									,'|'
											,ec.TreatmentCode2							,'|'
											,t2.Term									,'|'
											,ec.TreatmentCode3							,'|'
											,t3.Term									,'|'
											,ec.HealthResourceGroup						,'|'
											,ec.AttendanceCategory						,'|'
											,ac.[Description]							,'|'
											,ec.AmbulanceIncidentNumber					,'|'
											,ec.ConveyingAmbulanceTrust					,'|'
											,ec.AttendanceSource						,'|'
											,ats.Term									,'|'
											,o2.ProviderShortName						,'|'
											,ec.ReferredToService						,'|'
											,rs.Term									,'|'
											,ec.ReferredToService1						,'|'
											,rs1.Term									,'|'
											,ec.DischargeStatus							,'|'
											,ds.Term									,'|'
											,ec.DischargeDestination					,'|'
											,dd.Term									,'|'
											,ec.ChiefComplaint							,'|'
											,cc.Term									,'|'
											,ec.Acuity									,'|'
											,ay.Term									,'|'
											,ec.ComorbiditiesCode						,'|'
											,co.Term									,'|'
											,ec.ComorbiditiesCode1						,'|'
											,co1.Term									,'|'
											,ec.ComorbiditiesCode2						,'|'
											,co2.Term									,'|'
											,ec.AecRelated								,'|'
											,ec.EquivalentAeInvestigationCode			,'|'
											,iv.[Description]							,'|'
											,ec.EquivalentAeInvestigationCode1			,'|'
											,iv1.[Description]							,'|'
											,ec.EquivalentAeInvestigationCode2			,'|'
											,iv2.[Description]							,'|'
											,ec.EquivalentAeTreatmentCode				,'|'
											,tr.AeTreatment								,'|'
											,ec.EquivalentAeTreatmentCode1				,'|'
											,tr1.AeTreatment							,'|'
											,ec.EquivalentAeTreatmentCode2				,'|'
											,tr2.AeTreatment							,'|'
											,ec.EquivalentAeTreatmentCode3				,'|'
											,tr3.AeTreatment							,'|'
											,ec.InjuryIntentCode						,'|'
											,ii.Term									,'|'
											,ec.InjuryMechanismCode						,'|'
											,im.Term									,'|'
											,ec.InjuryPlaceDate							,'|'
											,ec.InjuryPlaceTime							,'|'
											,ec.InjuryPlaceCode							,'|'
											,ipc.Term									,'|'
											,ec.InjuryActivityStatus					,'|'
											,ias.Term									,'|'
											,ec.InjuryActivityType						,'|'
											,iat.Term									,'|'
											,ec.AlcoholDrugInvolvementsCode				,'|'
											,ec.AlcoholDrugInvolvementsCode1			,'|'
											,ad1.Term									,'|'
											,ec.AlcoholDrugInvolvementsCode2			,'|'
											,ad2.Term									,'|'
											,ec.AlcoholDrugInvolvementsCode3			,'|'
											,ad3.Term									,'|'
											,ec.Tariff									,'|'
											,CONCAT(ec.FinalPrice
											,ec.ClinicalCodedScoredAssessmentToolTypeCode		,'|'
											,att.Term											,'|'
											,ec.ClinicalCodedScoredAssessmentToolTypeCode1		,'|'
											,att1.Term											,'|'
											,ec.ClinicalCodedScoredAssessmentToolTypeCode2		,'|'
											,att2.Term											,'|'
											,ec.ClinicalCodedScoredAssessmentToolTypeCode3		,'|'
											,att3.Term											,'|'
											,ec.ClinicalCodedScoredAssessmentPersonScore		,'|'
											,aps.Term											,'|'
											,ec.ClinicalCodedScoredAssessmentPersonScore1		,'|'
											,aps1.Term											,'|'
											,ec.ClinicalCodedScoredAssessmentPersonScore2		,'|'
											,aps2.Term											,'|'
											,ec.ClinicalCodedScoredAssessmentPersonScore3		,'|'
											,aps3.Term											,'|'
											,ec.ValidationTimestamp								,'|'
											,ec.ValidationTimestamp1							,'|'
											,ec.ValidationTimestamp2							,'|'
											,ec.ValidationTimestamp3							,'|'
											,ec.ClinicalCodedFindingsCode						,'|'
											,cfc.Term											,'|'
											,ec.ClinicalCodedFindingsCode1						,'|'
											,cfc1.Term											,'|'
											,ec.ClinicalCodedFindingsCode2						,'|'
											,cfc2.Term											,'|'
											,ec.ClinicalCodedFindingsCode3						,'|'
											,cfc3.Term											,'|'
											,ec.ClinicalCodedFindingsCodeTimestamp				,'|'
											,ec.ClinicalCodedFindingsCodeTimestamp1				,'|'
											,ec.ClinicalCodedFindingsCodeTimestamp2				,'|'
											,ec.ClinicalCodedFindingsCodeTimestamp3				,'|'											
											))) AS RecordVersion
	FROM #Ecds AS ec
		LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeDepartment] AS d
			ON ec.DepartmentTypeCode  = d.AeDepartmentId
		LEFT OUTER JOIN [$(OdsDbName)].[dbo].[ProviderOrganisation] AS o
			ON ec.ProviderCode = o.ProviderOrganisationId
		LEFT OUTER JOIN [$(OdsDbName)].[dbo].[PrimaryCareOrganisation] AS po
			ON ec.ResidenceCcg = po.PrimaryCareOrganisationId
		LEFT OUTER JOIN [$(OdsDbName)].[dbo].[ProviderOrganisation] AS o2
			ON ec.ConveyingAmbulanceTrust = o2.ProviderOrganisationId
		LEFT OUTER JOIN [$(OdsDbName)].[dbo].[EthnicCategory] AS eth
			ON ec.EthnicCategory = eth.EthnicCategoryId
		LEFT OUTER JOIN #Snomed AS am
			ON ec.ArrivalMode = am.ConceptId
		LEFT OUTER JOIN #Snomed AS di
			ON ec.DiagnosesCode = CAST(di.ConceptId AS VARCHAR(50))
		LEFT OUTER JOIN #Snomed AS di1
			ON ec.DiagnosesCode1 = di1.ConceptId
		LEFT OUTER JOIN #Snomed AS di2
			ON ec.DiagnosesCode2 = di2.ConceptId
		LEFT OUTER JOIN #Snomed AS di3
			ON ec.DiagnosesCode3 = di3.ConceptId
		LEFT OUTER JOIN #Snomed AS i
			ON ec.InvestigationCode = CAST(i.ConceptId AS VARCHAR(50))
		LEFT OUTER JOIN #Snomed AS i1
			ON ec.InvestigationCode1 = i1.ConceptId
		LEFT OUTER JOIN #Snomed AS i2
			ON ec.InvestigationCode2 = i2.ConceptId
		LEFT OUTER JOIN #Snomed AS t
			ON ec.TreatmentCode = CAST(t.ConceptId AS VARCHAR(50))
		LEFT OUTER JOIN #Snomed AS t1
			ON ec.TreatmentCode1 = t1.ConceptId
		LEFT OUTER JOIN #Snomed AS t2
			ON ec.TreatmentCode2 = t2.ConceptId
		LEFT OUTER JOIN #Snomed AS t3
			ON ec.TreatmentCode3 = t3.ConceptId
		LEFT OUTER JOIN [$(OdsDbName)].dbo.AeAttendanceCategory AS ac
			ON ec.AttendanceCategory = ac.AeAttendanceCategoryId
		LEFT OUTER JOIN #Snomed AS rs
			ON ec.ReferredToService = CAST(rs.ConceptId AS VARCHAR(50))
		LEFT OUTER JOIN #Snomed AS rs1
			ON ec.ReferredToService1 = CAST(rs1.ConceptId AS VARCHAR(50))
		LEFT OUTER JOIN #Snomed AS ds
			ON ec.DischargeStatus = ds.ConceptId
		LEFT OUTER JOIN #Snomed AS dd
			ON ec.DischargeDestination = dd.ConceptId
		LEFT OUTER JOIN #Snomed AS cc
			ON ec.ChiefComplaint = cc.ConceptId
		LEFT OUTER JOIN #Snomed AS ay
			ON ec.Acuity = ay.ConceptId
		LEFT OUTER JOIN #Snomed AS att
			ON ec.ClinicalCodedScoredAssessmentToolTypeCode = CAST(att.ConceptId AS varchar(50))
		LEFT OUTER JOIN #Snomed AS att1
			ON ec.ClinicalCodedScoredAssessmentToolTypeCode1 = att.ConceptId
		LEFT OUTER JOIN #Snomed AS att2
			ON ec.ClinicalCodedScoredAssessmentToolTypeCode2 = att.ConceptId
		LEFT OUTER JOIN #Snomed AS att3
			ON ec.ClinicalCodedScoredAssessmentToolTypeCode3 = att3.ConceptId
		LEFT OUTER JOIN #Snomed AS aps
			ON ec.ClinicalCodedScoredAssessmentPersonScore = CAST(aps.ConceptId AS VARCHAR(50))
		LEFT OUTER JOIN #Snomed AS aps1
			ON ec.ClinicalCodedScoredAssessmentPersonScore1 = aps1.ConceptId
		LEFT OUTER JOIN #Snomed AS aps2
			ON ec.ClinicalCodedScoredAssessmentPersonScore2 = aps2.ConceptId
		LEFT OUTER JOIN #Snomed AS aps3
			ON ec.ClinicalCodedScoredAssessmentPersonScore3 = aps3.ConceptId
		LEFT OUTER JOIN #Snomed AS vt
			ON ec.ValidationTimestamp = CAST(vt.ConceptId AS VARCHAR(50))
		LEFT OUTER JOIN #Snomed AS cfc
			ON ec.ClinicalCodedFindingsCode = CAST(cfc.ConceptId AS VARCHAR(50))
		LEFT OUTER JOIN #Snomed AS cfc1
			ON ec.ClinicalCodedFindingsCode1 = cfc1.ConceptId
		LEFT OUTER JOIN #Snomed AS cfc2
			ON ec.ClinicalCodedFindingsCode2 = cfc2.ConceptId
		LEFT OUTER JOIN #Snomed AS cfc3
			ON ec.ClinicalCodedFindingsCode3 = cfc3.ConceptId
		LEFT OUTER JOIN #Snomed AS co
			ON ec.ComorbiditiesCode = CAST(co.ConceptId AS VARCHAR(50))
		LEFT OUTER JOIN #Snomed AS co1
			ON ec.ComorbiditiesCode1 = co1.ConceptId
		LEFT OUTER JOIN #Snomed AS co2
			ON ec.ComorbiditiesCode2 = co2.ConceptId
		LEFT OUTER JOIN #Snomed AS ii
			ON ec.InjuryIntentCode = ii.ConceptId
		LEFT OUTER JOIN #Snomed AS im
			ON ec.InjuryMechanismCode = im.ConceptId
		LEFT OUTER JOIN #Snomed AS ipc
			ON ec.InjuryPlaceCode = ipc.ConceptId
		LEFT OUTER JOIN #Snomed AS ias
			ON ec.InjuryActivityStatus = ias.ConceptId
		LEFT OUTER JOIN #Snomed AS iat
			ON ec.InjuryActivityType = iat.ConceptId
		LEFT OUTER JOIN #Snomed AS ad1
			ON ec.AlcoholDrugInvolvementsCode1 = ad1.ConceptId
		LEFT OUTER JOIN #Snomed AS ad2
			ON ec.AlcoholDrugInvolvementsCode2 = ad2.ConceptId
		LEFT OUTER JOIN #Snomed AS ad3
			ON ec.AlcoholDrugInvolvementsCode3 = ad3.ConceptId
		LEFT OUTER JOIN #Snomed AS ats
			ON ec.AttendanceSource = ats.ConceptId
		LEFT OUTER JOIN #Snomed AS acoms
			ON ec.AccommodationStatus = acoms.ConceptId
		LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeInvestigation] AS iv
			ON ec.EquivalentAeInvestigationCode = iv.AeInvestigationId
		LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeInvestigation] AS iv1
			ON ec.EquivalentAeInvestigationCode1 = iv1.AeInvestigationId
		LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeInvestigation] AS iv2
			ON ec.EquivalentAeInvestigationCode2 = iv2.AeInvestigationId
		LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeTreatment] AS tr
			ON ec.EquivalentAeTreatmentCode = tr.AeTreatmentId
		LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeTreatment] AS tr1
			ON ec.EquivalentAeTreatmentCode1 = tr1.AeTreatmentId
		LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeTreatment] AS tr2
			ON ec.EquivalentAeTreatmentCode2 = tr2.AeTreatmentId
		LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeTreatment] AS tr3
			ON ec.EquivalentAeTreatmentCode3 = tr3.AeTreatmentId
		LEFT OUTER JOIN [$(OdsDbName)].ref.OnsLaWardMapping AS olwm
			ON ec.LowerSuperOutputAreaCode = olwm.LowerSuperOutputAreaCode
	-- Removing rows where CDS_Unique_Identifier is NULL as they cannot be matched on
	WHERE ec.EmergencyCareId IS NOT NULL
	AND ec.RowNum = 1) AS SOURCE
		ON TARGET.EmergencyCareId = SOURCE.EmergencyCareId
		AND TARGET.ProviderCode = SOURCE.ProviderCode
	WHEN NOT MATCHED BY TARGET THEN
	INSERT ( EmergencyCareId
		,SourceSystemKey
		,ProviderCode
		,[Provider]
		,DepartmentTypeCode
		,DepartmentType
		,OrganisationCodeCommissioner
		,PersonId
		,Age
		,Gender
		,LocalPatientIdentifier
		,GeneralPractice
		,[Site]
		,OutputArea
		,LowerSuperOutputAreaCode
		,LocalAuthorityCode
		,LocalAuthorityName
		,PostcodeDistrict
		,ResidenceCcg
		,ResidenceCcgDescription
		,EthnicCategory
		,EthnicCategoryDescription
		,AccommodationStatus
		,AccommodationStatusDescription
		,ArrivalDate
		,ArrivalTime
		,ArrivalMode
		,ArrivalModeDescription
		,ArrivalPlanned
		,ReferredToServiceDate
		,ReferredToServiceTime
		,InitialAssessmentDate
		,InitialAssessmentTime
		,SeenForTreatmentDate
		,SeenForTreatmentTime
		,ConclusionDate
		,ConclusionTime
		,DepartureDate
		,DepartureTime
		,DecisionToAdmitDate
		,DecisionToAdmitTime
		,DecisionToAdmitTimeSinceArrival
		,DiagnosesCode
		,DiagnosesDescription
		,DiagnosesCode1
		,DiagnosesDescription1
		,DiagnosesCode2
		,DiagnosesDescription2
		,DiagnosesCode3
		,DiagnosesDescription3
		,InvestigationCode
		,InvestigationDescription
		,InvestigationCode1
		,InvestigationDescription1
		,InvestigationCode2
		,InvestigationDescription2
		,TreatmentCode
		,TreatmentDescription
		,TreatmentCode1
		,TreatmentDescription1
		,TreatmentCode2
		,TreatmentDescription2
		,TreatmentCode3
		,TreatmentDescription3
		,HealthResourceGroup
		,AttendanceCategory
		,AttendanceCategoryDescription
		,AmbulanceIncidentNumber
		,ConveyingAmbulanceTrust
		,ConveyingAmbulanceTrustDescription
		,AttendanceSource
		,AttendanceSourceDescription
		,ReferredToService				
		,ReferredToServiceDescription
		,ReferredToService1				
		,ReferredToService1Description
		,DischargeStatus
		,DischargeStatusDescription
		,DischargeDestination
		,DischargeDestinationDescription
		,ChiefComplaint
		,ChiefComplaintDescription
		,Acuity
		,AcuityDescription
		,ComorbiditiesCode
		,ComorbiditiesCodeDescription
		,ComorbiditiesCode1
		,ComorbiditiesCode1Description
		,ComorbiditiesCode2
		,ComorbiditiesCode2Description
		,AecRelated
		,EquivalentAeInvestigationCode
		,EquivalentAeInvestigationCodeDescription
		,EquivalentAeInvestigationCode1
		,EquivalentAeInvestigationCode1Description
		,EquivalentAeInvestigationCode2
		,EquivalentAeInvestigationCode2Description
		,EquivalentAeTreatmentCode
		,EquivalentAeTreatmentCodeDescription
		,EquivalentAeTreatmentCode1
		,EquivalentAeTreatmentCode1Description
		,EquivalentAeTreatmentCode2
		,EquivalentAeTreatmentCode2Description
		,EquivalentAeTreatmentCode3
		,EquivalentAeTreatmentCode3Description
		,InjuryIntentCode
		,InjuryIntentDescription
		,InjuryMechanismCode
		,InjuryMechanismDescription
		,InjuryPlaceDate
		,InjuryPlaceTime
		,InjuryPlaceCode
		,InjuryPlaceDescription
		,InjuryActivityStatus
		,InjuryActivityStatusDescription
		,InjuryActivityType
		,InjuryActivityTypeDescription
		,AlcoholDrugInvolvementsCode
		,AlcoholDrugInvolvementsCode1
		,AlcoholDrugInvolvements1Description
		,AlcoholDrugInvolvementsCode2
		,AlcoholDrugInvolvements2Description
		,AlcoholDrugInvolvementsCode3
		,AlcoholDrugInvolvements3Description
		,Tariff
		,FinalPrice
		,ClinicalCodedScoredAssessmentToolTypeCode
		,ClinicalCodedScoredAssessmentToolTypeCodeDescription
		,ClinicalCodedScoredAssessmentToolTypeCode1
		,ClinicalCodedScoredAssessmentToolTypeCode1Description
		,ClinicalCodedScoredAssessmentToolTypeCode2
		,ClinicalCodedScoredAssessmentToolTypeCode2Description
		,ClinicalCodedScoredAssessmentToolTypeCode3
		,ClinicalCodedScoredAssessmentToolTypeCode3Description
		,ClinicalCodedScoredAssessmentPersonScore
		,ClinicalCodedScoredAssessmentPersonScoreDescription
		,ClinicalCodedScoredAssessmentPersonScore1
		,ClinicalCodedScoredAssessmentPersonScore1Description
		,ClinicalCodedScoredAssessmentPersonScore2
		,ClinicalCodedScoredAssessmentPersonScore2Description
		,ClinicalCodedScoredAssessmentPersonScore3
		,ClinicalCodedScoredAssessmentPersonScore3Description
		,ValidationTimestamp
		,ValidationTimestamp1
		,ValidationTimestamp2
		,ValidationTimestamp3
		,ClinicalCodedFindingsCode
		,ClinicalCodedFindingsCodeDescription
		,ClinicalCodedFindingsCode1
		,ClinicalCodedFindingsCode1Description
		,ClinicalCodedFindingsCode2
		,ClinicalCodedFindingsCode2Description
		,ClinicalCodedFindingsCode3
		,ClinicalCodedFindingsCode3Description
		,ClinicalCodedFindingsCodeTimestamp
		,ClinicalCodedFindingsCodeTimestamp1
		,ClinicalCodedFindingsCodeTimestamp2
		,ClinicalCodedFindingsCodeTimestamp3
		,IsActive
		,InsertUser
		,InsertTime
		,UpdateUser
		,UpdateTime
        ,RecordVersion)
	VALUES ( SOURCE.EmergencyCareId
			,SOURCE.SourceSystemKey
			,SOURCE.ProviderCode
			,SOURCE.[Provider]
			,SOURCE.DepartmentTypeCode
			,SOURCE.DepartmentType
			,SOURCE.OrganisationCodeCommissioner
			,SOURCE.PersonId
			,SOURCE.Age
			,SOURCE.Gender
			,SOURCE.LocalPatientIdentifier
			,SOURCE.GeneralPractice
			,SOURCE.[Site]
			,SOURCE.OutputArea
			,SOURCE.LowerSuperOutputAreaCode
			,SOURCE.LocalAuthorityCode
			,SOURCE.LocalAuthorityName
			,SOURCE.PostcodeDistrict
			,SOURCE.ResidenceCcg
			,SOURCE.ResidenceCcgDescription
			,SOURCE.EthnicCategory
			,SOURCE.EthnicCategoryDescription
			,SOURCE.AccommodationStatus
			,SOURCE.AccommodationStatusDescription
			,SOURCE.ArrivalDate
			,SOURCE.ArrivalTime
			,SOURCE.ArrivalMode
			,SOURCE.ArrivalModeDescription
			,SOURCE.ArrivalPlanned
			,SOURCE.ReferredToServiceDate
			,SOURCE.ReferredToServiceTime
			,SOURCE.InitialAssessmentDate
			,SOURCE.InitialAssessmentTime
			,SOURCE.SeenForTreatmentDate
			,SOURCE.SeenForTreatmentTime
			,SOURCE.ConclusionDate
			,SOURCE.ConclusionTime
			,SOURCE.DepartureDate
			,SOURCE.DepartureTime
			,SOURCE.DecisionToAdmitDate
			,SOURCE.DecisionToAdmitTime
			,SOURCE.DecisionToAdmitTimeSinceArrival
			,SOURCE.DiagnosesCode
			,SOURCE.DiagnosesDescription
			,SOURCE.DiagnosesCode1
			,SOURCE.DiagnosesDescription1
			,SOURCE.DiagnosesCode2
			,SOURCE.DiagnosesDescription2
			,SOURCE.DiagnosesCode3
			,SOURCE.DiagnosesDescription3
			,SOURCE.InvestigationCode
			,SOURCE.InvestigationDescription
			,SOURCE.InvestigationCode1
			,SOURCE.InvestigationDescription1
			,SOURCE.InvestigationCode2
			,SOURCE.InvestigationDescription2
			,SOURCE.TreatmentCode
			,SOURCE.TreatmentDescription
			,SOURCE.TreatmentCode1
			,SOURCE.TreatmentDescription1
			,SOURCE.TreatmentCode2
			,SOURCE.TreatmentDescription2
			,SOURCE.TreatmentCode3
			,SOURCE.TreatmentDescription3
			,SOURCE.HealthResourceGroup
			,SOURCE.AttendanceCategory
			,SOURCE.AttendanceCategoryDescription
			,SOURCE.AmbulanceIncidentNumber
			,SOURCE.ConveyingAmbulanceTrust
			,SOURCE.ConveyingAmbulanceTrustDescription
			,SOURCE.AttendanceSource
			,SOURCE.AttendanceSourceDescription
			,SOURCE.ReferredToService				
			,SOURCE.ReferredToServiceDescription
			,SOURCE.ReferredToService1				
			,SOURCE.ReferredToService1Description
			,SOURCE.DischargeStatus
			,SOURCE.DischargeStatusDescription
			,SOURCE.DischargeDestination
			,SOURCE.DischargeDestinationDescription
			,SOURCE.ChiefComplaint
			,SOURCE.ChiefComplaintDescription
			,SOURCE.Acuity
			,SOURCE.AcuityDescription
			,SOURCE.ComorbiditiesCode
			,SOURCE.ComorbiditiesCodeDescription
			,SOURCE.ComorbiditiesCode1
			,SOURCE.ComorbiditiesCode1Description
			,SOURCE.ComorbiditiesCode2
			,SOURCE.ComorbiditiesCode2Description
			,SOURCE.AecRelated
			,SOURCE.EquivalentAeInvestigationCode
			,SOURCE.EquivalentAeInvestigationCodeDescription
			,SOURCE.EquivalentAeInvestigationCode1
			,SOURCE.EquivalentAeInvestigationCode1Description
			,SOURCE.EquivalentAeInvestigationCode2
			,SOURCE.EquivalentAeInvestigationCode2Description
			,SOURCE.EquivalentAeTreatmentCode
			,SOURCE.EquivalentAeTreatmentCodeDescription
			,SOURCE.EquivalentAeTreatmentCode1
			,SOURCE.EquivalentAeTreatmentCode1Description
			,SOURCE.EquivalentAeTreatmentCode2
			,SOURCE.EquivalentAeTreatmentCode2Description
			,SOURCE.EquivalentAeTreatmentCode3
			,SOURCE.EquivalentAeTreatmentCode3Description
			,SOURCE.InjuryIntentCode
			,SOURCE.InjuryIntentDescription
			,SOURCE.InjuryMechanismCode
			,SOURCE.InjuryMechanismDescription
			,SOURCE.InjuryPlaceDate
			,SOURCE.InjuryPlaceTime
			,SOURCE.InjuryPlaceCode
			,SOURCE.InjuryPlaceDescription
			,SOURCE.InjuryActivityStatus
			,SOURCE.InjuryActivityStatusDescription
			,SOURCE.InjuryActivityType
			,SOURCE.InjuryActivityTypeDescription
			,SOURCE.AlcoholDrugInvolvementsCode
			,SOURCE.AlcoholDrugInvolvementsCode1
			,SOURCE.AlcoholDrugInvolvements1Description
			,SOURCE.AlcoholDrugInvolvementsCode2
			,SOURCE.AlcoholDrugInvolvements2Description
			,SOURCE.AlcoholDrugInvolvementsCode3
			,SOURCE.AlcoholDrugInvolvements3Description
			,SOURCE.Tariff
			,SOURCE.FinalPrice
			,SOURCE.ClinicalCodedScoredAssessmentToolTypeCode
			,SOURCE.ClinicalCodedScoredAssessmentToolTypeCodeDescription
			,SOURCE.ClinicalCodedScoredAssessmentToolTypeCode1
			,SOURCE.ClinicalCodedScoredAssessmentToolTypeCode1Description
			,SOURCE.ClinicalCodedScoredAssessmentToolTypeCode2
			,SOURCE.ClinicalCodedScoredAssessmentToolTypeCode2Description
			,SOURCE.ClinicalCodedScoredAssessmentToolTypeCode3
			,SOURCE.ClinicalCodedScoredAssessmentToolTypeCode3Description
			,SOURCE.ClinicalCodedScoredAssessmentPersonScore
			,SOURCE.ClinicalCodedScoredAssessmentPersonScoreDescription
			,SOURCE.ClinicalCodedScoredAssessmentPersonScore1
			,SOURCE.ClinicalCodedScoredAssessmentPersonScore1Description
			,SOURCE.ClinicalCodedScoredAssessmentPersonScore2
			,SOURCE.ClinicalCodedScoredAssessmentPersonScore2Description
			,SOURCE.ClinicalCodedScoredAssessmentPersonScore3
			,SOURCE.ClinicalCodedScoredAssessmentPersonScore3Description
			,SOURCE.ValidationTimestamp
			,SOURCE.ValidationTimestamp1
			,SOURCE.ValidationTimestamp2
			,SOURCE.ValidationTimestamp3
			,SOURCE.ClinicalCodedFindingsCode
			,SOURCE.ClinicalCodedFindingsCodeDescription
			,SOURCE.ClinicalCodedFindingsCode1
			,SOURCE.ClinicalCodedFindingsCode1Description
			,SOURCE.ClinicalCodedFindingsCode2
			,SOURCE.ClinicalCodedFindingsCode2Description
			,SOURCE.ClinicalCodedFindingsCode3
			,SOURCE.ClinicalCodedFindingsCode3Description
			,SOURCE.ClinicalCodedFindingsCodeTimestamp
			,SOURCE.ClinicalCodedFindingsCodeTimestamp1
			,SOURCE.ClinicalCodedFindingsCodeTimestamp2
			,SOURCE.ClinicalCodedFindingsCodeTimestamp3
			,1
			,@InsertUpdateUser
			,@InsertUpdateTime
			,@InsertUpdateUser
			,@InsertUpdateTime
			,SOURCE.RecordVersion)
    -- Handle updates using RecordVersion
	WHEN MATCHED
    AND SOURCE.RecordVersion <> TARGET.RecordVersion THEN
    UPDATE SET TARGET.SourceSystemKey									 	= SOURCE.SourceSystemKey
			,TARGET.[Provider]											 	= SOURCE.[Provider]
			,TARGET.DepartmentTypeCode									 	= SOURCE.DepartmentTypeCode
			,TARGET.DepartmentType										 	= SOURCE.DepartmentType
			,TARGET.OrganisationCodeCommissioner						 	= SOURCE.OrganisationCodeCommissioner
			,TARGET.PersonId											 	= SOURCE.PersonId
			,TARGET.Age													 	= SOURCE.Age
			,TARGET.Gender												 	= SOURCE.Gender
			,TARGET.LocalPatientIdentifier								 	= SOURCE.LocalPatientIdentifier
			,TARGET.GeneralPractice										 	= SOURCE.GeneralPractice
			,TARGET.[Site]												 	= SOURCE.[Site]
			,TARGET.OutputArea											 	= SOURCE.OutputArea
			,TARGET.LowerSuperOutputAreaCode							 	= SOURCE.LowerSuperOutputAreaCode
			,TARGET.LocalAuthorityCode									 	= SOURCE.LocalAuthorityCode
			,TARGET.LocalAuthorityName									 	= SOURCE.LocalAuthorityName
			,TARGET.PostcodeDistrict									 	= SOURCE.PostcodeDistrict
			,TARGET.ResidenceCcg										 	= SOURCE.ResidenceCcg
			,TARGET.ResidenceCcgDescription								 	= SOURCE.ResidenceCcgDescription
			,TARGET.EthnicCategory										 	= SOURCE.EthnicCategory
			,TARGET.EthnicCategoryDescription							 	= SOURCE.EthnicCategoryDescription
			,TARGET.AccommodationStatus									 	= SOURCE.AccommodationStatus
			,TARGET.AccommodationStatusDescription						 	= SOURCE.AccommodationStatusDescription
			,TARGET.ArrivalDate											 	= SOURCE.ArrivalDate
			,TARGET.ArrivalTime											 	= SOURCE.ArrivalTime
			,TARGET.ArrivalMode											 	= SOURCE.ArrivalMode
			,TARGET.ArrivalModeDescription								 	= SOURCE.ArrivalModeDescription
			,TARGET.ArrivalPlanned										 	= SOURCE.ArrivalPlanned
			,TARGET.ReferredToServiceDate								 	= SOURCE.ReferredToServiceDate
			,TARGET.ReferredToServiceTime								 	= SOURCE.ReferredToServiceTime
			,TARGET.InitialAssessmentDate								 	= SOURCE.InitialAssessmentDate
			,TARGET.InitialAssessmentTime								 	= SOURCE.InitialAssessmentTime
			,TARGET.SeenForTreatmentDate								 	= SOURCE.SeenForTreatmentDate
			,TARGET.SeenForTreatmentTime								 	= SOURCE.SeenForTreatmentTime
			,TARGET.ConclusionDate										 	= SOURCE.ConclusionDate
			,TARGET.ConclusionTime										 	= SOURCE.ConclusionTime
			,TARGET.DepartureDate										 	= SOURCE.DepartureDate
			,TARGET.DepartureTime										 	= SOURCE.DepartureTime
			,TARGET.DecisionToAdmitDate									 	= SOURCE.DecisionToAdmitDate
			,TARGET.DecisionToAdmitTime									 	= SOURCE.DecisionToAdmitTime
			,TARGET.DecisionToAdmitTimeSinceArrival						 	= SOURCE.DecisionToAdmitTimeSinceArrival
			,TARGET.DiagnosesCode										 	= SOURCE.DiagnosesCode
			,TARGET.DiagnosesDescription								 	= SOURCE.DiagnosesDescription
			,TARGET.DiagnosesCode1										 	= SOURCE.DiagnosesCode1
			,TARGET.DiagnosesDescription1								 	= SOURCE.DiagnosesDescription1
			,TARGET.DiagnosesCode2										 	= SOURCE.DiagnosesCode2
			,TARGET.DiagnosesDescription2								 	= SOURCE.DiagnosesDescription2
			,TARGET.DiagnosesCode3										 	= SOURCE.DiagnosesCode3
			,TARGET.DiagnosesDescription3								 	= SOURCE.DiagnosesDescription3
			,TARGET.InvestigationCode									 	= SOURCE.InvestigationCode
			,TARGET.InvestigationDescription							 	= SOURCE.InvestigationDescription
			,TARGET.InvestigationCode1									 	= SOURCE.InvestigationCode1
			,TARGET.InvestigationDescription1							 	= SOURCE.InvestigationDescription1
			,TARGET.InvestigationCode2									 	= SOURCE.InvestigationCode2
			,TARGET.InvestigationDescription2							 	= SOURCE.InvestigationDescription2
			,TARGET.TreatmentCode										 	= SOURCE.TreatmentCode
			,TARGET.TreatmentDescription								 	= SOURCE.TreatmentDescription
			,TARGET.TreatmentCode1										 	= SOURCE.TreatmentCode1
			,TARGET.TreatmentDescription1								 	= SOURCE.TreatmentDescription1
			,TARGET.TreatmentCode2										 	= SOURCE.TreatmentCode2
			,TARGET.TreatmentDescription2								 	= SOURCE.TreatmentDescription2
			,TARGET.TreatmentCode3										 	= SOURCE.TreatmentCode3
			,TARGET.TreatmentDescription3								 	= SOURCE.TreatmentDescription3
			,TARGET.HealthResourceGroup									 	= SOURCE.HealthResourceGroup
			,TARGET.AttendanceCategory									 	= SOURCE.AttendanceCategory
			,TARGET.AttendanceCategoryDescription						 	= SOURCE.AttendanceCategoryDescription
			,TARGET.AmbulanceIncidentNumber								 	= SOURCE.AmbulanceIncidentNumber
			,TARGET.ConveyingAmbulanceTrust								 	= SOURCE.ConveyingAmbulanceTrust
			,TARGET.ConveyingAmbulanceTrustDescription					 	= SOURCE.ConveyingAmbulanceTrustDescription
			,TARGET.AttendanceSource									 	= SOURCE.AttendanceSource
			,TARGET.AttendanceSourceDescription							 	= SOURCE.AttendanceSourceDescription
			,TARGET.ReferredToService									 	= SOURCE.ReferredToService
			,TARGET.ReferredToServiceDescription						 	= SOURCE.ReferredToServiceDescription
			,TARGET.ReferredToService1									 	= SOURCE.ReferredToService1
			,TARGET.ReferredToService1Description						 	= SOURCE.ReferredToService1Description
			,TARGET.DischargeStatus										 	= SOURCE.DischargeStatus
			,TARGET.DischargeStatusDescription							 	= SOURCE.DischargeStatusDescription
			,TARGET.DischargeDestination								 	= SOURCE.DischargeDestination
			,TARGET.DischargeDestinationDescription						 	= SOURCE.DischargeDestinationDescription
			,TARGET.ChiefComplaint										 	= SOURCE.ChiefComplaint
			,TARGET.ChiefComplaintDescription							 	= SOURCE.ChiefComplaintDescription
			,TARGET.Acuity												 	= SOURCE.Acuity
			,TARGET.AcuityDescription									 	= SOURCE.AcuityDescription
			,TARGET.ComorbiditiesCode									 	= SOURCE.ComorbiditiesCode
			,TARGET.ComorbiditiesCodeDescription						 	= SOURCE.ComorbiditiesCodeDescription
			,TARGET.ComorbiditiesCode1									 	= SOURCE.ComorbiditiesCode1
			,TARGET.ComorbiditiesCode1Description						 	= SOURCE.ComorbiditiesCode1Description
			,TARGET.ComorbiditiesCode2									 	= SOURCE.ComorbiditiesCode2
			,TARGET.ComorbiditiesCode2Description						 	= SOURCE.ComorbiditiesCode2Description
			,TARGET.AecRelated											 	= SOURCE.AecRelated
			,TARGET.EquivalentAeInvestigationCode						 	= SOURCE.EquivalentAeInvestigationCode
			,TARGET.EquivalentAeInvestigationCodeDescription			 	= SOURCE.EquivalentAeInvestigationCodeDescription
			,TARGET.EquivalentAeInvestigationCode1						 	= SOURCE.EquivalentAeInvestigationCode1
			,TARGET.EquivalentAeInvestigationCode1Description			 	= SOURCE.EquivalentAeInvestigationCode1Description
			,TARGET.EquivalentAeInvestigationCode2						 	= SOURCE.EquivalentAeInvestigationCode2
			,TARGET.EquivalentAeInvestigationCode2Description			 	= SOURCE.EquivalentAeInvestigationCode2Description
			,TARGET.EquivalentAeTreatmentCode							 	= SOURCE.EquivalentAeTreatmentCode
			,TARGET.EquivalentAeTreatmentCodeDescription				 	= SOURCE.EquivalentAeTreatmentCodeDescription
			,TARGET.EquivalentAeTreatmentCode1							 	= SOURCE.EquivalentAeTreatmentCode1
			,TARGET.EquivalentAeTreatmentCode1Description				 	= SOURCE.EquivalentAeTreatmentCode1Description
			,TARGET.EquivalentAeTreatmentCode2							 	= SOURCE.EquivalentAeTreatmentCode2
			,TARGET.EquivalentAeTreatmentCode2Description				 	= SOURCE.EquivalentAeTreatmentCode2Description
			,TARGET.EquivalentAeTreatmentCode3							 	= SOURCE.EquivalentAeTreatmentCode3
			,TARGET.EquivalentAeTreatmentCode3Description				 	= SOURCE.EquivalentAeTreatmentCode3Description
			,TARGET.InjuryIntentCode									 	= SOURCE.InjuryIntentCode
			,TARGET.InjuryIntentDescription								 	= SOURCE.InjuryIntentDescription
			,TARGET.InjuryMechanismCode									 	= SOURCE.InjuryMechanismCode
			,TARGET.InjuryMechanismDescription							 	= SOURCE.InjuryMechanismDescription
			,TARGET.InjuryPlaceDate										 	= SOURCE.InjuryPlaceDate
			,TARGET.InjuryPlaceTime										 	= SOURCE.InjuryPlaceTime
			,TARGET.InjuryPlaceCode										 	= SOURCE.InjuryPlaceCode
			,TARGET.InjuryPlaceDescription								 	= SOURCE.InjuryPlaceDescription
			,TARGET.InjuryActivityStatus								 	= SOURCE.InjuryActivityStatus
			,TARGET.InjuryActivityStatusDescription						 	= SOURCE.InjuryActivityStatusDescription
			,TARGET.InjuryActivityType									 	= SOURCE.InjuryActivityType
			,TARGET.InjuryActivityTypeDescription						 	= SOURCE.InjuryActivityTypeDescription
			,TARGET.AlcoholDrugInvolvementsCode							 	= SOURCE.AlcoholDrugInvolvementsCode
			,TARGET.AlcoholDrugInvolvementsCode1						 	= SOURCE.AlcoholDrugInvolvementsCode1
			,TARGET.AlcoholDrugInvolvements1Description					 	= SOURCE.AlcoholDrugInvolvements1Description
			,TARGET.AlcoholDrugInvolvementsCode2						 	= SOURCE.AlcoholDrugInvolvementsCode2
			,TARGET.AlcoholDrugInvolvements2Description					 	= SOURCE.AlcoholDrugInvolvements2Description
			,TARGET.AlcoholDrugInvolvementsCode3						 	= SOURCE.AlcoholDrugInvolvementsCode3
			,TARGET.AlcoholDrugInvolvements3Description					 	= SOURCE.AlcoholDrugInvolvements3Description
			,TARGET.Tariff												 	= SOURCE.Tariff
			,TARGET.FinalPrice											 	= SOURCE.FinalPrice
			,TARGET.ClinicalCodedScoredAssessmentToolTypeCode			 	= SOURCE.ClinicalCodedScoredAssessmentToolTypeCode
			,TARGET.ClinicalCodedScoredAssessmentToolTypeCodeDescription 	= SOURCE.ClinicalCodedScoredAssessmentToolTypeCodeDescription
			,TARGET.ClinicalCodedScoredAssessmentToolTypeCode1			 	= SOURCE.ClinicalCodedScoredAssessmentToolTypeCode1
			,TARGET.ClinicalCodedScoredAssessmentToolTypeCode1Description	= SOURCE.ClinicalCodedScoredAssessmentToolTypeCode1Description
			,TARGET.ClinicalCodedScoredAssessmentToolTypeCode2			 	= SOURCE.ClinicalCodedScoredAssessmentToolTypeCode2
			,TARGET.ClinicalCodedScoredAssessmentToolTypeCode2Description	= SOURCE.ClinicalCodedScoredAssessmentToolTypeCode2Description
			,TARGET.ClinicalCodedScoredAssessmentToolTypeCode3			 	= SOURCE.ClinicalCodedScoredAssessmentToolTypeCode3
			,TARGET.ClinicalCodedScoredAssessmentToolTypeCode3Description	= SOURCE.ClinicalCodedScoredAssessmentToolTypeCode3Description
			,TARGET.ClinicalCodedScoredAssessmentPersonScore			 	= SOURCE.ClinicalCodedScoredAssessmentPersonScore
			,TARGET.ClinicalCodedScoredAssessmentPersonScoreDescription	 	= SOURCE.ClinicalCodedScoredAssessmentPersonScoreDescription
			,TARGET.ClinicalCodedScoredAssessmentPersonScore1			 	= SOURCE.ClinicalCodedScoredAssessmentPersonScore1
			,TARGET.ClinicalCodedScoredAssessmentPersonScore1Description 	= SOURCE.ClinicalCodedScoredAssessmentPersonScore1Description
			,TARGET.ClinicalCodedScoredAssessmentPersonScore2			 	= SOURCE.ClinicalCodedScoredAssessmentPersonScore2
			,TARGET.ClinicalCodedScoredAssessmentPersonScore2Description 	= SOURCE.ClinicalCodedScoredAssessmentPersonScore2Description
			,TARGET.ClinicalCodedScoredAssessmentPersonScore3			 	= SOURCE.ClinicalCodedScoredAssessmentPersonScore3
			,TARGET.ClinicalCodedScoredAssessmentPersonScore3Description 	= SOURCE.ClinicalCodedScoredAssessmentPersonScore3Description
			,TARGET.ValidationTimestamp									 	= SOURCE.ValidationTimestamp
			,TARGET.ValidationTimestamp1								 	= SOURCE.ValidationTimestamp1
			,TARGET.ValidationTimestamp2								 	= SOURCE.ValidationTimestamp2
			,TARGET.ValidationTimestamp3								 	= SOURCE.ValidationTimestamp3
			,TARGET.ClinicalCodedFindingsCode							 	= SOURCE.ClinicalCodedFindingsCode
			,TARGET.ClinicalCodedFindingsCodeDescription				 	= SOURCE.ClinicalCodedFindingsCodeDescription
			,TARGET.ClinicalCodedFindingsCode1							 	= SOURCE.ClinicalCodedFindingsCode1
			,TARGET.ClinicalCodedFindingsCode1Description				 	= SOURCE.ClinicalCodedFindingsCode1Description
			,TARGET.ClinicalCodedFindingsCode2							 	= SOURCE.ClinicalCodedFindingsCode2
			,TARGET.ClinicalCodedFindingsCode2Description				 	= SOURCE.ClinicalCodedFindingsCode2Description
			,TARGET.ClinicalCodedFindingsCode3							 	= SOURCE.ClinicalCodedFindingsCode3
			,TARGET.ClinicalCodedFindingsCode3Description				 	= SOURCE.ClinicalCodedFindingsCode3Description
			,TARGET.ClinicalCodedFindingsCodeTimestamp					 	= SOURCE.ClinicalCodedFindingsCodeTimestamp
			,TARGET.ClinicalCodedFindingsCodeTimestamp1					 	= SOURCE.ClinicalCodedFindingsCodeTimestamp1
			,TARGET.ClinicalCodedFindingsCodeTimestamp2					 	= SOURCE.ClinicalCodedFindingsCodeTimestamp2
			,TARGET.ClinicalCodedFindingsCodeTimestamp3					 	= SOURCE.ClinicalCodedFindingsCodeTimestamp3
			,TARGET.IsActive											 	= 1
			,TARGET.UpdateUser											 	= @InsertUpdateUser
			,TARGET.UpdateTime											 	= @InsertUpdateTime
			,TARGET.RecordVersion										 	= SOURCE.RecordVersion
	-- Set deleted rows from source to inactive. Data older than 24 months will not be resent, so do not set not inactive
	WHEN NOT MATCHED BY SOURCE
    AND TARGET.IsActive = 1
	AND TARGET.DepartureDate > @24MonthsAgo	THEN
	UPDATE SET TARGET.UpdateUser	= @InsertUpdateUser
			  ,TARGET.UpdateTime	= @InsertUpdateTime
			  ,TARGET.IsActive		= 0
              ,TARGET.RecordVersion = 0
	OUTPUT $ACTION INTO @SummaryOfChanges;

END TRY
BEGIN CATCH
	SELECT	 @EndTime = SYSDATETIME()
			,@ErrorMessage = ERROR_MESSAGE();

    -- Log the inserts, updates, and deletes, as well as any error message captured
    EXEC [$(LoggingDbName)].dbo.usp_UpdateEtlLog	 @LogId        = @LogId
													,@EndTime      = @EndTime
													,@Success      = @Success
													,@ErrorMessage = @ErrorMessage
													,@Inserts      = @Inserts
													,@Updates      = @Updates
													,@Deletes      = @Deletes;

    -- Throw the error (don't just swallow it)
    THROW;
END CATCH

SELECT	 @EndTime = SYSDATETIME()
		,@Success = 1;

-- Count the number of changes of each type from the merge
SELECT	 @Inserts = ISNULL(SUM(IIF(Change = 'Insert', 1, 0)), 0)
		,@Updates = ISNULL(SUM(IIF(Change = 'Update', 1, 0)), 0)
		,@Deletes = ISNULL(SUM(IIF(Change = 'Delete', 1, 0)), 0)
FROM @SummaryOfChanges;

-- Log the inserts, updates, and deletes, as well as any error message captured
EXEC [$(LoggingDbName)].dbo.usp_UpdateEtlLog	 @LogId        = @LogId
												,@EndTime      = @EndTime
												,@Success      = @Success
												,@ErrorMessage = @ErrorMessage
												,@Inserts      = @Inserts
												,@Updates      = @Updates
												,@Deletes      = @Deletes;