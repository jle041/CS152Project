.PHONY: all minil test clean

all: minil test

CFLAGS = -g -Wall -w -ansi -pedantic

minil: mini_l.lex mini_l.y
	bison -v -d --file-prefix=y mini_l.y
	flex mini_l.lex
	g++ $(CFLAGS) -std=c++11 y.tab.c lex.yy.c -lfl -o my_compiler

test: 
	cat fibonacci.min | my_compiler
	echo 5 > input.txt
	mil_run fibonacci.mil < input.txt

clean:
	rm -f input.txt lex.yy.c my_compiler y.output y.tab.c y.tab.h
