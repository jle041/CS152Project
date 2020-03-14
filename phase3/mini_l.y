%{
#define YY_NO_UNPUT
#include <stdio.h>
#include <string.h>
#include <vector>
#include <map>
#include <stdlib.h>

void yyerror(const char* s);
int yylex();
extern int currLine;
extern int currPos;
extern char* yytext;
extern char* newProgram;
std::string createT();
std::string createLabel();
char empty[1] = "";
std::map<std::string, int> varMap;
std::map<std::string, int> funcMap;
  
std::vector<std::string> reserved = {"FUNCTION","BEGIN_PARAMS","END_PARAMS","BEGIN_LOCALS","END_LOCALS","BEGIN_BODY","END_BODY","INTEGER","ARRAY","OF","IF","THEN","ENDIF","ELSE","WHILE","DO","FOR","IN","BEGINLOOP","ENDLOOP","CONTINUE","READ","WRITE","AND","OR", "NOT", "TRUE", "FALSE", "RETURN", "SUB", "ADD", "MULT", "DIV", "MOD", "EQ", "NEQ", "LT", "GT", "LTE", "GTE", "L_PAREN", "R_PAREN", "L_SQUARE_BRACKET","R_SQUARE_BRACKET","COLON","SEMICOLON","COMMA","ASSIGN","function","Ident","beginparams","endparams","beginlocals","endlocals","integer","beginbody","endbody","beginloop","endloop","if","endif","foreach","continue","while","else","read","do","write"};
%}



