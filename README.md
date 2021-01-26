# CommandBox CFC to Markdown Docs

A CommandBox custom command to generate markdown documentation from your CFCs.

## Package Installation

You will need [CommandBox](https://www.ortussolutions.com/products/commandbox) installed to use this tool. If you're a [CFML developer not using CommandBox](#a-note-on-commandbox-for-new-developers), see my note on the bottom.

From within the terminal, simply run the following command to install the module.

```shell
box install commandbox-cfc-to-markdown-docs
```

Once the module is installed, it uses the command: `markdowndoc` or the alias `mdd`.

## What it does

Running the command `markdowndoc path/to/your/file.cfc` reads/analyzes the component metadata for your `file.cfc` and uses this to generate a markdown documentation file. It ignores properties and private methods.

The documentation is sourced from your javadoc style comments. In particular, `@hint` for the primary documentation, and `@doc` for a reference to external documentation. You can provide additional hints for your function arguments using `@arguementName` comments.

### Example

You can see an example of how this command can be used on the [`eversigncfc` repository](https://github.com/mjclemente/eversigncfc). From the root of that project, the following command was used to generate the documentation: `mdd path=eversign.cfc directory=docs/`

### A Note

This command was built to solve a problem I repeatedly encountered when working on documentation for API wrappers. Which is to say, it's designed to meet my needs. I realize that, currently, the flow/output may not be a good fit for other projects. I am very open to revising/restructing/expanding the command to better meet the needs of other developers, if there is interest in using it.

### Options

There are a handful of options for configuring the output.

#### `path`

Path to the CFC that you want to generate documentation for (*required*).

#### `directory`

Destination directory to in which to generate the markdown file (default CWD)

#### `force`

Overwrite an existing markdown file if present (default false)

#### `template`

Template that controls how the markdown docs for each function are displayed.

#### `layout`

Template that determines the layout of the markdown document.

#### `methodOrder`

Determines the order that functions are displayed in the generated output. The options are `positional` or `alphabetical`. The default is `positional`, which orders functions in the same order they appear in the CFC.

#### `generateFile`

Generate a markdown file with the documentation (default true). If false, the generated markdown is output to the terminal.

___

### A Note on CommandBox for New Developers

If you're a ColdFusion developer and you're not already using CommandBox... you really, really should be. As I've said before, it's hard to explain how helpful it is. If have questions about CommandBox, feel free to ask me, or, for more professional help, ask [Brad Wood](https://twitter.com/bdw429s). [↩](#package-installation)
