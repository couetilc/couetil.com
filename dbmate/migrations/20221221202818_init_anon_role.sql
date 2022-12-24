-- migrate:up
create role anon nologin;
grant usage on schema api_todo_app to anon;
grant select on api_todo_app.todos to anon;
create role authenticator noinherit login password 'mysecretpassword';
grant anon to authenticator;


-- migrate:down
revoke select on api_todo_app.todos from anon;
revoke usage on schema api_todo_app from anon;
revoke anon from authenticator;
drop role authenticator;
drop role anon;

