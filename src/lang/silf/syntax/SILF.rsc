@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::silf::syntax::SILF

syntax Program = Default: Decl* decls FunDecl+ funDecls;

syntax Decl =
	  VarDecl: "var" TypedIdent varName ";"
	| ArrayDecl: "var" TypedIdent varName "[" Integer size "]" ";"
	;
	
syntax FunDecl =
	  FunNoParams: "function" TypedIdent funName "(" "void" ")" PrePost* "begin" Decl* decls Stmt+ stmts "end"
	| FunParams: "function" TypedIdent funName "(" {TypedIdent ","}+ params ")" PrePost* "begin" Decl* decls Stmt+ stmts "end"
	| FunSigNoParams: "function" TypedIdent funName "(" "void" ")" PrePost* "end"
	| FunSigParams: "function" TypedIdent funName "(" {TypedIdent ","}+ params ")" PrePost* "end"
	;
	
syntax Stmt =
	  Assignment: Ident ident ":=" Exp exp ";"
	| ArrayAssignment: Ident ident "[" Exp index "]" ":=" Exp exp ";"
	| IfThen: "if" Exp exp "then" Decl* decls Stmt+ stmts "fi"
	| IfThenElse: "if" Exp exp "then" Decl* trueDecls Stmt+ trueStmts "else" Decl* falseDecls Stmt+ falseStmts "fi"
	| For: "for" Ident ident ":=" Exp startRange "to" Exp endRange Invariant* invariants "do" Decl* decls Stmt+ stmts "od"
	| While: "while" Exp exp Invariant* invariants "do" Decl* decls Stmt+ stmts "od"
	| Call: "call" Ident ident "(" {Exp ","}* params ")" ";"
	| Return: "return" Exp exp ";"
	| Write: "write" Exp exp ";"
	| AssumeWithPolicy: "assume" "(" Ident ident ")" ":" Annotation ";"  
	| AssumeNoPolicy: "assume" ":" Annotation ";"  
	| AssertWithPolicy: "assert" "(" Ident ident ")" ":" Annotation ";"  
	| AssertNoPolicy: "assert" ":" Annotation ";"  
	; 

syntax PrePost =
	  PreconditionWithPolicy: "precondition" "(" Ident ident ")" ":" Annotation af ";"  
	| PreconditionNoPolicy: "precondition" ":" Annotation af ";"  
	| PreWithPolicy: "pre" "(" Ident ident ")" ":" Annotation af ";"  
	| PreNoPolicy: "pre" ":" Annotation af ";"  
	| PostconditionWithPolicy: "postcondition" "(" Ident ident ")" ":" Annotation af ";"  
	| PostconditionNoPolicy: "postcondition" ":" Annotation af ";"  
	| PostWithPolicy: "post" "(" Ident ident ")" ":" Annotation af ";"  
	| PostNoPolicy: "post" ":" Annotation af ";"  
	| ModifiesWithPolicy: "modifies" "(" Ident ident ")" ":" {Ident ","}+ ";" 
	| ModifiesNoPolicy: "modifies" ":" {Ident ","}+ ";"
	| ModWithPolicy: "mod" "(" Ident ident ")" ":" {Ident ","}+ ";"  
	| ModNoPolicy: "mod" ":" {Ident ","}+ ";"  
	;
	  
syntax Invariant = 
	  InvWithPolicy: "invariant" "(" Ident ident ")" ":" Annotation ";" 
	| InvNoPolicy: "invariant" ":" Annotation ";" 
	;

