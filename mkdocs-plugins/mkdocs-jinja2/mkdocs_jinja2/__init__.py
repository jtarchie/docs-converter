__version__ = '0.0.1'

from jinja2 import Environment, FileSystemLoader, lexer, nodes
from jinja2.ext import Extension
from mkdocs import plugins
import os
import re
import sys


class CodeSnippetExtension(Extension):
    tags = {'code_snippet'}

    class CouldNotFindSnippet(Exception):
        pass

    def __init__(self, environment):
        super(CodeSnippetExtension, self).__init__(environment)
        environment.extend(dependent_sections=[])

    def parse(self, parser):
        lineno = next(parser.stream).lineno
        args = [parser.parse_expression()]
        parser.stream.skip_if('comma')
        args.append(parser.parse_expression())
        return nodes.Output([
            self.call_method('_code_snippet', args)
            ], lineno=lineno)


    def _code_snippet(self, repo_name, code_name):
        if self.environment.dependent_sections[repo_name]:
            repo = self.environment.dependent_sections[repo_name]
            exclude_dirs = {'.git'}
            regex = re.compile(r'.*code_snippet %s start (\w+)\n(.*)\n.*?code_snippet %s end' % (re.escape(code_name), re.escape(code_name)), re.MULTILINE | re.DOTALL)

            for root, dirs, files in os.walk(repo, topdown=True):
                dirs[:] = [d for d in dirs if d not in exclude_dirs]

                for name in files:
                    path = os.path.join(root, name)
                    f = open(path, 'r')
                    matches = regex.search(f.read())
                    if matches is not None:
                        return("""```%s\n%s\n```""" % (matches.group(1), matches.group(2)))
            sys.stderr.write("could not find code snippet %s under repo %s\n" % (code_name, repo_name))
            raise CouldNotFindSnippet
        else:
            raise Exception('Dependent section "%s" not defined in mkdocs.yml' % (repo_name))


class JinjaMkDocPlugin(plugins.BasePlugin):
    def on_page_markdown(self, markdown, page, config, files):
        env = Environment(
            loader=FileSystemLoader(config['docs_dir']),
            extensions=[CodeSnippetExtension],
            )
        env.dependent_sections=config.get('dependent_sections', [])
        return env.from_string(markdown).render(config=config)
