@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CONSUMPTION TAB 2'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity Z36_C_JOBAPPL
  as projection on Z36_I_JOBAPPL
{
    key AppId,
    JobId,
    
    @Search.defaultSearchElement: true
    CandidateName,
    
    Email,
    Phone,
    ResumeUrl,
    AppStatus,
    AppliedAt,
    LastChangedAt,
    
    /* Associations */
    _Job : redirected to parent Z36_C_JOBPOST
}
