create table cr_workflows (
  case_id        integer
                 constraint cr_workflows_pk 
                 primary key
                 constraint cr_workflows_case_id_fk
                 references wf_cases
);

declare
  v_workflow_key varchar(100);

begin

  v_workflow_key := workflow.create_workflow (
      workflow_key  => 'publishing',
      pretty_name   => 'Simple Publishing Workflow',
      pretty_plural => 'Simple Publishing Workflows',
      description   =>   'A simple linear workflow for authoring, 
                          editing and scheduling content items.',
      table_name    => 'cr_workflows');

end;
/ 
show errors

create or replace package publishing_wf as

  -- simply check the 'next_place' attribute and return true if
  -- it matches the submitted place_key

  function is_next (
    case_id           in number, 
    workflow_key      in varchar, 
    transition_key    in varchar, 
    place_key         in varchar, 
    direction	      in varchar, 
    custom_arg	      in varchar
  ) return char;

end publishing_wf;
/
show errors

create or replace package body publishing_wf as

  function is_next (
    case_id           in number, 
    workflow_key      in varchar, 
    transition_key    in varchar, 
    place_key         in varchar, 
    direction	      in varchar, 
    custom_arg	      in varchar
  ) return char is

    v_next_place varchar(100);
    v_result char(1) := 'f';

  begin

    v_next_place := workflow_case.get_attribute_value(case_id, 'next_place');

    if v_next_place = place_key then
      v_result := 't';
    end if;
     
    return v_result;

  end is_next;
  
end publishing_wf;
/
show errors

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
  'publishing_wf', 'authoring', 'authored', 'out', 'publishing_wf.is_next'
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
  'publishing_wf', 'editing', 'edited', 'out', 'publishing_wf.is_next'
);

insert into wf_arcs (
  workflow_key, transition_key, place_key, direction, guard_callback
) values (
  'publishing_wf', 'editing', 'start', 'out', 'publishing_wf.is_next'
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
  'publishing_wf', 'approval', 'end', 'out', 'publishing_wf.is_next'
);

insert into wf_arcs (
  workflow_key, transition_key, place_key, direction, guard_callback
) values (
  'publishing_wf', 'approval', 'authored', 'out', 'publishing_wf.is_next'
);

insert into wf_arcs (
  workflow_key, transition_key, place_key, direction, guard_callback
) values (
  'publishing_wf', 'approval', 'start', 'out', 'publishing_wf.is_next'
);


declare
    v_attribute_id acs_attributes.attribute_id%TYPE;
begin
    v_attribute_id := workflow.create_attribute(
	workflow_key   => 'publishing_wf',
	attribute_name => 'next_place',
	datatype       => 'string',
	wf_datatype    => 'none',
	pretty_name    => 'Next Place',
	default_value  => 'start'
    );

    insert into wf_transition_attribute_map
        (workflow_key, transition_key, attribute_id, sort_order) 
    values
        ('publishing_wf', 'authoring', v_attribute_id, 1);

    insert into wf_transition_attribute_map
        (workflow_key, transition_key, attribute_id, sort_order) 
    values
        ('publishing_wf', 'editing', v_attribute_id, 1);

    insert into wf_transition_attribute_map
        (workflow_key, transition_key, attribute_id, sort_order) 
    values
        ('publishing_wf', 'approval', v_attribute_id, 1);

end;
/
show errors;

