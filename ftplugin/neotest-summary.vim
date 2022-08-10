if get(b:, 'did_ftplugin', v:false)
	finish
endif
let b:did_ftplugin = v:true

let s:save_cpo = &cpo
set cpo&vim

setlocal winfixwidth
setlocal nonumber
setlocal norelativenumber
setlocal nospell

let b:undo_ftplugin = 'setlocal wfh< nu< rnu< spell<'

let &cpo = s:save_cpo
unlet s:save_cpo
