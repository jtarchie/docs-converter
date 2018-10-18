__version__ = '0.0.1'

from jinja2 import Environment, FileSystemLoader, lexer, nodes
from jinja2.ext import Extension
from mkdocs import plugins
import os
import re


'''
class CodeSnippetExtension(Extension):
    tags = {'code_snippet'}

    def parse(self, parser):
        lineno = next(parser.stream).lineno

        token     = parser.stream.expect(lexer.TOKEN_STRING)
        repo_name = nodes.Const(token.value)

        if self.environment.dependent_sections[repo_name]:
            token     = parser.stream.expect(lexer.TOKEN_STRING)
            code_name = nodes.Const(token.value)

            repo = self.environment.dependent_sections[repo_name]
            exclude_dirs = {".git"}
            regex = re.compile(r'code_snippet %s start (\w+)\n(.*)code_snippet %s end' % (code_name, code_name))

            for root, dirs, files in os.walk(os.path.join(os.getcwd(), repo['directory']), topdown=True):
                dirs[:] = [d for d in dirs if d not in exclude_dirs]

                for name in files:
                    path = os.path.join(root, name)
                    with open(path) as f:
                        matches = re.match(regex, f.read, re.MULTILINE)
                        # do something

        else:
            raise Exception('Dependent section "%s" not defined in mkdocs.yml' % (repo_name))

'''

class JinjaMkDocPlugin(plugins.BasePlugin):
    def on_page_markdown(self, markdown, page, config, files):
        env = Environment(loader=FileSystemLoader(config['docs_dir']))
        return env.from_string(markdown).render(config=config)
