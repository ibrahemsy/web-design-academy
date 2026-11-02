-- Serialize role changes so concurrent requests cannot demote the final two admins.
create or replace function private.set_academy_user_role(
  p_target_user_id uuid,
  p_new_role public.user_role
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_current_role public.user_role;
begin
  if v_actor is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if not private.is_admin() then
    raise exception 'Only administrators can manage account roles' using errcode = '42501';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext('web-design-academy-role-management')::bigint
  );

  select role into v_current_role
  from public.profiles
  where id = p_target_user_id
  for update;

  if not found then
    raise exception 'Profile not found' using errcode = 'P0002';
  end if;

  if p_target_user_id = v_actor and p_new_role <> 'admin'::public.user_role then
    raise exception 'You cannot remove your own administrator role' using errcode = '42501';
  end if;

  if v_current_role = 'admin'::public.user_role
     and p_new_role <> 'admin'::public.user_role
     and (select count(*) from public.profiles where role = 'admin'::public.user_role) <= 1 then
    raise exception 'The last administrator cannot be demoted' using errcode = '23514';
  end if;

  update public.profiles
  set role = p_new_role
  where id = p_target_user_id;

  return jsonb_build_object('user_id', p_target_user_id, 'role', p_new_role::text);
end;
$$;