%union{
    char* op_val;
    int val;
    struct E {
        char* pStream;
        char* outputCode;
        bool array;
    } expr;
    struct S {
        char* outputCode;
    } stat;
}
%error-verbose
%start Program
%token <op_val> IDENT
%token <val> NUMBER
%type <expr> Ident LocalIdent FunctionIdent
%type <expr> Declarations Declaration Identifiers Var Vars
%type <stat> Statements Statement ElseStatement
%type <expr> Expression Expressions MultExp Term BoolExp RAExp RExp RExp1 Comp
%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY OF IF THEN ENDIF ELSE WHILE DO FOR IN BEGINLOOP ENDLOOP CONTINUE READ WRITE
%left AND OR
%right NOT
%token TRUE FALSE RETURN
%left MULT DIV MOD ADD SUB
%left LT LTE GT GTE EQ NEQ
%token L_PAREN R_PAREN
%token L_SQUARE_BRACKET R_SQUARE_BRACKET
%token COLON SEMICOLON COMMA
%left ASSIGN
%%  
Program:         %empty
{
  std::string tempMain = "main";
  if ( funcMap.find(tempMain) == funcMap.end()) {
    char arr[256];
    snprintf(arr, 256, "No main function declared");
    yyerror(arr);
  }

  if (varMap.find(std::string(newProgram)) != varMap.end()) {
    char arr[256];
    snprintf(arr, 256, "Cannot have declared program name as a variable.");
    yyerror(arr);
  }
}
| Function Program
{
};
Function:        FUNCTION FunctionIdent SEMICOLON BEGIN_PARAMS Declarations END_PARAMS BEGIN_LOCALS Declarations END_LOCALS BEGIN_BODY Statements END_BODY
{
  std::string outputString = "func ";
  
  outputString = outputString + $2.pStream + "\n" + $2.outputCode + $5.outputCode;
  
  std::string wordChecks = $5.outputCode;
  int pNum = 0;
  while (wordChecks.find(".") != std::string::npos) {
    size_t currIndex = wordChecks.find(".");
    wordChecks.replace(currIndex, 1, "=");
    std::string param = ", $";
    param.append(std::to_string(pNum++));
    param.append("\n");
    wordChecks.replace(wordChecks.find("\n", currIndex), 1, param);
  }
  outputString = outputString + wordChecks + $8.outputCode;
  std::string statements($11.outputCode);

  if (statements.find("continue") != std::string::npos) {
    printf("ERROR Continue statement not inside loop %s\n", $2.pStream);
  }
  outputString.append(statements);
  outputString.append("endfunc\n");
  
  printf("%s", outputString.c_str());
};
Declaration:     Identifiers COLON INTEGER
{
  std::string vars($1.pStream);
  std::string outputString;
  std::string variable;
  bool cont = true;

  size_t prevIndex = 0;
  size_t currIndex = 0;
  bool ifReserved = false;
  while (cont) {
    currIndex = vars.find("|", prevIndex);
    if (currIndex == std::string::npos) {
      outputString.append(". ");
      variable = vars.substr(prevIndex,currIndex);
      outputString.append(variable);
      outputString.append("\n");
      cont = false;
    }
    else {
      size_t totalLen = currIndex - prevIndex;
      outputString.append(". ");
      variable = vars.substr(prevIndex, totalLen);
      outputString.append(variable);
      outputString.append("\n");
    }

    for (unsigned int i = 0; i < reserved.size(); ++i) {
      if (reserved.at(i) == variable) {
        ifReserved = true;
      }
    } 

    if (varMap.find(variable) != varMap.end()) {
      char arr[256];
      snprintf(arr, 256, "Variable redeclared %s", variable.c_str());
      yyerror(arr);
    }
    else if (ifReserved){
      char arr[256];
      snprintf(arr, 256, "Cannot use reserved words %s", variable.c_str());
      yyerror(arr);
    }
    else {
      varMap.insert(std::pair<std::string,int>(variable,0));
    }
    
    prevIndex = currIndex + 1;
  }
  
  $$.outputCode = strdup(outputString.c_str());
  $$.pStream = strdup(empty);	      
}
| Identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER
{

  if ($5 <= 0) {
    char arr[256];
    snprintf(arr, 256, "Cannot have negative array");
    yyerror(arr);
  }
  
  std::string vars($1.pStream);
  std::string outputString;
  std::string variable;
  bool contLoop = true;

  size_t prevIndex = 0;
  size_t currIndex = 0;
  while (contLoop) {
    currIndex = vars.find("|", prevIndex);
    if (currIndex == std::string::npos) {
      outputString.append(".[] ");
      variable = vars.substr(prevIndex, currIndex);
	  outputString = outputString + variable + ", " + std::to_string($5) + "\n";
      contLoop = false;
    }
    else {
      size_t totalLen = currIndex - prevIndex;
      outputString.append(".[] ");
      variable = vars.substr(prevIndex, totalLen);
	  outputString = outputString + variable + ", " + std::to_string($5) + "\n";
    }

    if (varMap.find(variable) != varMap.end()) {
      char arr[256];
      snprintf(arr, 256, "Variable redeclared %s", variable.c_str());
      yyerror(arr);
    }
    else {
      varMap.insert(std::pair<std::string,int>(variable,$5));
    }
      
    prevIndex = currIndex + 1;
  }
  
  $$.outputCode = strdup(outputString.c_str());
  $$.pStream = strdup(empty);	      
};
Declarations:    %empty
{
  $$.outputCode = strdup(empty);
  $$.pStream = strdup(empty);
}
| Declaration SEMICOLON Declarations
{
  std::string outputString;
  outputString = outputString + $1.outputCode + $3.outputCode; 
  $$.outputCode = strdup(outputString.c_str());
  $$.pStream = strdup(empty);
};
Identifiers:     Ident
{
  $$.pStream = strdup($1.pStream);
  $$.outputCode = strdup(empty);
}
| Ident COMMA Identifiers
{

  std::string outputString;
  outputString = outputString + $1.pStream + "|" + $3.pStream;
  $$.pStream = strdup(outputString.c_str());
  $$.outputCode = strdup(empty);
}
Statements:      Statement SEMICOLON Statements
{
  std::string outputString;
  outputString.append($1.outputCode);
  outputString.append($3.outputCode);
  $$.outputCode = strdup(outputString.c_str());
}
| Statement SEMICOLON
{
  std::string outputString;
  outputString.append($1.outputCode);
  $$.outputCode = strdup(outputString.c_str());
};
Statement:      Var ASSIGN Expression
{
  std::string outputString;
  outputString.append($1.outputCode);
  outputString.append($3.outputCode);
  std::string intermediate = $3.pStream;
  if ($1.array && $3.array) {

    
    outputString = outputString + ". " + intermediate + "\n=[] " + intermediate + ", " + $3.pStream + "\n" + "[]= ";
  }
  else if ($1.array) {
    outputString.append("[]= ");
  }
  else if ($3.array) {
    outputString.append("=[] ");
  }
  else {
    outputString.append("= ");
  }
  
  outputString = outputString + $1.pStream + ", " + intermediate + "\n";
  $$.outputCode = strdup(outputString.c_str());
}
| IF BoolExp THEN Statements ElseStatement ENDIF
{
  std::string then_begin = createLabel();
  std::string after = createLabel();
  std::string outputString;

  outputString.append($2.outputCode);

  outputString = outputString + "?:= " + then_begin + ", " + $2.pStream + "\n";
  outputString.append($5.outputCode);
  outputString = outputString + ":= " + after + "\n";
  outputString = outputString + ": " + then_begin + "\n";
  outputString.append($4.outputCode);

  outputString = outputString + ": " + after + "\n";
  $$.outputCode = strdup(outputString.c_str());
}		 
| WHILE BoolExp BEGINLOOP Statements ENDLOOP
{
  std::string outputString;
  std::string beginWhile = createLabel();
  std::string beginLoop = createLabel();
  std::string endLoop = createLabel();

  std::string statement = $4.outputCode;
  std::string jump;
  jump.append(":= ");
  jump.append(beginWhile);
  while (statement.find("continue") != std::string::npos) {
    statement.replace(statement.find("continue"), 8, jump);
  }
  
  outputString = outputString + ": " + beginWhile + "\n" + $2.outputCode + "?:= " + beginLoop + ", " + $2.pStream + "\n" + ":= " + endLoop + "\n" + ": " + beginLoop + "\n" + statement + ":= " + beginWhile + "\n" + ": " + endLoop + "\n";
  $$.outputCode = strdup(outputString.c_str());
}
| DO BEGINLOOP Statements ENDLOOP WHILE BoolExp
{
  std::string outputString;
  std::string beginLoop = createLabel();
  std::string beginWhile = createLabel();
  std::string statement = $3.outputCode;
  std::string jump;
  jump.append(":= ");
  jump.append(beginWhile);
  while (statement.find("continue") != std::string::npos) {
    statement.replace(statement.find("continue"), 8, jump);
  }

  outputString = outputString + ": " + beginLoop + "\n" + statement + ": " + beginWhile + "\n" + $6.outputCode + "?:= " + beginLoop + ", " + $6.pStream + "\n";
  
  $$.outputCode = strdup(outputString.c_str());
}
| FOR LocalIdent IN Ident BEGINLOOP Statements ENDLOOP
{
  std::string outputString;
  std::string count = createT();
  std::string check = createT();
  std::string begin = createLabel();
  std::string beginLoop = createLabel();
  std::string increment = createLabel();
  std::string endLoop = createLabel();

  std::string statement = $6.outputCode;
  std::string jump;
  jump.append(":= ");
  jump.append(increment);
  while (statement.find("continue") != std::string::npos) {
    statement.replace(statement.find("continue"), 8, jump);
  }

  if (varMap.find(std::string($4.pStream)) == varMap.end()) {
    char arr[256];
    snprintf(arr, 256, "Undeclared variable used %s", $4.pStream);
    yyerror(arr);
  }

  else if (varMap.find(std::string($4.pStream))->second == 0) {
    char arr[256];
    snprintf(arr, 256, "Cannot use scalar %s in for", $4.pStream);
    yyerror(arr);
  }
 
  
  outputString = outputString + ". " + $2.pStream + "\n" + ". " + check + "\n" + ". " + count + "\n" + "= " + count + ", 0" + "\n";

  outputString = outputString + ": " + begin + "\n" + "< " + check + ", " + count + ", " + std::to_string(varMap.find(std::string($4.pStream))->second) + "\n";
  outputString = outputString + "?:= " + beginLoop + ", " + check + "\n";
  outputString = outputString + ":= " + endLoop + "\n";
  outputString = outputString + ": " + beginLoop + "\n";
  outputString = outputString + "=[] " + $2.pStream + ", " + $4.pStream + ", " + count + "\n";
  outputString.append(statement);
  outputString = outputString + ": " + increment + "\n" + "+ " + count + ", " + count + ", 1\n";
  outputString = outputString + ":= " + begin + "\n";
  

  outputString = outputString + ": " + endLoop + "\n";
  $$.outputCode = strdup(outputString.c_str());
}
| READ Vars
{
  std::string outputString = $2.outputCode;
  size_t currIndex = 0;
  do {
    currIndex = outputString.find("|", currIndex);
    if (currIndex == std::string::npos)
      break;
    outputString.replace(currIndex, 1, "<");
  } while (true);
  $$.outputCode = strdup(outputString.c_str());
}
| WRITE Vars
{
  std::string outputString = $2.outputCode;
  size_t currIndex = 0;
  do {
    currIndex = outputString.find("|", currIndex);
    if (currIndex == std::string::npos)
      break;
    outputString.replace(currIndex, 1, ">");
  } while (true);
  $$.outputCode = strdup(outputString.c_str());
}
| CONTINUE
{

  std::string outputString = "continue\n";
  $$.outputCode = strdup(outputString.c_str());
}
| RETURN Expression
{
  std::string outputString;
  outputString.append($2.outputCode);
  outputString.append("ret ");
  outputString.append($2.pStream);
  outputString.append("\n");
  $$.outputCode = strdup(outputString.c_str());
};
ElseStatement:   %empty
{
  $$.outputCode = strdup(empty);
}
| ELSE Statements
{
  $$.outputCode = strdup($2.outputCode);
};
Var:             Ident L_SQUARE_BRACKET Expression R_SQUARE_BRACKET
{

  if (varMap.find(std::string($1.pStream)) == varMap.end()) {
    char arr[256];
    snprintf(arr, 256, "Undeclared variable used %s", $1.pStream);
    yyerror(arr);
  }

  else if (varMap.find(std::string($1.pStream))->second == 0) {
    char arr[256];
    snprintf(arr, 256, "Cannot index variable that is not an array %s", $1.pStream);
    yyerror(arr);
  }
  std::string outputString;

  outputString = outputString + $1.pStream + ", " + $3.pStream;
  $$.outputCode = strdup($3.outputCode);
  $$.pStream = strdup(outputString.c_str());
  $$.array = true;
}
| Ident
{

  if (varMap.find(std::string($1.pStream)) == varMap.end()) {
    char arr[256];
    snprintf(arr, 256, "Undeclared variable used %s", $1.pStream);
    yyerror(arr);
  }

  else if (varMap.find(std::string($1.pStream))->second > 0) {
    char arr[256];
    snprintf(arr, 256, "No index put in %s", $1.pStream);
    yyerror(arr);
  }
  $$.outputCode = strdup(empty);
  $$.pStream = strdup($1.pStream);
  $$.array = false;
};

