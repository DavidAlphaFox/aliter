all: compile

compile:
	erl -pa ebin -make

install: compile
	erl -noshell -pa ebin -sname aliter -eval "aliter:install()."

start: compile
	erl -noshell -pa ebin -sname aliter -eval "application:start(aliter)."
