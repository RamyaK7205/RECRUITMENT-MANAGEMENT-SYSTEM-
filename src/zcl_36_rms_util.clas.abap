CLASS zcl_36_rms_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS generate_guid
      RETURNING VALUE(rv_guid) TYPE sysuuid_x16.

    CLASS-METHODS get_timestamp
      RETURNING VALUE(rv_tstmpl) TYPE timestampl.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_36_rms_util IMPLEMENTATION.

  METHOD generate_guid.
    TRY.
        rv_guid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        CLEAR rv_guid.    "✅ safe - no dump, caller can check
    ENDTRY.
  ENDMETHOD.

  METHOD get_timestamp.
    GET TIME STAMP FIELD rv_tstmpl.
  ENDMETHOD.

ENDCLASS.
