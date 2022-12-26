## Create Help file from loaded module

### Templates included for output. Modify as needed.

- HTML: out-html-template.ps1
- MARKDOWN: out-markdown-template.ps1
- MARKUP: out-confluence-markup-template.ps1

### Requirements:

- Module must be loaded in session
- Template file must exist in same folder as New-HelpFile.ps1

### Example:

`New-HelpFile.ps1 -moduleName MyModule -fileName MyModule-help.html`
