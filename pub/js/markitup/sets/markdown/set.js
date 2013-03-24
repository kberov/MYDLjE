// -------------------------------------------------------------------
// markItUp!
// -------------------------------------------------------------------
// Copyright (C) 2008 Jay Salvat
// http://markitup.jaysalvat.com/
// -------------------------------------------------------------------
// MarkDown tags example
// http://en.wikipedia.org/wiki/Markdown
// http://daringfireball.net/projects/markdown/
// -------------------------------------------------------------------
// Feel free to add more tags
// -------------------------------------------------------------------
MarkItUpMarkdownSettings = {
	previewParserPath:	'',
	onShiftEnter:		{keepDefault:false, openWith:'\n\n'},
	markupSet: [
		{name:'First Level Heading', className:'h1', key:'1', placeHolder:'Your title here...', closeWith:function(markItUp) { return miu.markdownTitle(markItUp, '=') } },
		{name:'Second Level Heading', className:'h2', key:'2', placeHolder:'Your title here...', closeWith:function(markItUp) { return miu.markdownTitle(markItUp, '-') } },
		{name:'Heading 3', key:'3', className:'h3', openWith:'### ', placeHolder:'Your title here...' },
		{name:'Heading 4', key:'4', className:'h4', openWith:'#### ', placeHolder:'Your title here...' },
		{name:'Heading 5', key:'5', className:'h5', openWith:'##### ', placeHolder:'Your title here...' },
		{name:'Heading 6', key:'6', className:'h6', openWith:'###### ', placeHolder:'Your title here...' },
		{separator:'---------------' },		
		{name:'Bold', key:'B', className:'bold', openWith:'**', closeWith:'**'},
		{name:'Italic', key:'I', className:'italic', openWith:'_', closeWith:'_'},
		{separator:'---------------' },
		{name:'Bulleted List', className:'list_bullet', openWith:'- ' },
		{name:'Numeric List', className:'list_numeric', openWith:function(markItUp) {
			return markItUp.line+'. ';
		}},
		{separator:'---------------' },
		{name:'Picture', key:'P', className:'picture', replaceWith:'![[![Alternative text]!]]([![Url:!:http://]!] "[![Title]!]")'},
		{name:'Link', key:'L', className:'link', openWith:'[', closeWith:']([![Url:!:http://]!] "[![Title]!]")', placeHolder:'Your text to link here...' },
		{separator:'---------------'},	
		{name:'Quotes', className:'quotes', openWith:'> '},
		{name:'Code Block / Code', className:'code', openWith:'(!(\t|!|`)!)', closeWith:'(!(`)!)'},
		{separator:'---------------'},
		{name:'Preview', call:'preview', className:"Markdown preview"}
	]
}

// mIu nameSpace to avoid conflict.
miu = {
	markdownTitle: function(markItUp, char) {
		heading = '';
		n = $.trim(markItUp.selection||markItUp.placeHolder).length;
		for(i = 0; i < n; i++) {
			heading += char;
		}
		return '\n'+heading;
	}
}
