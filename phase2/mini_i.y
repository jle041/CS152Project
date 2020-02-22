//submitted
/* CS152 Phase 2
   Robert Yee
   861270047
   
   Stephanie Qian
   861283827
*/

/* C Declaration */
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
/* Define collection of data types for semantic values */
%union {
    int int_val;
    //char* char_val;
    char char_val[100];
}

%error-verbose
%start prog_start

/* Bison Declartions */ 

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
%token TRUE
%token FALSE
%token RETURN
%token SEMICOLON
%token COMMA
%token COLON
%token LPAREN
%token RPAREN
%token LSQUARE
%token RSQUARE
%token SUB
%token ADD
%token MULT
%token DIV
%token MOD
%token EQ
%token NEQ
%token LT
%token GT
%token LTE
%token GTE
%token AND
%token OR
%token NOT
%token ASSIGN

%% /* Grammar Rules */
prog_start: {printf("prog_start -> epsilon\n");}
            | functions prog_start{printf("prog_start -> function prog_start\n");} 
;

//useless?
functions: {printf("functions -> epsilon\n");}
           | function functions{printf("functions -> function functions\n");}  
;

function: FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {printf("function -> FUNCTION IDENT SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY\n");};

declarations: {printf("declarations -> epsilon\n");}
              | declaration SEMICOLON declarations {printf("declarations -> declaration SEMICOLON declarations\n");}
;

declaration: identifiers COLON INTEGER {printf("declaration -> identifiers COLON INTEGER\n");}
             | identifiers COLON ARRAY LSQUARE NUMBER RSQUARE OF INTEGER {printf("declaration -> identifiers COLON ARRAY LSQUARE NUMBER %d RSQURE OF INTEGER;\n", $5);} 
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
           | FOREACH ident IN ident BEGINLOOP statements ENDLOOP {printf("statement -> FOREACH IDENT IN IDENT BEGINLOOP statements ENDLOOP\n");}
           | READ vars {printf("statement -> READ vars\n");}| WRITE vars {printf("statement -> WRITE vars\n");}
           | CONTINUE {printf("statement -> CONTINUE\n");}| RETURN expression {printf("statement -> RETURN expression\n");}
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
              | LPAREN bool_exp RPAREN {printf("relation_exp -> LPAREN bool_exp RPAREN\n");}
              | NOT expression comp expression {printf("r_expr -> NOT expression comp expression\n");}
              | NOT TRUE {printf("relation_exp -> NOT TRUE\n");}
              | NOT FALSE {printf("relation_exp -> NOT FALSE\n");}
              | NOT LPAREN bool_exp RPAREN {printf("relation_exp -> NOT LPAREN bool_exp RPAREN\n");}
;

comp: EQ {printf("comp -> EQ\n");}
      | NEQ {printf("comp -> NEG\n");}
      | GT {printf("comp -> GT\n");}
      | LT {printf("comp -> LT\n");}
      | GTE {printf("comp -> GTE\n");}
      | LTE {printf("comp -> LTE\n");}
;
	
expression: multiplicative-expr{printf("expression -> multiplicative-expr\n");}
            | multiplicative-expr ADD expression{printf("expression -> multiplicative-expr ADD multiplicative-expr\n");}
            | multiplicative-expr SUB expression{printf("expression -> multiplicative-expr SUB multiplicative-expr\n");}
;

multiplicative-expr: term{printf("multiplicative-expr -> term\n");}
                           | term MULT multiplicative-expr {printf("multiplicative-expr -> term MULT term\n");}
                           | term DIV multiplicative-expr {printf("multiplicative-expr -> term DIV term\n");}
                           | term MOD multiplicative-expr {printf("multiplicative-expr -> term MOD term\n");}
;

term: var{printf("term -> var\n");}
      | NUMBER {printf("term -> NUMBER\n"); }
      | LPAREN expression RPAREN {printf("term -> LPAREN expression RPAREN\n");}
      | SUB var {printf("term -> SUB var\n");}| SUB NUMBER {printf("term -> SUB NUMBER \n");}
      | SUB LPAREN expression RPAREN {printf("term -> SUB LPAREN expression RPAREN\n");}
      | ident bterm {printf("term -> IDENT bterm\n");}
;

bterm: LPAREN bterm_ex RPAREN{printf("bterm -> ident LPAREN bterm_ex RPAREN\n");}
       | LPAREN RPAREN {printf("bterm -> ident  LPAREN RPAREN\n");}
;  

bterm_ex: expression{printf("bterm_ex -> expression\n");}
          | expression COMMA bterm_ex {printf("bterm_ex -> expression COMMA bterm_ex\n");}
;

var: ident{printf("var -> ident\n");}
     | ident LSQUARE expression RSQUARE {printf("var -> ident LSQUARE expression RSQUARE\n");}
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
    printf("** Line %d, position %d: %s\n",currLine,currPos, msg);
}