syntax Exp =
	  Cast: "cast" "(" Exp expFrom ")" "to" "(" TypeExp toExp ")"
	> CallExp: Ident ident "(" {Exp ","}* exps ")"
	| bracket Bracket: "(" Exp exp ")"
	| Read: "read"
	| Integer: Integer
	| Boolean: Bool
	| left ArrayExp: Ident ident "[" Exp exp "]"
	> IdentExp: Ident ident
	> right Negation: "-" Exp exp
	> left ( Times: Exp leftOp "*" Exp rightOp
	       | Div: Exp leftOp "/" Exp rightOp
	       | Mod: Exp leftOp "%" Exp rightOp )
	> left ( Plus: Exp leftOp "+" Exp rightOp
	       | Minus: Exp leftOp "-" Exp rightOp )
	> non-assoc ( Lt: Exp leftOp "\<" Exp rightOp
	            | LtEq: Exp leftOp "\<=" Exp rightOp
	            | Gt: Exp leftOp "\>" Exp rightOp
	            | GtEq: Exp leftOp "\>=" Exp rightOp
	            | Eq: Exp leftOp "=" Exp rightOp
	            | Neq: Exp leftOp "!=" Exp rightOp )
	> right Not: "not" Exp exp
	> right And: Exp leftOp "and" Exp rightOp
	> right Or: Exp leftOp "or" Exp rightOp
	;

syntax TypeIdentL = lex "$" [a-z][a-zA-Z0-9]*;

syntax TypeVarL = lex "$" [A-Z][a-zA-Z0-9]*;

syntax TypeIdent = TypeIdentL | TypeVarL;

syntax TypeExp = 
	  TIdent: TypeIdent
	| TLiteral: Integer
	| bracket TBracket: "(" TypeExp ")"
	| left TCall: TypeIdent "(" TypeExp ")"
	> right TExp: TypeExp "^" TypeExp
	> left TProduct: TypeExp tl TypeExp tr
	> left TDiv: TypeExp "/" TypeExp
	> right TFun: TypeExp "-\>" TypeExp  
	;

syntax Bool
	= lex "true" 
	| lex "false" 
	;

syntax Integer
	= lex [+\-]?"0" 
	| lex [+\-]?[1-9] [0-9]* 
	# [0-9 A-Z a-z] 
	;
	
syntax TypedIdent = TypedIdent: TypeExp? typeExp Ident ident ;

syntax Ident
	= lex [A-Z a-z] [0-9 A-Z a-z]*
	- ReservedWords 
	# [0-9 A-Z a-z] 
	;

syntax Annotation =
	  Var: Ident
	| FSym: FSym
	| VSym: VSym
	| Number: Integer
	> Appl: FSym "(" {Annotation ","}* ")"
	> left Annotation leftOp "/" Annotation rightOp
	> left Annotation leftOp "^" Annotation rightOp
	| left Prod: Annotation left Annotation right
	> right Eq: Annotation leftOp "=" Annotation rightOp
	| non-assoc Neq: Annotation leftOp "!=" Annotation rightOp
	> right Not: "!" Annotation exp
	> right And: Annotation leftOp "/\\" Annotation rightOp
	> right Or: Annotation leftOp "\\/" Annotation rightOp
	> left ( DotOffset: Annotation "." Annotation
		   | ArrowOffset: Annotation "-\>" Annotation )
	> right Deref: "*" Annotation
	;

syntax FSym = lex [@] Ident ;

syntax VSym = lex [$] Ident ;

syntax Comment = lex "#" ![\n]* [\n] ;

syntax LAYOUT
	= lex Comment 
	| lex [\t-\n \r \ ] 
	;

layout LAYOUTLIST
	= LAYOUT* 
	# [\t-\n \r \ ] 
	# "#" 
	;

syntax ReservedWords =
	  "function"
	| "return"
	| "begin"
	| "false"
	| "while"
	| "write"
	| "call"
	| "cast"
	| "else"
	| "read"
	| "true"
	| "then"
	| "void"
	| "and"
	| "end"
	| "for"
	| "not"
	| "var"
	| "or"
	| "if"
	| "fi"
	| "do"
	| "od"
	| "to"
	| "precondition"
	| "pre"
	| "postcondition"
	| "post"
	| "modifies"
	| "mod"
	| "assert"
	| "assume"
	| "invariant"
	;
