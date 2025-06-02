--=================================================================================
--Created by: Rachael Devney
--Date:  24th February 2020
--Description: Loads Emergency Care data from staging into the Ods.
--Usage:       EXEC sus2.usp_LoadEcdsToOds;
--=================================================================================
CREATE PROCEDURE sus2.usp_LoadEcdsToOds
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
		,@UnknownMemberKey	INT = CAST(ref.udf_GetGlobalVariable('UnknownMemberKey') AS INT)
		,@InsertUpdateUser	VARCHAR(100) = ORIGINAL_LOGIN()
		,@InsertUpdateTime	DATETIME2(0) = SYSDATETIME()
		,@SourceSystemKey	INT = CAST([$(OdsDbName)].dbo.udf_GetSourceSystemKey('SUS2') AS INT)
		,@PartnerId			VARCHAR(50) = 'CSU'
		,@24MonthsAgo		DATE = DATEADD(MONTH, -24, DATEADD(DAY,1,EOMONTH(SYSDATETIME(),-1)));

-- Log the start of the load
EXEC [$(LoggingDbName)].dbo.usp_CreateEtlLog @PackageName			= @ProcedureName
                                            ,@SourceObjectType		= 'Table'
                                            ,@SourceObjectName		= '$(DatabaseName).sus2.Ecds'
                                            ,@DestinationObjectType = 'Table'
                                            ,@DestinationObjectName = '$(OdsDbName).clinical.EmergencyCare'
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
			,Local_Patient_Identifier AS LocalPatientIdentifier
			,General_Practice AS GeneralPractice
			,[Site] AS [Site]
			,OA_11 AS OutputArea
			,LSOA_11 AS LowerSuperOutputAreaCode
			,Postcode_District AS PostcodeDistrict
			,Residence_CCG AS ResidenceCcg
			,Ethnic_Category AS EthnicCategory
			,Arrival_Date AS ArrivalDate
			,Arrival_Time AS ArrivalTime
			,Arrival_Planned AS ArrivalPlanned
			,CAST(Arrival_Mode AS BIGINT) AS ArrivalMode
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
			,CAST(Investigation_Code_3 AS BIGINT) AS InvestigationCode3
			,Treatment_Code AS TreatmentCode
			,CAST(Treatment_Code_1 AS BIGINT) AS TreatmentCode1
			,CAST(Treatment_Code_2 AS BIGINT) AS TreatmentCode2
			,CAST(Treatment_Code_3 AS BIGINT) AS TreatmentCode3
			,Health_Resource_Group AS HealthResourceGroup
			,Attendance_Category AS AttendanceCategory
			,Ambulance_Incident_Number AS AmbulanceIncidentNumber
			,Conveying_Ambulance_Trust AS ConveyingAmbulanceTrust
			,Referred_To_Service AS ReferredToService
			,CAST(Discharge_Status AS BIGINT) AS DischargeStatus
			,CAST(Destination AS BIGINT) AS DischargeDestination
			,CAST(Discharge_Follow_Up AS BIGINT) AS DischargeFollowUp
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
			,Tariff AS Tariff
			,Final_Price AS FinalPrice
			,RECORD_ID AS RecordId
			,ROW_NUMBER() OVER (PARTITION BY CDS_Unique_Identifier, Organisation_Code_Provider ORDER BY RECORD_ID DESC) AS RowNum
	INTO #Ecds
	FROM sus2.Ecds;

	MERGE INTO [$(OdsDbName)].[clinical].[EmergencyCare] AS TARGET
	USING	(SELECT	 a.EmergencyCareId
					,a.SourceSystemKey
					,a.ProviderCode
					,o.ProviderShortName AS [Provider]
					,a.DepartmentTypeCode
					,d.AeDepartmentDescriptionShort AS DepartmentType
					,a.OrganisationCodeCommissioner
					,a.PersonId
					,ISNULL(pl.PersonKey, @UnknownMemberKey) AS PersonKey
					,a.Age
					,a.LocalPatientIdentifier
					,a.GeneralPractice
					,a.[Site]
					,a.OutputArea
					,a.LowerSuperOutputAreaCode
					,olwm.LocalAuthorityCode
					,olwm.LocalAuthorityName
					,a.PostcodeDistrict
					,a.ResidenceCcg
					,po.OrganisationName AS ResidenceCcgDescription
					,a.EthnicCategory
					,ec.EthnicCategory AS EthnicCategoryDescription
					,a.ArrivalDate
					,a.ArrivalTime
					,a.ArrivalPlanned
					,a.ArrivalMode
					,am.Term AS ArrivalModeDescription
					,a.InitialAssessmentDate
					,a.InitialAssessmentTime
					,a.SeenForTreatmentDate
					,a.SeenForTreatmentTime
					,a.ConclusionDate
					,a.ConclusionTime
					,a.DepartureDate
					,a.DepartureTime
					,a.DecisionToAdmitDate
					,a.DecisionToAdmitTime
					,a.DecisionToAdmitTimeSinceArrival
					,a.DiagnosesCode
					,di.Term AS DiagnosesDescription
					,a.DiagnosesCode1
					,di1.Term AS DiagnosesDescription1
					,a.DiagnosesCode2
					,di2.Term AS DiagnosesDescription2
					,a.DiagnosesCode3
					,di3.Term AS DiagnosesDescription3
					,a.InvestigationCode
					,i.Term AS InvestigationDescription
					,a.InvestigationCode1
					,i1.Term AS InvestigationDescription1
					,a.InvestigationCode2
					,i2.Term AS InvestigationDescription2
					,a.InvestigationCode3
					,i3.Term AS InvestigationDescription3
					,a.TreatmentCode
					,t.Term AS TreatmentDescription
					,a.TreatmentCode1
					,t1.Term AS TreatmentDescription1
					,a.TreatmentCode2
					,t2.Term AS TreatmentDescription2
					,a.TreatmentCode3
					,t3.Term AS TreatmentDescription3
					,a.HealthResourceGroup
					,a.AttendanceCategory
					,ac.[Description] AS AttendanceCategoryDescription
					,a.AmbulanceIncidentNumber
					,a.ConveyingAmbulanceTrust
					,o2.ProviderShortName AS ConveyingAmbulanceTrustDescription
					,a.ReferredToService
					,rs.Term AS ReferredToServiceDescription
					,a.DischargeStatus
					,ds.Term AS DischargeStatusDescription
					,a.DischargeDestination
					,dd.Term AS DischargeDestinationDescription
					,a.DischargeFollowUp
					,df.Term AS DischargeFollowUpDescription
					,a.ChiefComplaint
					,cc.Term AS ChiefComplaintDescription
					,a.Acuity
					,ay.Term AS AcuityDescription
					,a.ComorbiditiesCode
					,co.Term AS ComorbiditiesCodeDescription
					,a.ComorbiditiesCode1
					,co1.Term AS ComorbiditiesCode1Description
					,a.ComorbiditiesCode2
					,co2.Term AS ComorbiditiesCode2Description
					,a.AecRelated
					,a.EquivalentAeInvestigationCode
					,iv.[Description] AS EquivalentAeInvestigationCodeDescription
					,a.EquivalentAeInvestigationCode1
					,iv1.[Description] AS EquivalentAeInvestigationCode1Description
					,a.EquivalentAeInvestigationCode2
					,iv2.[Description] AS EquivalentAeInvestigationCode2Description
					,a.EquivalentAeTreatmentCode
					,tr.AeTreatment AS EquivalentAeTreatmentCodeDescription
					,a.EquivalentAeTreatmentCode1
					,tr1.AeTreatment AS EquivalentAeTreatmentCode1Description
					,a.EquivalentAeTreatmentCode2
					,tr2.AeTreatment AS EquivalentAeTreatmentCode2Description
					,a.EquivalentAeTreatmentCode3
					,tr3.AeTreatment AS EquivalentAeTreatmentCode3Description
					,a.Tariff
					,a.FinalPrice
					,HASHBYTES('SHA2_512', CONCAT(	 a.EmergencyCareId							,'|'
													,a.SourceSystemKey							,'|'
													,a.ProviderCode								,'|'
													,o.ProviderShortName						,'|'
													,a.DepartmentTypeCode						,'|'
													,d.AeDepartmentDescriptionShort				,'|'
													,a.OrganisationCodeCommissioner				,'|'
													,a.PersonId									,'|'
													,ISNULL(pl.PersonKey, @UnknownMemberKey)	,'|'
													,a.Age										,'|'
													,a.LocalPatientIdentifier					,'|'
													,a.GeneralPractice							,'|'
													,a.[Site]									,'|'
													,a.OutputArea								,'|'
													,a.LowerSuperOutputAreaCode					,'|'
													,olwm.LocalAuthorityCode					,'|'
													,olwm.LocalAuthorityName					,'|'
													,a.PostcodeDistrict							,'|'
													,a.ResidenceCcg								,'|'
													,po.OrganisationName						,'|'
													,a.EthnicCategory							,'|'
													,ec.EthnicCategory							,'|'
													,a.ArrivalDate								,'|'
													,a.ArrivalTime								,'|'
													,a.ArrivalPlanned							,'|'
													,a.ArrivalMode								,'|'
													,am.Term									,'|'
													,a.InitialAssessmentDate					,'|'
													,a.InitialAssessmentTime					,'|'
													,a.SeenForTreatmentDate						,'|'
													,a.SeenForTreatmentTime						,'|'
													,a.ConclusionDate							,'|'
													,a.ConclusionTime							,'|'
													,a.DepartureDate							,'|'
													,a.DepartureTime							,'|'
													,a.DecisionToAdmitDate						,'|'
													,a.DecisionToAdmitTime						,'|'
													,a.DecisionToAdmitTimeSinceArrival			,'|'
													,a.DiagnosesCode							,'|'
													,di.Term									,'|'
													,a.DiagnosesCode1							,'|'
													,di1.Term									,'|'
													,a.DiagnosesCode2							,'|'
													,di2.Term									,'|'
													,a.DiagnosesCode3							,'|'
													,di3.Term									,'|'
													,a.InvestigationCode						,'|'
													,i.Term										,'|'
													,a.InvestigationCode1						,'|'
													,i1.Term									,'|'
													,a.InvestigationCode2						,'|'
													,i2.Term									,'|'
													,a.InvestigationCode3						,'|'
													,i3.Term									,'|'
													,a.TreatmentCode							,'|'
													,t.Term										,'|'
													,a.TreatmentCode1							,'|'
													,t1.Term									,'|'
													,a.TreatmentCode2							,'|'
													,t2.Term									,'|'
													,a.TreatmentCode3							,'|'
													,t3.Term									,'|'
													,a.HealthResourceGroup						,'|'
													,a.AttendanceCategory						,'|'
													,ac.[Description]							,'|'
													,a.AmbulanceIncidentNumber					,'|'
													,a.ConveyingAmbulanceTrust					,'|'
													,o2.ProviderShortName						,'|'
													,a.ReferredToService						,'|'
													,rs.Term									,'|'
													,a.DischargeStatus							,'|'
													,ds.Term									,'|'
													,a.DischargeDestination						,'|'
													,dd.Term									,'|'
													,a.DischargeFollowUp						,'|'
													,df.Term									,'|'
													,a.ChiefComplaint							,'|'
													,cc.Term									,'|'
													,a.Acuity									,'|'
													,ay.Term									,'|'
													,a.ComorbiditiesCode						,'|'
													,co.Term									,'|'
													,a.ComorbiditiesCode1						,'|'
													,co1.Term									,'|'
													,a.ComorbiditiesCode2						,'|'
													,co2.Term									,'|'
													,a.AecRelated								,'|'
													,a.EquivalentAeInvestigationCode			,'|'
													,iv.[Description]							,'|'
													,a.EquivalentAeInvestigationCode1			,'|'
													,iv1.[Description]							,'|'
													,a.EquivalentAeInvestigationCode2			,'|'
													,iv2.[Description]							,'|'
													,a.EquivalentAeTreatmentCode				,'|'
													,tr.AeTreatment								,'|'
													,a.EquivalentAeTreatmentCode1				,'|'
													,tr1.AeTreatment							,'|'
													,a.EquivalentAeTreatmentCode2				,'|'
													,tr2.AeTreatment							,'|'
													,a.EquivalentAeTreatmentCode3				,'|'
													,tr3.AeTreatment							,'|'
													,a.Tariff									,'|'
													,a.FinalPrice)) AS RecordVersion
			FROM #Ecds AS a
				LEFT OUTER JOIN [$(MpiDbName)].dbo.PersonLink AS pl
					ON a.PersonId = pl.SourceId
					AND pl.SourceSystemKey = @SourceSystemKey
					AND pl.PartnerId = @PartnerId
				LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeDepartment] AS d
					ON a.DepartmentTypeCode  = d.AeDepartmentId
				LEFT OUTER JOIN [$(OdsDbName)].[dbo].[ProviderOrganisation] AS o
					ON a.ProviderCode = o.ProviderOrganisationId
				LEFT OUTER JOIN [$(OdsDbName)].[dbo].[PrimaryCareOrganisation] AS po
					ON a.ResidenceCcg = po.PrimaryCareOrganisationId
				LEFT OUTER JOIN [$(OdsDbName)].[dbo].[ProviderOrganisation] AS o2
					ON a.ConveyingAmbulanceTrust = o2.ProviderOrganisationId
				LEFT OUTER JOIN [$(OdsDbName)].[dbo].[EthnicCategory] AS ec
					ON a.EthnicCategory = ec.EthnicCategoryId
				LEFT OUTER JOIN #Snomed AS am
					ON a.ArrivalMode = am.ConceptId
				LEFT OUTER JOIN #Snomed AS di
					ON a.DiagnosesCode = CAST(di.ConceptId AS VARCHAR(50))
				LEFT OUTER JOIN #Snomed AS di1
					ON a.DiagnosesCode1 = di1.ConceptId
				LEFT OUTER JOIN #Snomed AS di2
					ON a.DiagnosesCode2 = di2.ConceptId
				LEFT OUTER JOIN #Snomed AS di3
					ON a.DiagnosesCode3 = di3.ConceptId
				LEFT OUTER JOIN #Snomed AS i
					ON a.InvestigationCode = CAST(i.ConceptId AS VARCHAR(50))
				LEFT OUTER JOIN #Snomed AS i1
					ON a.InvestigationCode1 = i1.ConceptId
				LEFT OUTER JOIN #Snomed AS i2
					ON a.InvestigationCode2 = i2.ConceptId
				LEFT OUTER JOIN #Snomed AS i3
					ON a.InvestigationCode3 = i3.ConceptId
				LEFT OUTER JOIN #Snomed AS t
					ON a.TreatmentCode = CAST(t.ConceptId AS VARCHAR(50))
				LEFT OUTER JOIN #Snomed AS t1
					ON a.TreatmentCode1 = t1.ConceptId
				LEFT OUTER JOIN #Snomed AS t2
					ON a.TreatmentCode2 = t2.ConceptId
				LEFT OUTER JOIN #Snomed AS t3
					ON a.TreatmentCode3 = t3.ConceptId
				LEFT OUTER JOIN [$(OdsDbName)].dbo.AeAttendanceCategory AS ac
					ON a.AttendanceCategory = ac.AeAttendanceCategoryId
				LEFT OUTER JOIN #Snomed AS rs
					ON a.ReferredToService = CAST(rs.ConceptId AS VARCHAR(50))
				LEFT OUTER JOIN #Snomed AS ds
					ON a.DischargeStatus = ds.ConceptId
				LEFT OUTER JOIN #Snomed AS dd
					ON a.DischargeDestination = dd.ConceptId
				LEFT OUTER JOIN #Snomed AS df
					ON a.DischargeFollowUp = df.ConceptId
				LEFT OUTER JOIN #Snomed AS cc
					ON a.ChiefComplaint = cc.ConceptId
				LEFT OUTER JOIN #Snomed AS ay
					ON a.Acuity = ay.ConceptId
				LEFT OUTER JOIN #Snomed AS co
					ON a.ComorbiditiesCode = CAST(co.ConceptId AS VARCHAR(50))
				LEFT OUTER JOIN #Snomed AS co1
					ON a.ComorbiditiesCode1 = co1.ConceptId
				LEFT OUTER JOIN #Snomed AS co2
					ON a.ComorbiditiesCode2 = co2.ConceptId
				LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeInvestigation] AS iv
					ON a.EquivalentAeInvestigationCode = iv.AeInvestigationId
				LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeInvestigation] AS iv1
					ON a.EquivalentAeInvestigationCode1 = iv1.AeInvestigationId
				LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeInvestigation] AS iv2
					ON a.EquivalentAeInvestigationCode2 = iv2.AeInvestigationId
				LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeTreatment] AS tr
					ON a.EquivalentAeTreatmentCode = tr.AeTreatmentId
				LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeTreatment] AS tr1
					ON a.EquivalentAeTreatmentCode1 = tr1.AeTreatmentId
				LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeTreatment] AS tr2
					ON a.EquivalentAeTreatmentCode2 = tr2.AeTreatmentId
				LEFT OUTER JOIN [$(OdsDbName)].[dbo].[AeTreatment] AS tr3
					ON a.EquivalentAeTreatmentCode3 = tr3.AeTreatmentId
				LEFT OUTER JOIN [$(OdsDbName)].ref.OnsLaWardMapping AS olwm
					ON a.LowerSuperOutputAreaCode = olwm.LowerSuperOutputAreaCode
			-- Removing rows where CDS_Unique_Identifier is NULL as they cannot be matched on
			WHERE a.EmergencyCareId IS NOT NULL
			AND a.RowNum = 1) AS SOURCE
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
			,PersonKey
			,Age
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
			,ArrivalDate
			,ArrivalTime
			,ArrivalMode
			,ArrivalModeDescription
			,ArrivalPlanned
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
			,ReferredToService
			,ReferredToServiceDescription
			,DischargeStatus
			,DischargeStatusDescription
			,DischargeDestination
			,DischargeDestinationDescription
			,DischargeFollowUp
			,DischargeFollowUpDescription
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
			,Tariff
			,FinalPrice
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
			,SOURCE.PersonKey
			,SOURCE.Age
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
			,SOURCE.ArrivalDate
			,SOURCE.ArrivalTime
			,SOURCE.ArrivalMode
			,SOURCE.ArrivalModeDescription
			,SOURCE.ArrivalPlanned
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
			,SOURCE.ReferredToService
			,SOURCE.ReferredToServiceDescription
			,SOURCE.DischargeStatus
			,SOURCE.DischargeStatusDescription
			,SOURCE.DischargeDestination
			,SOURCE.DischargeDestinationDescription
			,SOURCE.DischargeFollowUp
			,SOURCE.DischargeFollowUpDescription
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
			,SOURCE.Tariff
			,SOURCE.FinalPrice
			,1
		    ,@InsertUpdateUser
		    ,@InsertUpdateTime
			,@InsertUpdateUser
		    ,@InsertUpdateTime
            ,SOURCE.RecordVersion)
    -- Handle updates using RecordVersion
	WHEN MATCHED
    AND SOURCE.RecordVersion <> TARGET.RecordVersion THEN
    UPDATE SET TARGET.SourceSystemKey								= SOURCE.SourceSystemKey
			  ,TARGET.[Provider]									= SOURCE.[Provider]
			  ,TARGET.DepartmentTypeCode							= SOURCE.DepartmentTypeCode
			  ,TARGET.DepartmentType								= SOURCE.DepartmentType
			  ,TARGET.OrganisationCodeCommissioner					= SOURCE.OrganisationCodeCommissioner
			  ,TARGET.PersonId										= SOURCE.PersonId
			  ,TARGET.PersonKey										= SOURCE.PersonKey
			  ,TARGET.Age											= SOURCE.Age
			  ,TARGET.LocalPatientIdentifier						= SOURCE.LocalPatientIdentifier
			  ,TARGET.GeneralPractice								= SOURCE.GeneralPractice
			  ,TARGET.[Site]										= SOURCE.[Site]
			  ,TARGET.OutputArea									= SOURCE.OutputArea
			  ,TARGET.LowerSuperOutputAreaCode						= SOURCE.LowerSuperOutputAreaCode
			  ,TARGET.LocalAuthorityCode							= SOURCE.LocalAuthorityCode
			  ,TARGET.LocalAuthorityName							= SOURCE.LocalAuthorityName
			  ,TARGET.PostcodeDistrict								= SOURCE.PostcodeDistrict
			  ,TARGET.ResidenceCcg									= SOURCE.ResidenceCcg
			  ,TARGET.ResidenceCcgDescription						= SOURCE.ResidenceCcgDescription
			  ,TARGET.EthnicCategory								= SOURCE.EthnicCategory
			  ,TARGET.EthnicCategoryDescription						= SOURCE.EthnicCategoryDescription
			  ,TARGET.ArrivalDate									= SOURCE.ArrivalDate
			  ,TARGET.ArrivalTime									= SOURCE.ArrivalTime
			  ,TARGET.ArrivalMode									= SOURCE.ArrivalMode
			  ,TARGET.ArrivalModeDescription						= SOURCE.ArrivalModeDescription
			  ,TARGET.ArrivalPlanned								= SOURCE.ArrivalPlanned
			  ,TARGET.InitialAssessmentDate							= SOURCE.InitialAssessmentDate
			  ,TARGET.InitialAssessmentTime							= SOURCE.InitialAssessmentTime
			  ,TARGET.SeenForTreatmentDate							= SOURCE.SeenForTreatmentDate
			  ,TARGET.SeenForTreatmentTime							= SOURCE.SeenForTreatmentTime
			  ,TARGET.ConclusionDate								= SOURCE.ConclusionDate
			  ,TARGET.ConclusionTime								= SOURCE.ConclusionTime
			  ,TARGET.DepartureDate									= SOURCE.DepartureDate
			  ,TARGET.DepartureTime									= SOURCE.DepartureTime
			  ,TARGET.DecisionToAdmitDate							= SOURCE.DecisionToAdmitDate
			  ,TARGET.DecisionToAdmitTime							= SOURCE.DecisionToAdmitTime
			  ,TARGET.DecisionToAdmitTimeSinceArrival				= SOURCE.DecisionToAdmitTimeSinceArrival
			  ,TARGET.DiagnosesCode									= SOURCE.DiagnosesCode
			  ,TARGET.DiagnosesDescription							= SOURCE.DiagnosesDescription
			  ,TARGET.DiagnosesCode1								= SOURCE.DiagnosesCode1
			  ,TARGET.DiagnosesDescription1							= SOURCE.DiagnosesDescription1
			  ,TARGET.DiagnosesCode2								= SOURCE.DiagnosesCode2
			  ,TARGET.DiagnosesDescription2							= SOURCE.DiagnosesDescription2
			  ,TARGET.DiagnosesCode3								= SOURCE.DiagnosesCode3
			  ,TARGET.DiagnosesDescription3							= SOURCE.DiagnosesDescription3
			  ,TARGET.InvestigationCode								= SOURCE.InvestigationCode
			  ,TARGET.InvestigationDescription						= SOURCE.InvestigationDescription
			  ,TARGET.InvestigationCode1							= SOURCE.InvestigationCode1
			  ,TARGET.InvestigationDescription1						= SOURCE.InvestigationDescription1
			  ,TARGET.InvestigationCode2							= SOURCE.InvestigationCode2
			  ,TARGET.InvestigationDescription2						= SOURCE.InvestigationDescription2
			  ,TARGET.TreatmentCode									= SOURCE.TreatmentCode
			  ,TARGET.TreatmentDescription							= SOURCE.TreatmentDescription
			  ,TARGET.TreatmentCode1								= SOURCE.TreatmentCode1
			  ,TARGET.TreatmentDescription1							= SOURCE.TreatmentDescription1
			  ,TARGET.TreatmentCode2								= SOURCE.TreatmentCode2
			  ,TARGET.TreatmentDescription2							= SOURCE.TreatmentDescription2
			  ,TARGET.TreatmentCode3								= SOURCE.TreatmentCode3
			  ,TARGET.TreatmentDescription3							= SOURCE.TreatmentDescription3
			  ,TARGET.HealthResourceGroup							= SOURCE.HealthResourceGroup
			  ,TARGET.AttendanceCategory							= SOURCE.AttendanceCategory
			  ,TARGET.AttendanceCategoryDescription					= SOURCE.AttendanceCategoryDescription
			  ,TARGET.AmbulanceIncidentNumber						= SOURCE.AmbulanceIncidentNumber
			  ,TARGET.ConveyingAmbulanceTrust						= SOURCE.ConveyingAmbulanceTrust
			  ,TARGET.ConveyingAmbulanceTrustDescription			= SOURCE.ConveyingAmbulanceTrustDescription
			  ,TARGET.ReferredToService								= SOURCE.ReferredToService
			  ,TARGET.ReferredToServiceDescription					= SOURCE.ReferredToServiceDescription
			  ,TARGET.DischargeStatus								= SOURCE.DischargeStatus
			  ,TARGET.DischargeStatusDescription					= SOURCE.DischargeStatusDescription
			  ,TARGET.DischargeDestination							= SOURCE.DischargeDestination
			  ,TARGET.DischargeDestinationDescription				= SOURCE.DischargeDestinationDescription
			  ,TARGET.DischargeFollowUp								= SOURCE.DischargeFollowUp
			  ,TARGET.DischargeFollowUpDescription					= SOURCE.DischargeFollowUpDescription
			  ,TARGET.ChiefComplaint								= SOURCE.ChiefComplaint
			  ,TARGET.ChiefComplaintDescription						= SOURCE.ChiefComplaintDescription
			  ,TARGET.Acuity										= SOURCE.Acuity
			  ,TARGET.AcuityDescription								= SOURCE.AcuityDescription
			  ,TARGET.ComorbiditiesCode								= SOURCE.ComorbiditiesCode
			  ,TARGET.ComorbiditiesCodeDescription					= SOURCE.ComorbiditiesCodeDescription
			  ,TARGET.ComorbiditiesCode1							= SOURCE.ComorbiditiesCode1
			  ,TARGET.ComorbiditiesCode1Description					= SOURCE.ComorbiditiesCode1Description
			  ,TARGET.ComorbiditiesCode2							= SOURCE.ComorbiditiesCode2
			  ,TARGET.ComorbiditiesCode2Description					= SOURCE.ComorbiditiesCode2Description
			  ,TARGET.AecRelated									= SOURCE.AecRelated
			  ,TARGET.EquivalentAeInvestigationCode					= SOURCE.EquivalentAeInvestigationCode
			  ,TARGET.EquivalentAeInvestigationCodeDescription		= SOURCE.EquivalentAeInvestigationCodeDescription
			  ,TARGET.EquivalentAeInvestigationCode1				= SOURCE.EquivalentAeInvestigationCode1
			  ,TARGET.EquivalentAeInvestigationCode1Description		= SOURCE.EquivalentAeInvestigationCode1Description
			  ,TARGET.EquivalentAeInvestigationCode2				= SOURCE.EquivalentAeInvestigationCode2
			  ,TARGET.EquivalentAeInvestigationCode2Description		= SOURCE.EquivalentAeInvestigationCode2Description
			  ,TARGET.EquivalentAeTreatmentCode						= SOURCE.EquivalentAeTreatmentCode
			  ,TARGET.EquivalentAeTreatmentCodeDescription			= SOURCE.EquivalentAeTreatmentCodeDescription
			  ,TARGET.EquivalentAeTreatmentCode1					= SOURCE.EquivalentAeTreatmentCode1
			  ,TARGET.EquivalentAeTreatmentCode1Description			= SOURCE.EquivalentAeTreatmentCode1Description
			  ,TARGET.EquivalentAeTreatmentCode2					= SOURCE.EquivalentAeTreatmentCode2
			  ,TARGET.EquivalentAeTreatmentCode2Description			= SOURCE.EquivalentAeTreatmentCode2Description
			  ,TARGET.EquivalentAeTreatmentCode3					= SOURCE.EquivalentAeTreatmentCode3
			  ,TARGET.EquivalentAeTreatmentCode3Description			= SOURCE.EquivalentAeTreatmentCode3Description
			  ,TARGET.Tariff										= SOURCE.Tariff
			  ,TARGET.FinalPrice									= SOURCE.FinalPrice
			  ,TARGET.IsActive										= 1
			  ,TARGET.UpdateUser									= @InsertUpdateUser
			  ,TARGET.UpdateTime									= @InsertUpdateTime
			  ,TARGET.RecordVersion									= SOURCE.RecordVersion
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