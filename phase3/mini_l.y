%{
#include <stdio.h>
#include <stdlib.h>
int yyparse();
void yyerror(const char *s);
int yylex(void);
extern int currLine;
extern int currPos;
FILE * yyin;
%}

%union {
    int int_val;
    char char_val[100];
}

%error-verbose
%start prog_start 

%token <int_val> NUMBER
%token <char_val> IDENT
%token FUNCTION
%token BEGIN_PARAMS
%token END_PARAMS
%token BEGIN_LOCALS
%token END_LOCALS
%token BEGIN_BODY
%token END_BODY
%token INTEGER
%token ARRAY
%token OF
%token IF
%token THEN
%token ENDIF
%token ELSE
%token WHILE
%token DO
%token FOREACH
%token IN
%token BEGINLOOP
%token ENDLOOP
%token CONTINUE
%token READ
%token WRITE
%token AND
%token OR
%token NOT
%token TRUE
%token FALSE
%token RETURN
%token FOR
%token ADD
%token SUB
%token MULT
%token DIV
%token MOD
%token EQ
%token NEQ
%token LT
%token GT
%token LTE
%token GTE
%token SEMICOLON
%token COLON
%token COMMA
%token L_PAREN
%token R_PAREN
%token L_SQUARE_BRACKET
%token R_SQUARE_BRACKET
%token ASSIGN

%%
prog_start: {printf("prog_start -> functions\n");}
            | functions prog_start{}
;

functions: {printf("functions -> epsilon\n");}
            | function functions{printf("functions -> function functions\n");}
;

function: FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {printf("function -> FUNCTION IDENT SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY\n");};

declarations: {printf("declarations -> epsilon\n");}
              | declaration SEMICOLON declarations {printf("declarations -> declaration SEMICOLON declarations\n");}
;

declaration: identifiers COLON INTEGER {printf("declaration -> identifiers COLON INTEGER\n");}
             | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {printf("declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER %d R_SQUARE_BRACKET OF INTEGER;\n", $5);} 
             | identifiers error INTEGER {yyerror("invalid declaration");} //error might be wrong 
;
identifiers: ident {printf("identifiers -> ident\n");}
             | ident COMMA identifiers {printf("identifiers -> ident COMMA identifiers\n");}
;  

ident: IDENT {printf("ident -> IDENT %s \n", $1);};

statements: {printf("statements -> epsilon\n");}
            | statement SEMICOLON statements {printf("statements -> statement SEMICOLON statements\n");}
;


statement: var ASSIGN expression {printf("statement -> var ASSIGN expression\n");}
           | IF bool_exp THEN statements ENDIF {printf("statement -> IF bool_exp THEN statements ENDIF\n");}
           | IF bool_exp THEN statements ELSE statements ENDIF{printf("statement -> IF bool_exp THEN statements ELSE statements ENDIF\n");}
           | WHILE bool_exp BEGINLOOP statements ENDLOOP {printf("statement -> WHILE bool_exp BEGINLOOP statements ENDLOOP\n");}
           | DO BEGINLOOP statements ENDLOOP WHILE bool_exp {printf("statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_exp\n");}
           | FOR vars ASSIGN NUMBER bool_exp vars ASSIGN BEGINLOOP statements ENDLOOP {printf("statement -> FOR vars ASSIGN NUMBER bool_exp vars ASSIGN BEGINLOOP statements ENDLOOP\n");}
           | READ vars {printf("statement -> READ vars\n");}
           | WRITE vars {printf("statement -> WRITE vars\n");}
           | CONTINUE {printf("statement -> CONTINUE\n");}
           | RETURN expression {printf("statement -> RETURN expression\n");}
;

bool_exp: relation_and_exp {printf("bool_exp -> relation_and_exp\n");}
          | relation_and_exp OR bool_exp {printf("bool_exp -> relation_and_exp OR relation_and_exp\n");}
;

relation_and_exp: relation_exp {printf("relation_and_exp -> relation_exp\n");}
                  | relation_exp AND relation_and_exp {printf("relation_and_exp -> relation_exp AND relation_exp\n");}
;

relation_exp: expression comp expression {printf("relation_exp -> expression comp expression\n");}
              | TRUE {printf("relation_exp -> TRUE\n");}
              | FALSE {printf("relation_exp -> FALSE\n");}
              | L_PAREN bool_exp R_PAREN {printf("relation_exp -> L_PAREN bool_exp R_PAREN\n");}
              | NOT expression comp expression {printf("r_expr -> NOT expression comp expression\n");}
              | NOT TRUE {printf("relation_exp -> NOT TRUE\n");}
              | NOT FALSE {printf("relation_exp -> NOT FALSE\n");}
              | NOT L_PAREN bool_exp R_PAREN {printf("relation_exp -> NOT L_PAREN bool_exp R_PAREN\n");}
;

comp: EQ {printf("comp -> EQ\n");}
      | NEQ {printf("comp -> NEG\n");}
      | GT {printf("comp -> GT\n");}
      | LT {printf("comp -> LT\n");}
      | GTE {printf("comp -> GTE\n");}
      | LTE {printf("comp -> LTE\n");}
;
	
expression: multiplicative_expr{printf("expression -> multiplicative_expr\n");}
            | multiplicative_expr ADD expression{printf("expression -> multiplicative_expr ADD multiplicative_expr\n");}
            | multiplicative_expr SUB expression{printf("expression -> multiplicative_expr SUB multiplicative_expr\n");}
;

multiplicative_expr: term{printf("multiplicative_expr -> term\n");}
                           | term MULT multiplicative_expr {printf("multiplicative_expr -> term MULT term\n");}
                           | term DIV multiplicative_expr {printf("multiplicative_expr -> term DIV term\n");}
                           | term MOD multiplicative_expr {printf("multiplicative_expr -> term MOD term\n");}
;

term: var{printf("term -> var\n");}
      | NUMBER {printf("term -> NUMBER\n"); }
      | L_PAREN expression R_PAREN {printf("term -> L_PAREN expression R_PAREN\n");}
      | SUB var {printf("term -> SUB var\n");}| SUB NUMBER {printf("term -> SUB NUMBER \n");}
      | SUB L_PAREN expression R_PAREN {printf("term -> SUB L_PAREN expression R_PAREN\n");}
      | ident bterm {printf("term -> IDENT bterm\n");}
;

bterm: L_PAREN bterm_ex R_PAREN{printf("bterm -> ident L_PAREN bterm_ex R_PAREN\n");}
       | L_PAREN R_PAREN {printf("bterm -> ident  L_PAREN R_PAREN\n");}
;  

bterm_ex: expression{printf("bterm_ex -> expression\n");}
          | expression COMMA bterm_ex {printf("bterm_ex -> expression COMMA bterm_ex\n");}
;

var: ident{printf("var -> ident\n");}
     | ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET {printf("var -> ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n");}
;

vars: var {printf("vars -> var\n");}
      | var COMMA vars {printf("vars -> var COMMA vars\n");}
;

%%

int main(int argc, char **argv) {
   if (argc > 1) {
      yyin = fopen(argv[1], "r\n");
      if (yyin == NULL){
         printf("syntax: %s filename\n", argv[0]);
      }//end if
   }//end if
   yyparse(); // Calls yylex() for tokens.
   return 0;
}
void yyerror (const char *msg) {
    printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}
