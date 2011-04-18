@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::silf::ide::Outline

import lang::silf::syntax::SILF;
import ParseTree; // for loc annos
import IO;

data Node
	= outline(list[Node] nodes)
	| funDecl(list[Node] nodes)
	| varDecl()
	;	

anno str Node@label;
anno loc Node@\loc;

public Node outlineProgram(Program p) {
	if ((Program)`<Decl* decls> <FunDecl+ funDecls>` := p) {
		return outline([ outlineVar(v) | v <- decls ] + [ outlineFun(f) | f <- funDecls ])[@label="SILF"];
	}
}

public Node outlineVar(Decl d) {
	if ((Decl)`var <TypedIdent tid> ;` := d) {
		return varDecl()[@label="<tid>"];
	} else if ((Decl)`var <TypedIdent tid> [ <Integer n> ] ;` := d) {
		return varDecl()[@label="<tid>[<n>]"];	
	}
}

public Node outlineFun(FunDecl fd) {
	if ((FunDecl)`function <TypedIdent tid> ( void ) <PrePosts? _> begin <Decl* _> <Stmt+ _> end` := fd) {
		return funDecl([])[@label="<tid>(void)"];
	} else if ((FunDecl)`function <TypedIdent tid> ( <{TypedIdent ","}+ params> ) <PrePosts? _> begin <Decl* _> <Stmt+ _> end` := fd) {
		return funDecl([])[@label="<tid>(<params>)"];	
	} else if ((FunDecl)`function <TypedIdent tid> ( void ) <PrePosts? _> end` := fd) {
		return funDecl([])[@label="<tid>(void)"];
	} else if ((FunDecl)`function <TypedIdent tid> ( <{TypedIdent ","}+ params> ) <PrePosts? _> end` := fd) {
		return funDecl([])[@label="<tid>(<params>)"];	
	}
}