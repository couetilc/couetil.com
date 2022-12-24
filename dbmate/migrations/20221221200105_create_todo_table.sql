-- migrate:up
create table api_todo_app.todos (
  id serial primary key,
  done boolean not null default false,
  task text not null,
  due timestamptz
);

insert into api_todo_app.todos (task) values
  ('finish tutorial 0'),
  ('pat self on back')
;

-- migrate:down

drop table if exists api_todo_app.todos;
