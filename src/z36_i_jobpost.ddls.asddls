@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'INTERFACE VIEW - JOB POSTING'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

define root view entity Z36_I_JOBPOST
  as select from z36_job_post
  composition [0..*] of Z36_I_JOBAPPL as _Applications
{
  key job_id          as JobId,
      job_title       as JobTitle,
      job_description as JobDescription,
      location        as Location,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      salary_range    as SalaryRange,
      currency_code   as CurrencyCode,
      status          as Status,
      created_by      as CreatedBy,
      created_at      as CreatedAt,
      last_changed_at as LastChangedAt,

      /* Associations */
      _Applications
}
