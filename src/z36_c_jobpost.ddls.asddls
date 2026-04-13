@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CONSUMPTION TAB 1'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
@Metadata.allowExtensions: true

define root view entity Z36_C_JOBPOST
  provider contract transactional_query
  as projection on Z36_I_JOBPOST
{
    @Search.defaultSearchElement: true
    key JobId,
    
    @Search.defaultSearchElement: true
    JobTitle,
    
    JobDescription,
    Location,
    
    @Semantics.amount.currencyCode: 'CurrencyCode'
    SalaryRange,
    
    CurrencyCode,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Currency', element: 'Currency' } }]
    Status,
    
    CreatedBy,
    CreatedAt,
    LastChangedAt,
    
    /* Associations */
    _Applications : redirected to composition child Z36_C_JOBAPPL
}
