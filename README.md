# Usage

This converts documents in the `bookbinder` format to an example `mkdocs` format.

```bash
brew install ruby python3
pip3 install mkdocs
bundle install
```

It uses mkdocs and jinja2 for the HTML and templating.
Purposely removing ERB from the equation.

## Conversions made

* `<%= yield_for_code_snippet from: 'org/repo', at: 'snippet-name' %>` becomes `{% code_snippet 'org/repo', 'snippet-name' %}` (a custom mkdocs plugin)
* `<%= partial 'some_file' %>` becomes `{% include 'some_file' %}` (built into jinja2)
  the corresponding `include` will do a look up of a `_some_file` and then `some_file` to support Rails style partials
* all header anchors (`<a id="name"></a>`) are remove, as mkdocs manages those automatically
* all `*.html.md.erb` have their extension changed to `.md` as required by mkdocs
* all links with a relative `.html` are converted to `.md` as required by mkdocs
* all `<% mermaid_diagram do %><% end %>` are converted to `<div class="mermaid"></div>` and the `mermaid.js` is include an external CDN provider
* all `<p class="note|warning"></p>` (ie alerts) are converted to `!!! note|warning` notation (used in the Python markdown library)
* icon and favicon set to Pivotal logo
* side nav converted to mkdocs `nav` format
* font defaults to `Source Sans Pro`
* color scheme is `teal` (as provided by mkdocs-material)

## Known issues

* side nav does not handle deeply nested navigation
* some types of alert types may not be supported
* `code_snippet` will error when snippet is not defined
* `include` will error when partial is not defined
* does not read `config.yml` at all

# Tests

The tests cover both unit and integration.
They can be a bit slow.
They are testing Python via Ruby, yes really.

## Locally

```bash
rspec
```

## Docker image

```bash
docker build . -t docs-converter
docker run -it --rm -v $PWD:/test -w /test docs-converter rspec 
```