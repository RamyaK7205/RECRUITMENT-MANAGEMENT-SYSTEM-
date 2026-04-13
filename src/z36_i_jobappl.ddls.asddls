@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'INTERFACE TAB 2'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Z36_I_JOBAPPL
  as select from z36_job_appl
  association to parent Z36_I_JOBPOST as _Job on $projection.JobId = _Job.JobId
{
  key app_id          as AppId,
      job_id          as JobId,
      candidate_name  as CandidateName,
      email           as Email,
      phone           as Phone,
      resume_url      as ResumeUrl,
      app_status      as AppStatus,
      applied_at      as AppliedAt,
      last_changed_at as LastChangedAt,
      
      /* Associations */
      _Job
}