Vars:            Var
{
  std::string outputString;
  outputString.append($1.outputCode);
  if ($1.array)
    outputString.append(".[]| ");
  else
    outputString.append(".| ");

  outputString = outputString + $1.pStream + "\n";
  
  $$.outputCode = strdup(outputString.c_str());
  $$.pStream = strdup(empty);
}
| Var COMMA Vars
{
  std::string outputString;
  outputString.append($1.outputCode);
  if ($1.array)
    outputString.append(".[]| ");
  else
    outputString.append(".| ");

  outputString = outputString + $1.pStream + "\n" + $3.outputCode;
  
  $$.outputCode = strdup(outputString.c_str());
  $$.pStream = strdup(empty);
};
Expression:      MultExp
{
  $$.outputCode = strdup($1.outputCode);
  $$.pStream = strdup($1.pStream);
}
| MultExp ADD Expression
{
  $$.pStream = strdup(createT().c_str());
  
  std::string outputString;

  outputString = outputString + $1.outputCode + $3.outputCode + ". " + $$.pStream + "\n" + "+ " + $$.pStream + ", " + $1.pStream + ", " + $3.pStream + "\n";
  $$.outputCode = strdup(outputString.c_str());
}
| MultExp SUB Expression
{
  $$.pStream = strdup(createT().c_str());
  
  std::string outputString;

  outputString = outputString + $1.outputCode + $3.outputCode + ". " + $$.pStream + "\n" + "- " + $$.pStream + ", " + $1.pStream + ", " + $3.pStream + "\n";
  $$.outputCode = strdup(outputString.c_str());
};

