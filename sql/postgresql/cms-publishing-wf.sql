create table cr_workflows (
  case_id        integer
                 constraint cr_workflows_pk 
                 primary key
                 constraint cr_workflows_case_id_fk
                 references wf_cases
);

create function inline_0 ()
returns integer as '
declare
  v_workflow_key varchar(100);

begin

   v_workflow_key := workflow__create_workflow(
      ''publishing'',
      ''Simple Publishing Workflow'',
      ''Simple Publishing Workflows'',
      ''A simple linear workflow for authoring, 
        editing and scheduling content items.'',
      ''cr_workflows'',
      ''case_id''
      );

   return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

 
-- show errors

-- create or replace package publishing_wf as
-- 
--   -- simply check the 'next_place' attribute and return true if
--   -- it matches the submitted place_key
-- 
--   function is_next (
--     case_id           in number, 
--     workflow_key      in varchar, 
--     transition_key    in varchar, 
--     place_key         in varchar, 
--     direction	      in varchar, 
--     custom_arg	      in varchar
--   ) return char;
-- 
-- end publishing_wf;

-- show errors

-- create or replace package body publishing_wf as
-- function is_next
create function publishing_wf__is_next (integer,varchar,varchar,varchar,varchar,varchar)
returns char as '
declare
  p_case_id                        alias for $1;  
  p_workflow_key                   alias for $2;  
  p_transition_key                 alias for $3;  
  p_place_key                      alias for $4;  
  p_direction                      alias for $5;  
  p_custom_arg                     alias for $6;  
  v_next_place                     varchar(100);  
  v_result                         boolean;
begin

    v_next_place := workflow_case__get_attribute_value(p_case_id,''next_place'');

    if v_next_place = p_place_key then
      v_result := ''t'';
    end if;
     
    return v_result;
   
end;' language 'plpgsql';

-- show errors

insert into wf_places (
  place_key, workflow_key, place_name, sort_order
) values (
  'start', 'publishing_wf', 'Created', 1
);

insert into wf_places (
  place_key, workflow_key, place_name, sort_order
) values (
  'authored', 'publishing_wf', 'Authored', 2
);

insert into wf_places (
  place_key, workflow_key, place_name, sort_order
) values (
  'edited', 'publishing_wf', 'Edited', 3
);

insert into wf_places (
  place_key, workflow_key, place_name, sort_order
) values (
  'end', 'publishing_wf', 'Approved', 4
);

/*
 * The next step is to define the valid transitions from one place in the 
 * workflow to another.  Transitions are where actions occur, either on the
 * part of users or machines.
 */

insert into wf_transitions (
  transition_key, transition_name, workflow_key, sort_order, trigger_type
) values (
  'authoring', 'Authoring', 'publishing_wf', 1, 'user'
);

insert into wf_transitions (
  transition_key, transition_name, workflow_key, sort_order, trigger_type
) values (
  'editing', 'Editing', 'publishing_wf', 2, 'user'
);

insert into wf_transitions (
  transition_key, transition_name, workflow_key, sort_order, trigger_type
) values (
  'approval', 'Approval', 'publishing_wf', 3, 'user'
);

/* 
 * The next step is connect transitions to places.  This is analogous
 * to adding arrows or arcs to the workflow diagram, pointing from places
 * to transitions and from transitions to other places.
 */

insert into wf_arcs (
  workflow_key, transition_key, place_key, direction
) values (
  'publishing_wf', 'authoring', 'start', 'in'
);

-- The authoring transition can either be to 'authored' or back to 'start'
-- if the author checks in the item without completing it

insert into wf_arcs (
  workflow_key, transition_key, place_key, direction, guard_callback
) values (
  'publishing_wf', 'authoring', 'authored', 'out', 'publishing_wf__is_next'
);

insert into wf_arcs (
  workflow_key, transition_key, place_key, direction, guard_callback
) values (
  'publishing_wf', 'authoring', 'start', 'out', '#'
);


insert into wf_arcs (
  workflow_key, transition_key, place_key, direction
) values (
  'publishing_wf', 'editing', 'authored', 'in'
);

-- The editing transition can either be to 'edited' or back to 'start'
-- if the item is rejected

insert into wf_arcs (
  workflow_key, transition_key, place_key, direction, guard_callback
) values (
  'publishing_wf', 'editing', 'authored', 'out', '#'
);

insert into wf_arcs (
  workflow_key, transition_key, place_key, direction, guard_callback
) values (
  'publishing_wf', 'editing', 'edited', 'out', 'publishing_wf__is_next'
);

insert into wf_arcs (
  workflow_key, transition_key, place_key, direction, guard_callback
) values (
  'publishing_wf', 'editing', 'start', 'out', 'publishing_wf__is_next'
);

insert into wf_arcs (
  workflow_key, transition_key, place_key, direction
) values (
  'publishing_wf', 'approval', 'edited', 'in'
);

-- The approval transition can be to the end, back to authored
-- for further editor review, or back to start for further author work.


insert into wf_arcs (
  workflow_key, transition_key, place_key, direction, guard_callback
) values (
  'publishing_wf', 'approval', 'edited', 'out', '#'
);


insert into wf_arcs (
  workflow_key, transition_key, place_key, direction, guard_callback
) values (
  'publishing_wf', 'approval', 'end', 'out', 'publishing_wf__is_next'
);

insert into wf_arcs (
  workflow_key, transition_key, place_key, direction, guard_callback
) values (
  'publishing_wf', 'approval', 'authored', 'out', 'publishing_wf__is_next'
);

insert into wf_arcs (
  workflow_key, transition_key, place_key, direction, guard_callback
) values (
  'publishing_wf', 'approval', 'start', 'out', 'publishing_wf__is_next'
);


create function inline_1 ()
returns integer as '
declare
    v_attribute_id acs_attributes.attribute_id%TYPE;
begin
    v_attribute_id := workflow__create_attribute(
	''publishing_wf'',
	''next_place'',
	''string'',
	''Next Place'',
        null,
        null,
        null,
	''start'',
        1,
        1,
        null,
        ''generic'',
	''none''
    );

    insert into wf_transition_attribute_map
        (workflow_key, transition_key, attribute_id, sort_order) 
    values
        (''publishing_wf'', ''authoring'', v_attribute_id, 1);

    insert into wf_transition_attribute_map
        (workflow_key, transition_key, attribute_id, sort_order) 
    values
        (''publishing_wf'', ''editing'', v_attribute_id, 1);

    insert into wf_transition_attribute_map
        (workflow_key, transition_key, attribute_id, sort_order) 
    values
        (''publishing_wf'', ''approval'', v_attribute_id, 1);

    return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();


-- show errors

