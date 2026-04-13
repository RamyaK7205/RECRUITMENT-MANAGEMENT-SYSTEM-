" ---------------------------------------------------------------------
" 1. BUFFER CLASS - Must be at the very top
" ---------------------------------------------------------------------
CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: tt_jobs TYPE TABLE OF z36_job_post WITH EMPTY KEY,
           tt_apps TYPE TABLE OF z36_job_appl WITH EMPTY KEY.

    TYPES: BEGIN OF ty_buffer,
             jobs         TYPE tt_jobs,
             applications TYPE tt_apps,
             jobs_delete  TYPE tt_jobs,
             apps_delete  TYPE tt_apps,
           END OF ty_buffer.

    CLASS-DATA mt_buffer TYPE ty_buffer.
ENDCLASS.

" ---------------------------------------------------------------------
" 2. HANDLER CLASS DEFINITION
" ---------------------------------------------------------------------
CLASS lhc_Job DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Job RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Job RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Job.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Job.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Job.

    METHODS read FOR READ
      IMPORTING keys FOR READ Job RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Job.

    METHODS cba_Applications FOR MODIFY
      IMPORTING entities_cba FOR CREATE Job\_Applications.
ENDCLASS.

" ---------------------------------------------------------------------
" 3. HANDLER CLASS IMPLEMENTATION
" ---------------------------------------------------------------------
CLASS lhc_Job IMPLEMENTATION.

  METHOD get_global_authorizations.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      APPEND VALUE #( %tky = <key>-%tky
                      %update = if_abap_behv=>auth-allowed
                      %delete = if_abap_behv=>auth-allowed ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD create.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      DATA: ls_job TYPE z36_job_post.

      " Map UI data to DB structure
      ls_job = CORRESPONDING #( <entity> MAPPING FROM ENTITY ).

      " Manual keys and admin data
      ls_job-job_id = zcl_36_rms_util=>generate_guid( ).
      ls_job-created_by = sy-uname.
      ls_job-created_at = zcl_36_rms_util=>get_timestamp( ).
      ls_job-last_changed_at = ls_job-created_at.

      " Push to buffer
      INSERT ls_job INTO TABLE lcl_buffer=>mt_buffer-jobs.

      " Report mapped ID back to Fiori
      APPEND VALUE #( %cid = <entity>-%cid
                      JobId = ls_job-job_id ) TO mapped-job.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      DATA(ls_job) = CORRESPONDING z36_job_post( <entity> MAPPING FROM ENTITY ).
      ls_job-last_changed_at = zcl_36_rms_util=>get_timestamp( ).
      INSERT ls_job INTO TABLE lcl_buffer=>mt_buffer-jobs.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      INSERT VALUE #( job_id = <key>-JobId ) INTO TABLE lcl_buffer=>mt_buffer-jobs_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD cba_Applications.
    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<entity_cba>).
      LOOP AT <entity_cba>-%target ASSIGNING FIELD-SYMBOL(<app_entity>).
        DATA: ls_app TYPE z36_job_appl.
        ls_app = CORRESPONDING #( <app_entity> MAPPING FROM ENTITY ).

        ls_app-app_id = zcl_36_rms_util=>generate_guid( ).
        ls_app-job_id = <entity_cba>-JobId.
        ls_app-applied_at = zcl_36_rms_util=>get_timestamp( ).
        ls_app-last_changed_at = ls_app-applied_at.

        INSERT ls_app INTO TABLE lcl_buffer=>mt_buffer-applications.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    " Implementation for READ if required for Draft Resume
  ENDMETHOD.

  METHOD lock.
    " Implementation for LOCK
  ENDMETHOD.
ENDCLASS.

" ---------------------------------------------------------------------
" CHILD HANDLER CLASS - Z36_I_JOBAPPL
" ---------------------------------------------------------------------
CLASS lhc_Application DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    "✅ REMOVED lock - not needed, child uses lock dependent by _Job
    "✅ REMOVED get_instance_authorizations - not needed for dependent entity

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Application.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Application.

    METHODS read FOR READ
      IMPORTING keys FOR READ Application RESULT result.
ENDCLASS.

CLASS lhc_Application IMPLEMENTATION.

  METHOD update.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      SELECT SINGLE * FROM z36_job_appl
        WHERE app_id = @<entity>-AppId
        INTO @DATA(ls_existing).

      IF sy-subrc = 0.
        IF <entity>-%control-CandidateName = if_abap_behv=>mk-on.
          ls_existing-candidate_name = <entity>-CandidateName.
        ENDIF.
        IF <entity>-%control-Email = if_abap_behv=>mk-on.
          ls_existing-email = <entity>-Email.
        ENDIF.
        IF <entity>-%control-Phone = if_abap_behv=>mk-on.
          ls_existing-phone = <entity>-Phone.
        ENDIF.
        IF <entity>-%control-AppStatus = if_abap_behv=>mk-on.
          ls_existing-app_status = <entity>-AppStatus.
        ENDIF.

        ls_existing-last_changed_at = zcl_36_rms_util=>get_timestamp( ).
        INSERT ls_existing INTO TABLE lcl_buffer=>mt_buffer-applications.
      ELSE.
        APPEND VALUE #( %tky = <entity>-%tky ) TO failed-application.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      INSERT VALUE #( app_id = <key>-AppId )
        INTO TABLE lcl_buffer=>mt_buffer-apps_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      SELECT SINGLE * FROM z36_job_appl
        WHERE app_id = @<key>-AppId
        INTO @DATA(ls_app).

      IF sy-subrc = 0.
        APPEND CORRESPONDING #( ls_app MAPPING TO ENTITY ) TO result.
      ELSE.
        APPEND VALUE #( %tky = <key>-%tky ) TO failed-application.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

" ---------------------------------------------------------------------
" 4. SAVER CLASS DEFINITION & IMPLEMENTATION
" ---------------------------------------------------------------------
CLASS lsc_z36_i_jobpost DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
ENDCLASS.

CLASS lsc_z36_i_jobpost IMPLEMENTATION.
  METHOD save.
    " Persist Jobs
    IF lcl_buffer=>mt_buffer-jobs IS NOT INITIAL.
      MODIFY z36_job_post FROM TABLE @lcl_buffer=>mt_buffer-jobs.
    ENDIF.

    " Persist Applications
    IF lcl_buffer=>mt_buffer-applications IS NOT INITIAL.
      MODIFY z36_job_appl FROM TABLE @lcl_buffer=>mt_buffer-applications.
    ENDIF.

    " Handle Deletions
    IF lcl_buffer=>mt_buffer-jobs_delete IS NOT INITIAL.
      DELETE z36_job_post FROM TABLE @lcl_buffer=>mt_buffer-jobs_delete.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR lcl_buffer=>mt_buffer.
  ENDMETHOD.
ENDCLASS.