Expressions:     %empty
{
  $$.outputCode = strdup(empty);
  $$.pStream = strdup(empty);
}
| Expression COMMA Expressions
{
  std::string outputString;

  outputString = outputString + $1.outputCode + "param " + $1.pStream + "\n" + $3.outputCode;
  $$.outputCode = strdup(outputString.c_str());
  $$.pStream = strdup(empty);
}
| Expression
{
  std::string outputString;

  outputString = outputString + $1.outputCode + "param " + $1.pStream + "\n";
  $$.outputCode = strdup(outputString.c_str());
  $$.pStream = strdup(empty);
};
MultExp:         Term
{
  $$.outputCode = strdup($1.outputCode);
  $$.pStream = strdup($1.pStream);
}
| Term MULT MultExp
{
  $$.pStream = strdup(createT().c_str());
  
  std::string outputString;

  outputString = outputString + ". " + $$.pStream + "\n" + $1.outputCode + $3.outputCode + "* " + $$.pStream + ", " + $1.pStream + ", " + $3.pStream + "\n";
  $$.outputCode = strdup(outputString.c_str());
}
| Term DIV MultExp
{
  $$.pStream = strdup(createT().c_str());
  
  std::string outputString;

  outputString = outputString + ". " + $$.pStream + "\n" + $1.outputCode + $3.outputCode + "/ " + $$.pStream + ", " + $1.pStream + ", " + $3.pStream + "\n";
  $$.outputCode = strdup(outputString.c_str());
}
| Term MOD MultExp
{
  $$.pStream = strdup(createT().c_str());
  
  std::string outputString;

  outputString = outputString + ". " + $$.pStream + "\n" + $1.outputCode + $3.outputCode + "% " + $$.pStream + ", " + $1.pStream + ", " + $3.pStream + "\n";
  $$.outputCode = strdup(outputString.c_str());
};
Term:            Var
{

  if ($$.array == true) {
    std::string outputString;
    std::string intermediate = createT();
	
    outputString = outputString + $1.outputCode + ". " + intermediate + "\n" + "=[] " + intermediate + ", " + $1.pStream + "\n";
    $$.outputCode = strdup(outputString.c_str());
    $$.pStream = strdup(intermediate.c_str());
    $$.array = false;
  }
  else {
    $$.outputCode = strdup($1.outputCode);
    $$.pStream = strdup($1.pStream);
  }
}
| SUB Var
{

  $$.pStream = strdup(createT().c_str());
  std::string outputString;

  outputString = outputString + $2.outputCode + ". " + $$.pStream + "\n";
  if ($2.array) {

    outputString = outputString + "=[] " + $$.pStream + ", " + $2.pStream + "\n";
  }
  else {

    outputString = outputString + "= " + $$.pStream + ", " + $2.pStream + "\n";
  }

  outputString = outputString + "* " + $$.pStream + ", " + $$.pStream + ", -1\n";
  
  $$.outputCode = strdup(outputString.c_str());
  $$.array = false;
}
| NUMBER
{
  $$.outputCode = strdup(empty);
  $$.pStream = strdup(std::to_string($1).c_str());
}
| SUB NUMBER
{
  std::string outputString;
  outputString.append("-");
  outputString.append(std::to_string($2));
  $$.outputCode = strdup(empty);
  $$.pStream = strdup(outputString.c_str());
}
| L_PAREN Expression R_PAREN
{
  $$.outputCode = strdup($2.outputCode);
  $$.pStream = strdup($2.pStream);
}
| SUB L_PAREN Expression R_PAREN
{
  $$.pStream = strdup($3.pStream);
  std::string outputString;

  outputString = outputString + $3.outputCode + "* " + $3.pStream + ", " + $3.pStream + ", -1\n";
  $$.outputCode = strdup(outputString.c_str());
}
| Ident L_PAREN Expressions R_PAREN
{
   
  if (funcMap.find(std::string($1.pStream)) == funcMap.end()) {
    char arr[256];
    snprintf(arr, 256, "Use of undeclared function %s", $1.pStream);
    yyerror(arr);
  }
  $$.pStream = strdup(createT().c_str());
  std::string outputString;

  outputString = outputString + $3.outputCode + ". " + $$.pStream + "\n" + "call " + $1.pStream + ", " + $$.pStream + "\n";
  
  $$.outputCode = strdup(outputString.c_str());
};
BoolExp:         RAExp 
{
  $$.pStream = strdup($1.pStream);
  $$.outputCode = strdup($1.outputCode);
}
| RAExp OR BoolExp
{
  std::string dest = createT();
  std::string outputString;

  outputString = outputString + $1.outputCode + $3.outputCode + ". " + dest + "\n" + "|| " + dest + ", " + $1.pStream + ", " + $3.pStream + "\n";
  $$.outputCode = strdup(outputString.c_str());
  $$.pStream = strdup(dest.c_str());
};
RAExp:           RExp
{
  $$.pStream = strdup($1.pStream);
  $$.outputCode = strdup($1.outputCode);
}
| RExp AND RAExp
{
  std::string dest = createT();
  std::string outputString;

  outputString = outputString + $1.outputCode + $3.outputCode + ". " + dest + "\n" + "&& " + dest + ", " + $1.pStream + ", " + $3.pStream + "\n";
  $$.outputCode = strdup(outputString.c_str());
  $$.pStream = strdup(dest.c_str());
};
RExp:            NOT RExp1 
{
  std::string dest = createT();
  std::string outputString;

  outputString = outputString + $2.outputCode + ". " + dest + "\n" + "! " + dest + ", " + $2.pStream + "\n";
  $$.outputCode = strdup(outputString.c_str());
  $$.pStream = strdup(dest.c_str());
}
| RExp1
{
  $$.pStream = strdup($1.pStream);
  $$.outputCode = strdup($1.outputCode);
};
RExp1:           Expression Comp Expression
{
  std::string dest = createT();
  std::string outputString;  

  outputString = outputString + $1.outputCode + $3.outputCode + ". " + dest + "\n" + $2.pStream + dest + ", " + $1.pStream + ", " + $3.pStream + "\n";
  $$.outputCode = strdup(outputString.c_str());
  $$.pStream = strdup(dest.c_str());
}
| TRUE
{
  char arr[2] = "1";
  $$.pStream = strdup(arr);
  $$.outputCode = strdup(empty);
}
| FALSE
{
  char arr[2] = "0";
  $$.pStream = strdup(arr);
  $$.outputCode = strdup(empty);
}
| L_PAREN BoolExp R_PAREN
{
  $$.pStream = strdup($2.pStream);
  $$.outputCode = strdup($2.outputCode);
};
Comp:            EQ
{
  std::string outputString = "== ";
  $$.pStream = strdup(outputString.c_str());
  $$.outputCode = strdup(empty);
}
| NEQ
{
  std::string outputString = "!= ";
  $$.pStream = strdup(outputString.c_str());
  $$.outputCode = strdup(empty);
}
| LT
{
  std::string outputString = "< ";
  $$.pStream = strdup(outputString.c_str());
  $$.outputCode = strdup(empty);
}
| GT
{
  std::string outputString = "> ";
  $$.pStream = strdup(outputString.c_str());
  $$.outputCode = strdup(empty);
}
| LTE
{
  std::string outputString = "<= ";
  $$.pStream = strdup(outputString.c_str());
  $$.outputCode = strdup(empty);
}
| GTE
{
  std::string outputString = ">= ";
  $$.pStream = strdup(outputString.c_str());
  $$.outputCode = strdup(empty);
};
Ident:      IDENT
{
  $$.pStream = strdup($1);
  $$.outputCode = strdup(empty);;
};
LocalIdent:      IDENT
{

  std::string variable($1);
  if (varMap.find(variable) != varMap.end()) {
    char arr[256];
    snprintf(arr, 256, "Variable is redeclared %s", variable.c_str());
    yyerror(arr);
  }
  else {
    varMap.insert(std::pair<std::string,int>(variable,0));
  }
  $$.pStream = strdup($1);
  $$.outputCode = strdup(empty);;
};
FunctionIdent: IDENT
{
  if (funcMap.find(std::string($1)) != funcMap.end()) {
    char arr[256];
    snprintf(arr, 256, "Function is redeclared %s", $1);
    yyerror(arr);
  }
  else {
    funcMap.insert(std::pair<std::string,int>($1,0));
  }
  $$.pStream = strdup($1);
  $$.outputCode = strdup(empty);;
}
%%
void yyerror(const char* s) {
   printf("ERROR: %s at symbol \"%s\" on line %d, col %d\n", s, yytext, currLine, currPos);
}
std::string createT() {
  static int num = 0;
  std::string outputString = "_t" + std::to_string(num++);
  return outputString;
}
std::string createLabel() {
  static int num = 0;
  std::string outputString = 'L' + std::to_string(num++);
  return outputString;
}
