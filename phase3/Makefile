CFLAGS = -g -Wall -w -ansi -pedantic

minil: mini_l.lex mini_l.y
	bison -v -d --file-prefix=y mini_l.y
	flex mini_l.lex
	g++ $(CFLAGS) -std=c++11 y.tab.c lex.yy.c -lfl -o my_compiler


