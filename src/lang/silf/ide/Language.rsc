@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::silf::ide::Language

import List;
import ParseTree;
import IO;
import util::IDE;
import util::ResourceMarkers;

import lang::silf::syntax::SILF;
import lang::silf::maude::MaudeInterface;

private loc maudeExec = |file:///Users/mhills/Development/maude/maude|;
private loc silfTCheckSpec = |file:///Users/mhills/Projects/SILF/SILF-tcheck.maude|;
private loc silfUCheckSpec = |file:///Users/mhills/Projects/SILF/SILF-ucheck-wann.maude|;

public void registerSILF() {
  	registerLanguage("SILF", "silf", Tree (str x, loc l) {
    	return parse(#lang::silf::syntax::SILF::Program, x, l);
  	});
  
	registerContributions("SILF", SILF_CONTRIBS);
}   

public void clearMarkers(Tree pt, loc l) {
	removeMessageMarkers(pt@\loc);
	return;
}

public set[Contribution] SILF_CONTRIBS = {
	popup(
		menu("SILF",[
    		action("Type Check", makeExecutor(maudeExec, silfTCheckSpec, "TYPES", preCheckSILF, postTCheckSILF)),
    		action("Unit Check", makeExecutor(maudeExec, silfUCheckSpec, "UNITS", preCheckSILF, postUCheckSILF)),
    		action("Clear Markers", clearMarkers) 
	    ])
  	)
};

