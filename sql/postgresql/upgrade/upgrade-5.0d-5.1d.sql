-- 
-- packages/cms/sql/postgresql/upgrade/upgrade-5.0d-5.1d.sql
-- 
-- @author Stan Kaufman (skaufman@epimetrics.com)
-- @creation-date 2005-10-04
-- @cvs-id $Id$
--

update apm_package_types set singleton_p = 'f' where package_key = 'cms';

insert into acs_rel_roles (role,pretty_name,pretty_plural) values ('author','Author','Authors');
insert into acs_rel_roles (role,pretty_name,pretty_plural) values ('editor','Editor','Editors');
insert into acs_rel_roles (role,pretty_name,pretty_plural) values ('publisher','Publisher','Publishers');
-- adds package_id to call to content_item__new
select define_function_args('content_module__new','name,key,root_key,sort_key,parent_id,package_id,object_id,creation_date,creation_user,creation_ip,object_type');
create or replace function content_module__new (varchar,varchar,varchar,integer,integer,integer,integer,timestamptz,integer,varchar,varchar)
returns integer as '
declare
  p_name                        alias for $1;  
  p_key                         alias for $2;  
  p_root_key                    alias for $3;  
  p_sort_key                    alias for $4;  
  p_parent_id                   alias for $5;  
  p_package_id                  alias for $6;
  p_object_id                   alias for $7;  -- null
  p_creation_date               alias for $8;  -- now()
  p_creation_user               alias for $9;  -- null
  p_creation_ip                 alias for $10;  -- null
  p_object_type                 alias for $11; -- ''content_module''
  v_module_id                   integer;       
begin
  v_module_id := content_item__new(
      p_name,
      p_parent_id,
      p_object_id,
      null,
      p_creation_date,
      p_creation_user,
      null,
      p_creation_ip,
      ''content_module'',
      p_object_type,
      null,
      null,
      ''text/plain'',
      null,
      null,
      ''file'',
      p_package_id
  );

  insert into cm_modules
    (module_id, key, name, root_key, sort_key, package_id)
  values
    (v_module_id, p_key, p_name, p_root_key, p_sort_key, p_package_id);

  return v_module_id;

end;' language 'plpgsql';

select define_function_args('content_method__set_default_method','content_type,content_method');
select define_function_args('content_method__unset_default_method','content_type');
select define_function_args('content_method__remove_method','content_type,content_method');
select define_function_args('content_method__add_all_methods','content_type');
select define_function_args('content_method__add_method','content_type,content_method,is_default');
select define_function_args('content_method__is_mapped','content_type,content_method');
select define_function_args('content_method__get_method','content_type');
