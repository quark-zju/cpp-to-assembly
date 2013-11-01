fs = require('fs')
util = require('util');

exec = require('child_process').exec;
decodeCode=(asm,code)->
	#split input
	asm_lines = asm.split("\n")
	code_lines = code.split("\n")
	labels={}
	label_data={}
	currentlabel=null
	files=[]
	readmode=false
	currentline=0
	for asline in asm_lines
		
		linedata=/^[ ]+[0-9]+ (.*)/m.exec(asline)
		if linedata?
			#parse file start markers '.file "filename"'
			file=/^[ \t]*\.file[ \t]+([0-9]*)?[ ]?\"([^"]*)"/m.exec(linedata[1])
			if file?
				fid=if file[1] then file[1] else 0

				fname=file[2]
				files[parseInt(fid)]= /(^c2a|\/c2a)/.test(fname)
				readmode=files[parseInt(fid)]
				currentline=0
			else
				#scan for labels
				label=/\.([^ :]*):/m.exec(linedata[1])
				if label?
					if labels[label[1]]?
						labels[label[1]]++
					else
						if currentlabel? and currentlabel < 1
							delete label_data[currentlabel]

						labels[label[1]]= 0 
						label_data[label[1]]= {0:linedata[1]+"\n"} 
						currentlabel=label[1];
				else if currentlabel?
					#parse .loc
					loc= /^[ \t]*.loc ([0-9]+) ([0-9]+)/.exec(linedata[1])
					if loc?
						readmode=files[parseInt(loc[1])]
						currentline=if readmode then parseInt(loc[2]) else 0
					else 
						if not label_data[currentlabel][currentline]?
							label_data[currentlabel][currentline]=""
						label_data[currentlabel][currentline]+= linedata[1]+"\n"
						if readmode
							labels[currentlabel]++
	if currentlabel? and currentlabel < 1
		delete label_data[currentlabel]
	{code:code_lines,asm:label_data}


exports.error404 = (req, res)->
  res.status(404)
  res.render('404', { title: 'C/C++ to Assembly' });

exports.indexpost = (req, res)->
	optimize=if req.body.optimize? then "-O2" else ""
	lang=if req.body.language=="c" then "c" else "cpp"
	#Generate file name
	fileid=Math.floor(Math.random()*1000000001);
	compiler=(if lang=='c' then 'gcc' else 'g++')
	opt=(if lang=='c' then '-std=c99' else '-std=c++0x')
	src="/tmp/c2asm/c2a#{fileid}.#{lang}"
	obj="c2a#{fileid}.o"
	
	#Write input to file
	fs.writeFile src, req.body.ccode, (err)->
		if err
			res.json({error:"Server Error"});
		else
			# Execute GCC
			#console.log("c-preload/compiler-wrapper #{compiler} #{opt} -c #{optimize} -Wa,-ald  -g #{src}")
			exec "c-preload/compiler-wrapper #{compiler} #{opt} -c #{optimize} -Wa,-ald  -g #{src}", {timeout:2000,maxBuffer: 1024 * 1024*4}, (error, stdout, stderr)->
					if error?
						#Send error message to the client
						msg = error.toString().replace(new RegExp(src, 'g'), "_.#{lang}")
						if msg.length > 1024
							msg = msg.substr(0, 1024) + ' ...'
						res.json({error:msg})
					else
						#Parse standart output
						#console.log stdout
						blocks=decodeCode(stdout,req.body.ccode)
						#Send result as json to the clien 
						res.json(blocks);
					#Clean up
					fs.unlink(src)
					fs.unlink(obj)
