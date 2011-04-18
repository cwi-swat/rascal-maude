@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::silf::maude::MaudeInterface

import IO;
import ParseTree;
import String;
import List;
import Message;
import util::integration::maude::RLSRunner;
import util::ResourceMarkers;

import lang::silf::syntax::SILF;
import lang::silf::maude::Maudeify;

data RLSResult = SILFAnalysisResult(bool foundErrors, set[Message] messages) ;

public void(Tree, loc) makeExecutor(loc maudeExec, loc silfSpec, str policy, str(str,list[str]) pre, RLSResult(str) post) {
	void exec(Tree pt, loc l) {
		str silfProgramText = maudeify(pt, true, policy);
		RLSRunner rlsRunner = RLSRun(silfSpec, pre, post);
		RLSResult res = runRLSTask(maudeExec, rlsRunner, silfProgramText);
		if (SILFAnalysisResult(true,msgs) := res) {
			addMessageMarkers(msgs);
		}
	}
	return exec;
}

public str preCheckSILF(str pgm, list[str] params) {
	return "red eval((<pgm>),nil) .\n";
}

public RLSResult postTCheckSILF(str res) {
	return processRLSResult(res, silfTCheckHandler);
}

public RLSResult postUCheckSILF(str res) {
	return processRLSResult(res, silfUCheckHandler);
}

RLSResult checkHandler(str info, str foundMsg) {
	bool errorsFound = /<foundMsg>/ := info;
	set[Message] errorMsgs = errorsFound ? createMessages(info) : { };
	return SILFAnalysisResult(errorsFound, errorMsgs);
}

RLSResult silfTCheckHandler(RLSPerf perf, str info) {
	return checkHandler(info, "Type checking found errors");
}

RLSResult silfUCheckHandler(RLSPerf perf, str info) {
	return checkHandler(info, "Unit type checking found errors");
}
