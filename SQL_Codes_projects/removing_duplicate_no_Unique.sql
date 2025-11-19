with CTE
as (select PatientLevelContractMonitoringId,
           ROW_NUMBER() OVER (PARTITION BY HASHBYTES(
                                                        'SHA2_512',
                                                        CONCAT(
                                                                  PatientLevelContractMonitoringId,
                                                                  SourceSystemKey,
                                                                  Pseudonym,
                                                                  FinancialMonth,
                                                                  FinancialYear,
                                                                  FinancialMonthDate,
                                                                  DatasetCreatedTime,
                                                                  PartnerId,
                                                                  ProviderShortName,
                                                                  TreatmentSiteOrganisationId,
                                                                  GpPracticeResponsibilityOrganisationId,
                                                                  ResidenceResponsibilityOrganisationId,
                                                                  CommissionerCodeOrganisationId,
                                                                  PatientRegistrationGeneralMedicalPractice,
                                                                  PracticeName,
                                                                  PrimaryCareNetwork,
                                                                  WithheldIdentityReason,
                                                                  NhsNumber,
                                                                  LocalPatientId,
                                                                  Postcode,
                                                                  DateOfBirth,
                                                                  ContractMonitoringAgeAtActivityDate,
                                                                  GenderCode,
                                                                  EthnicCategory,
                                                                  CdsUniqueIdentifier,
                                                                  NonCdsUniqueIdentifier,
                                                                  ActivityTreatmentFunctionCode,
                                                                  TreatmentFunctionCodeName,
                                                                  LocalSubSpecialtyCode,
                                                                  HospitalProviderSpellIdentifier,
                                                                  OutPatientAttendanceIdentifier,
                                                                  UrgentAndEmergencyCareActivityIdentifier,
                                                                  ContractMonitoringActivityStartDate,
                                                                  ContractMonitoringActivityEndDate,
                                                                  AdjustedLengthOfStay,
                                                                  ContractMonitoringPackageOfCareOrYearOfCareStartDate,
                                                                  LocalTreatmentCategoryCode,
                                                                  LocalTreatmentCode,
                                                                  LocationOfActivityStart,
                                                                  LocationOfActivityEnd,
                                                                  ProviderReferenceIdentifier,
                                                                  NhsServiceAgreementLineNumber,
                                                                  CommissionedServiceCategoryCode,
                                                                  ServiceCode,
                                                                  PointOfDeliveryCode,
                                                                  PointOfDeliveryFurtherDetailCode,
                                                                  PointOfDeliveryFurtherDetailDescription,
                                                                  LocalPointOfDeliveryCode,
                                                                  LocalPointOfDeliveryDescription,
                                                                  LocalContractCode,
                                                                  LocalContractCodeDescription,
                                                                  LocalContractMonitoringCode,
                                                                  LocalContractMonitoringDescription,
                                                                  FirstContractMonitoringAdditionalDetail,
                                                                  FirstContractMonitoringAdditionalDescription,
                                                                  TariffCode,
                                                                  HealthcareResourceGroupName,
                                                                  HealthcareResourceGroupChapter,
                                                                  HealthcareResourceGroupChapterName,
                                                                  HealthcareResourceGroupSubChapter,
                                                                  HealthcareResourceGroupSubChapterName,
                                                                  NationalTariffIndicator,
                                                                  PointOfDeliveryActivityCount,
                                                                  ActivityUnitPrice,
                                                                  TotalCost,
                                                                  TotalCostPreMarketForcesFactor,
                                                                  SourceFileId,
                                                                  CamOrganisation
                                                              )
                                                    )
                              ORDER BY SourceFileId
                             ) AS RowNum
    FROM ODS.cxslam.PatientLevelContractMonitoring
    WHERE IsActive = 1
   )
Select *
FROM ODS.cxslam.PatientLevelContractMonitoring
    join CTE
        on t.PatientLevelContractMonitoringId = CTE.PatientLevelContractMonitoringId
where CTE.RowNum > 1;

UPDATE t
SET t.IsActive = 0
FROM ODS.cxslam.PatientLevelContractMonitoring AS t
JOIN CTE
    ON t.PatientLevelContractMonitoringId = CTE.PatientLevelContractMonitoringId
WHERE CTE.RowNum > 1;