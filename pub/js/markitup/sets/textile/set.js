// -------------------------------------------------------------------
// markItUp!
// -------------------------------------------------------------------
// Copyright (C) 2008 Jay Salvat
// http://markitup.jaysalvat.com/
// -------------------------------------------------------------------
// Textile tags example
// http://en.wikipedia.org/wiki/Textile_(markup_language)
// http://www.textism.com/
// -------------------------------------------------------------------
// Feel free to add more tags
// -------------------------------------------------------------------
MarkItUpTextileSettings = {
	previewParserPath:	'', // path to your Textile parser
	onShiftEnter:		{keepDefault:false, replaceWith:'\n\n'},
	markupSet: [
		{name:'Heading 1', className:'h1', key:'1', openWith:'h1(!(([![Class]!]))!). ', placeHolder:'Your title here...' },
		{name:'Heading 2', className:'h2', key:'2', openWith:'h2(!(([![Class]!]))!). ', placeHolder:'Your title here...' },
		{name:'Heading 3', className:'h3', key:'3', openWith:'h3(!(([![Class]!]))!). ', placeHolder:'Your title here...' },
		{name:'Heading 4', className:'h4', key:'4', openWith:'h4(!(([![Class]!]))!). ', placeHolder:'Your title here...' },
		{name:'Heading 5', className:'h5', key:'5', openWith:'h5(!(([![Class]!]))!). ', placeHolder:'Your title here...' },
		{name:'Heading 6', className:'h6', key:'6', openWith:'h6(!(([![Class]!]))!). ', placeHolder:'Your title here...' },
		{name:'Paragraph', className:'paragraph', key:'P', openWith:'p(!(([![Class]!]))!). '},
		{separator:'---------------' },
		{name:'Bold', className:'bold', key:'B', closeWith:'*', openWith:'*'},
		{name:'Italic', className:'italic', key:'I', closeWith:'_', openWith:'_'},
		{name:'Stroke through', className:'stroke', key:'S', closeWith:'-', openWith:'-'},
		{separator:'---------------' },
		{name:'Bulleted list', className:'list_bullet', openWith:'(!(* |!|*)!)'},
		{name:'Numeric list', className:'list_numeric', openWith:'(!(# |!|#)!)'}, 
		{separator:'---------------' },
		{name:'Picture', className:'picture', replaceWith:'![![Source:!:http://]!]([![Alternative text]!])!'}, 
		{name:'Link', className:'link', openWith:'"', closeWith:'([![Title]!])":[![Link:!:http://]!]', placeHolder:'Your text to link here...' },
		{separator:'---------------' },
		{name:'Quotes', className:'quotes', openWith:'bq(!(([![Class]!]))!). '},
		{name:'Code', className:'code', openWith:'@', closeWith:'@'},
		{separator:'---------------' },
		{name:'Preview', call:'preview', className:'preview'}
	]
}
