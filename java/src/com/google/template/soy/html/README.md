# Knowledge of HTML in Soy

The package provides knowledge of the HTML structure of a Soy template to later 
passes.

## Background

Soy itself is a very flexible language, and while HTML is a very common use 
case, the language itself is not restricted to templating HTML. As a result, 
TemplateParser in soyparse does not capture any information about HTML present 
in templates.

Some passes may require knowledge of how HTML in templates is structured in 
order to perform transformations or to produce generated code. The Soy tree 
generated by the parser treats all text that is not in a Soy tag as general raw 
text, which works well for some types of code generation, such as string 
concatenation, but not others.

## Overview

Given a template:

~~~
{template .someName}
  {@param someCondition : boolean}
  {@param class : text}

  <div class="${class}">
    Hello
    {if $someCondition}
        <strong>world</strong>
    {/if}
  </div>
{/template}
~~~

After parsing, the corresponding Soy tree looks something like:

~~~
TemplateNode
    RawTextNode '<div class="'
    PrintNode
    RawTextNode '">Hello'
    IfNode
        IfCondNode
            RawTextNode '<strong>world</strong>'
    RawTextNode '</div>'
~~~

Instead of dealing with RawTextNodes, later passes might like to know the 
following information:

- Where are the open tags?
- What attributes does an open tag contain?
- Where are the close tags?
- If a print node is present in HTML, is it an attribute value or is it a text 
  node?
- Will the template produce valid HTML?

To provide this information, `HtmlTransformVisitor` will transform the tree 
into the following structure:

~~~
TemplateNode
    HTMLOpenTagStartNode 'div'
    HTMLAttributeNode 'class'
        HtmlPrintNode
    HTMLOpenTagEndNode
    HtmlPrintNode 'Hello'
    IfNode
        IfCondNode
            HtmlOpenTagStartNode 'strong'
            HtmlOpenTagEndNode
            HtmlPrintNode 'world'
            HtmlCloseTagNode 'strong'
    HtmlCloseTagNode 'div'
~~~

## Transformation

The initial transformation, performed by `HtmlTransformVisitor` replaces the 
`RawTextNode`s found in the tree with HTML nodes corresponding to the different 
pieces of HTML. They are:

- `HtmlOpenTagStartNode` - the start of a tag, e.g. `<div`
- `HtmlOpenTagEndNode` - the end of a tag, i.e. `>`
- `HtmlCloseTagNode`  - a closing tag, e.g. `</div>`
- `HtmlAttributeNode` - an attribute, has one or more node(s) representing the 
attribute's value
- `HtmlPrintNode` - a print node that appears in the middle of HTML

In order to keep the transformation logic simple, the `RawTextNode`s present in 
the original tree are simply translated to one or more node(s) capturing the 
HTML structure with minimal restructuring of the tree. A later pass may use 
this information to move nodes around as necessary.

Note that the Soy tree might not be able to be structured the same as the HTML 
hierachy in all situtations. Take for example, the following Soy template:

~~~
{template .someTemplate}
  {if $condition}
    <a href="...">
  {/if}
  
  <div>...</div>
  
  {if $condition}
    </a>
  {/if}
{/template}
~~~

Depending on the condition, the div may or may not be a child of an anchor tag.

`HtmlTransformVisitor` transforms any `RawTextNode`s that it finds that are 
present in an HTML context (i.e. inside a `{template}` body, a `{let}` or 
`{param}` of `kind="html"` or `kind="attributes"`). All other `RawTextNode`s 
are left untransformed, for example those found in a `{let 
kind="text"}...{/let}` statement.

## Visiting the modified tree

The existing code generators and visitors do not deal with HTML nodes. In order 
to visit a tree that contains HTML nodes, you should extend either 
`AbstractHtmlSoyNodeVisitor` or `AbstractReturningHtmlSoyNodeVisitor`, 
depending on whether or not the visit method should return a value.
