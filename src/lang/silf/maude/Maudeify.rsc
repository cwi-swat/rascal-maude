@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::silf::maude::Maudeify

import List;
import Set;
import IO;
import String;
import ParseTree;

import lang::silf::syntax::SILF;

public value noMatch = 3;

public str maudeify(Program p, bool addLocs, str policy) {

	str maudeify(list[&T] l, str unit) {
		if (size(l) == 0) {
			return unit;
		} else {
			return "_`,_(<maudeify(head(l))>,<maudeify(tail(l),unit)>)";
		} 
	}
	
	str maudeifyNoSep(list[&T] l, str unit) {
		if (size(l) == 0) {
			return unit;
		} else {
			return "__(<maudeify(head(l))>,<maudeifyNoSep(tail(l),unit)>)";
		} 
	}

	str maudeify(set[&T] s, str unit) {
		if (size(s) == 0) {
			return unit;
		} else {
			si = getOneFrom(s);
			return "__(<maudeify(si)>,<maudeify(s-si,unit)>)";
		} 
	}

	str showDecls(list[&T] l) {
		return maudeifyNoSep(l, "noDecls");
	}
	
	str showFunDecls(set[&T] s) {
		return maudeify(s, "nil");
	}
	
	str showPrePosts(list[&T] l) {
		return maudeifyNoSep(l, "noAnns");
	}
	
	str showStatements(list[&T] l) {
		return maudeifyNoSep(l, "nil");
	}
	
	str showExps(list[&T] l) {
		return maudeify(l, "nil");
	}
	
	str showTypedIdents(list[&T] l) {
		return maudeify(l, "nil");
	}
	
	str showIdents(list[&T] l) {
		return maudeify(l, "nil");
	}

	str showInvariants(list[&T] l) {
		return maudeifyNoSep(l, "noInvs");
	}

	str located(Tree t, str locator, str astNode) {
		str makeMaudeLoc(loc l) {
			return "sl(\"<l.uri>\",<l.offset>,<l.length>,<l.begin[0]>,<l.begin[1]>,<l.end[0]>,<l.end[1]>)";
		}
		
		if (addLocs)
			return "located<locator>(<astNode>,<makeMaudeLoc(t@\loc)>)";
		else
			return astNode;
	}
	
	str maudeify(Decl d) {
		switch(d) {
			case (Decl)`var <TypedIdent id> ;` :
				return located(d,"Decl","var_(<maudeify(id)>)");
			case (Decl)`var <TypedIdent id> [ <Integer sz> ] ;` :
				return located(d,"Decl","var_`[_`](<maudeify(id)>,<located(sz,"Integer","#(<sz>)")>)");
		}
	}

	str maudeify(FunDecl fd) {
		switch(fd) {
			case (FunDecl)`function <TypedIdent id> ( void ) <PrePost* pp> begin <Decl* decls> <Stmt+ stmts> end` :
				return located(fd,"FunDecl","function_`(_`)_begin__end(<maudeify(id)>,nil,<showPrePosts([ppi|ppi<-pp])>,<showDecls([di|di<-decls])>,<showStatements([sti|sti<-stmts])>)");
			case (FunDecl)`function <TypedIdent id> ( <{TypedIdent ","}+ params> ) <PrePost* pp> begin <Decl* decls> <Stmt+ stmts> end` :
				return located(fd,"FunDecl","function_`(_`)_begin__end(<maudeify(id)>,<showTypedIdents([tii|tii<-params])>,<showPrePosts([ppi|ppi<-pp])>,<showDecls([di|di<-decls])>,<showStatements([sti|sti<-stmts])>)");
			case (FunDecl)`function <TypedIdent id> ( void ) <PrePost* pp> end` :
				return located(fd,"FunDecl","function_`(_`)_begin__end(<maudeify(id)>,nil,<showPrePosts([ppi|ppi<-pp])>,noDecls,nil)");
			case (FunDecl)`function <TypedIdent id> ( <{TypedIdent ","}+ params> ) <PrePost* pp> end` :
				return located(fd,"FunDecl","function_`(_`)_begin__end(<maudeify(id)>,<showTypedIdents([tii|tii<-params])>,<showPrePosts([ppi|ppi<-pp])>,noDecls,nil)");
		}
	}

	str maudeify(Stmt s) {
		switch(s) {
			case (Stmt)`<Ident id> := <Exp e> ;` : 
				return located(s,"Stmt","_:=_(<maudeify(id)>,<maudeify(e)>)");
			case (Stmt)`<Ident id> [ <Exp e> ] := <Exp er> ;` : 
				return located(s,"Stmt","_`[_`]:=_(<maudeify(id)>,<maudeify(e)>,<maudeify(er)>)");
			case (Stmt)`if <Exp e> then <Decl* dt> <Stmt+ st> fi` : 
				return located(s,"Stmt","if_then__fi(<maudeify(e)>,<showDecls([dti|dti<-dt])>,<showStatements([sti|sti<-st])>)");
			case (Stmt)`if <Exp e> then <Decl* dt> <Stmt+ st> else <Decl* df> <Stmt+ sf> fi` :
				return located(s,"Stmt","if_then__else__fi(<maudeify(e)>,<showDecls([dti|dti<-dt])>,<showStatements([sti|sti<-st])>,<showDecls([dfi|dfi<-df])>,<showStatements([sfi|sfi<-sf])>)");
			case (Stmt)`for <Ident id> := <Exp sr> to <Exp er> <Invariant* invs> do <Decl* ds> <Stmt+ ss> od` :
				return located(s,"Stmt","for_:=_to__do__od(<maudeify(id)>,<maudeify(sr)>,<maudeify(er)>,<showInvariants([invi|invi<-invs])>,<showDecls([dsi|dsi<-ds])>,<showStatements([ssi|ssi<-ss])>)");
			case (Stmt)`while <Exp exp> <Invariant* invs> do <Decl* ds> <Stmt+ ss> od` :
				return located(s,"Stmt","while__do__od(<maudeify(exp)>,<showInvariants([invi|invi<-invs])>,<showDecls([dsi|dsi<-ds])>,<showStatements([ssi|ssi<-ss])>)");
			case (Stmt)`call <Ident id> ( <{Exp ","}* ps> ) ;` :
				if (size([p | p <- ps] == 0))
					return located(s,"Stmt","call_`(`)(<maudeify(id)>)");
				else
					return located(s,"Stmt","call_`(_`)(<maudeify(id)>,<showExps([psi|psi<-ps])>)");
			case (Stmt)`return <Exp e> ;` :
				return located(s,"Stmt","return_(<maudeify(e)>)");
			case (Stmt)`write <Exp e> ;` :
				return located(s,"Stmt","write_(<maudeify(e)>)");
			case (Stmt)`assume(<Ident id>) : <Annotation af> ;` :
				return located(s,"Stmt","assume(<maudeify(id)>,<maudeify(af)>)");
			case (Stmt)`assume : <Annotation af> ;` :
				return located(s,"Stmt","assume(n(\'ALL),<maudeify(af)>)"); 
			case (Stmt)`assert ( <Ident id> ) : <Annotation af> ;` :
				return located(s,"Stmt","assert(<maudeify(id)>, <maudeify(af)>)");
			case (Stmt)`assert : <Annotation af> ;` :
				return located(s,"Stmt","assume(n(\'ALL),<maudeify(af)>)");
		}
	}
		
	str maudeify(Exp exp) {
		switch(exp) {
			case (Exp)`cast ( <Exp ef> ) to ( <TypeExp et> )` :
				return located(exp,"Exp","cast_to`(_`)(<maudeify(ef)>,<maudeify(et)>)");
			case (Exp)`<Ident id> ( < {Exp ","}* exps > )` :
				if (size([e | e <- exps]) > 0)
					return located(exp,"Exp","_`(_`)(<maudeify(id)>,<showExps([expi|expi<-exps])>)");
				else
					return located(exp,"Exp","_`(`)(<maudeify(id)>)");
			case (Exp)`( <Exp e> )` : 
				return maudeify(e);
			case (Exp)`read` :
				return located(exp,"Exp","read");
			case (Exp)`<Integer n>` :
				return located(exp,"Exp","#(<n>)");
			case (Exp)`true` :
				return located(exp,"Exp","b(true)");
			case (Exp)`false` :
				return located(exp,"Exp","b(false)");
			case (Exp)`<Ident id> [ <Exp e> ]` :
				return located(exp,"Exp","_`[_`](<maudeify(id)>,<maudeify(e)>)");
			case (Exp)`<Ident id>` :
				return located(exp,"Exp","<maudeify(id)>");
			case (Exp)`- <Exp e>` :
				return located(exp,"Exp","-_(<maudeify(e)>)");
			case (Exp)`<Exp el> * <Exp er>` :
				return located(exp,"Exp","_*_(<maudeify(el)>,<maudeify(er)>)");			
			case (Exp)`<Exp el> / <Exp er>` :
				return located(exp,"Exp","_/_(<maudeify(el)>,<maudeify(er)>)");			
			case (Exp)`<Exp el> % <Exp er>` :
				return located(exp,"Exp","_%_(<maudeify(el)>,<maudeify(er)>)");			
			case (Exp)`<Exp el> + <Exp er>` :
				return located(exp,"Exp","_+_(<maudeify(el)>,<maudeify(er)>)");			
			case (Exp)`<Exp el> - <Exp er>` :
				return located(exp,"Exp","_-_(<maudeify(el)>,<maudeify(er)>)");			
			case (Exp)`<Exp el> <= <Exp er>` :
				return located(exp,"Exp","_\<=_(<maudeify(el)>,<maudeify(er)>)");			
			case (Exp)`<Exp el> >= <Exp er>` :
				return located(exp,"Exp","_\>=_(<maudeify(el)>,<maudeify(er)>)");			
			case (Exp)`<Exp el> < <Exp er>` :
				return located(exp,"Exp","_\<_(<maudeify(el)>,<maudeify(er)>)");			
			case (Exp)`<Exp el> > <Exp er>` :
				return located(exp,"Exp","_\>_(<maudeify(el)>,<maudeify(er)>)");			
			case (Exp)`<Exp el> = <Exp er>` :
				return located(exp,"Exp","_=_(<maudeify(el)>,<maudeify(er)>)");			
			case (Exp)`<Exp el> != <Exp er>` :
				return located(exp,"Exp","_!=_(<maudeify(el)>,<maudeify(er)>)");			
			case (Exp)`not <Exp e>` :
				return located(exp,"Exp","not_(<maudeify(e)>)");			
			case (Exp)`<Exp el> and <Exp er>` :
				return located(exp,"Exp","_and_(<maudeify(el)>,<maudeify(er)>)");			
			case (Exp)`<Exp el> or <Exp er>` :
				return located(exp,"Exp","_or_(<maudeify(el)>,<maudeify(er)>)");			
		}
	}
	
	str maudeify(Ident i) {
		return "n(\'<i>)";
	}

	str maudeify(PrePost pp) {
		switch(pp) {
			case (PrePost)`precondition ( <Ident id> ) : <Annotation af> ;` :
				return "pre(<maudeify(id)>,<maudeify(af)>)";
			case (PrePost)`precondition : <Annotation af> ;` :
				return "pre(n(\'ALL),<maudeify(af)>)";
			case (PrePost)`pre ( <Ident id> ) : <Annotation af> ;` :
				return "pre(<maudeify(id)>,<maudeify(af)>)";
			case (PrePost)`pre : <Annotation af> ;` :
				return "pre(n(\'ALL),<maudeify(af)>)";
			case (PrePost)`postcondition ( <Ident id> ) : <Annotation af> ;` :
				return "post(<maudeify(id)>,<maudeify(af)>)";
			case (PrePost)`postcondition : <Annotation af> ;` :
				return "post(n(\'ALL),<maudeify(af)>)";
			case (PrePost)`post ( <Ident id> ) : <Annotation af> ;` :
				return "post(<maudeify(id)>,<maudeify(af)>)";
			case (PrePost)`post : <Annotation af> ;` :
				return "post(n(\'ALL),<maudeify(af)>)";
			case (PrePost)`modifies ( <Ident id> ) : <{Ident ","}+ ids> ;` :
				return "mod(<maudeify(id)>,<showIdents([idi|idi<-ids])>)";
			case (PrePost)`modifies : <{Ident ","}+ ids> ;` :
				return "mod(n(\'ALL),<showIdents([idi|idi<-ids])>)";
			case (PrePost)`mod ( <Ident id> ) : <{Ident ","}+ ids> ;` :
				return "mod(<maudeify(id)>,<showIdents([idi|idi<-ids])>)";
			case (PrePost)`mod : <{Ident ","}+ ids> ;` :
				return "mod(n(\'ALL),<showIdents([idi|idi<-ids])>)";
			default: { noMatch = pp; throw "No matching case for <pp>"; }
		}
	}
	
	str maudeify(Invariant inv) {
		switch(inv) {
			case (Invariant)`invariant ( <Ident id> ) : <Annotation af> ;` :
				return "invariant(<maudeify(id)>,<maudeify(af)>)";
			case (Invariant)`invariant : <Annotation af> ;` :
				return "invariant(n(\'ALL),<maudeify(af)>)";		
		}
	}
	
	str maudeify(Annotation ae) {
		switch(ae) {
			case (Annotation)`<Ident v>` : return "n(\'<v>)";
			case (Annotation)`<FSym fs>` : return "<fs>";
			case (Annotation)`<VSym vs>` : return "$<substring("<vs>",1)>";
			case (Annotation)`<Integer n>` : return "<n>";
			case (Annotation)`<Annotation l> / <Annotation r>` : return "_/_(<maudeify(l)>,<maudeify(r)>)";
			case (Annotation)`<Annotation l> ^ <Annotation r>` : return "_^_(<maudeify(l)>,<maudeify(r)>)";
			case (Annotation)`<FSym fs> ( < {Annotation ","}* ps > )` : return "<fs>(<intercalate(",",[maudeify(p)|p<-ps])>)";
			case (Annotation)`<Annotation l> <Annotation r>` : return "__(<maudeify(l)>,<maudeify(r)>)";
			case (Annotation)`<Annotation l> = <Annotation r>` : return "_=_(<maudeify(l)>,<maudeify(r)>)";
			case (Annotation)`<Annotation l> != <Annotation r>` : return "_!=_(<maudeify(l)>,<maudeify(r)>)";
			case (Annotation)`! <Annotation l>` : return "!_(<maudeify(l)>)";
			case (Annotation)`<Annotation l> /\ <Annotation r>` : return "_/\\_(<maudeify(l)>,<maudeify(r)>)";
			case (Annotation)`<Annotation l> \/ <Annotation r>` : return "_\\/_(<maudeify(l)>,<maudeify(r)>)";
			case (Annotation)`<Annotation l> . <Annotation r>` : return "_._(<maudeify(l)>,<maudeify(r)>)";
			case (Annotation)`<Annotation l> -> <Annotation r>` : return "_-\>_(<maudeify(l)>,<maudeify(r)>)";
			case (Annotation)`* <Annotation l>` : return "*_(<maudeify(l)>)";
		}
	}
	
	str maudeify(TypedIdent ti) {
		switch(ti) {
			case (TypedIdent)`<TypeExp te> <Ident id>` :
				return "__(<maudeify(te)>,<maudeify(id)>)";
			case (TypedIdent)`<Ident id>` :
				return "__(noType,<maudeify(id)>)";
		}
	}
	
	str maudeify(TypeExp te) {
		switch(te) {
			case (TypeExp)`<TypeIdent ti>` :
				return maudeify(ti);
			case (TypeExp)`<Integer n>` :
				return "#(<n>)";
			case (TypeExp)`( <TypeExp te2> )` :
				return maudeify(te2);
			case (TypeExp)`<TypeIdent ti> ( <TypeExp te2> )` :
				return "_`(_`)(<maudeify(ti)>,<maudeify(te2)>)";
			case (TypeExp)`<TypeExp te1> ^ <TypeExp te2>` :
				return "_^_(<maudeify(te1)>,<maudeify(te2)>)";
			case (TypeExp)`<TypeExp te1> <TypeExp te2>` :
				return "__(<maudeify(te1)>,<maudeify(te2)>)";
			case (TypeExp)`<TypeExp te1> / <TypeExp te2>` :
				return "_/_(<maudeify(te1)>,<maudeify(te2)>)";
			case (TypeExp)`<TypeExp te1> -> <TypeExp te2>` :
				return "_-\>_(<maudeify(te1)>,<maudeify(te2)>)";
		}	
	}
	
	str maudeify(TypeIdent ti) {
		switch(ti) {
			case (TypeIdent)`<TypeIdentL s>` :
				return "$(\'<substring("<s>",1)>)";
			case (TypeIdent)`<TypeVarL s>` :
				return "$$(\'<substring("<s>",1)>)";
		}
	}
	
	if ((Program)`<Decl* decls> <FunDecl+ funDecls>` := p)
		return located(p,"Pgm","__(<showDecls([d|d<-decls])>,<showFunDecls({f|f<-funDecls})>)");
}


