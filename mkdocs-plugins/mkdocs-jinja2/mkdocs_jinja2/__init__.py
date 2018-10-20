__version__ = '0.0.1'

from jinja2 import Environment, FileSystemLoader, lexer, nodes, TemplateRuntimeError
from jinja2.ext import Extension
from mkdocs import plugins, config
import os
import re
import sys
import subprocess


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
            self.call_method('_code_snippet', args, lineno=lineno)
            ], lineno=lineno)


    def _code_snippet(self, repo_name, code_name):
        if self.environment.dependent_sections.get(repo_name):
            repo = self.environment.dependent_sections[repo_name]
            root = os.path.abspath(repo)
            regex = re.compile(r'.*code_snippet %s start (\w+)\n(.*)\n.*?code_snippet %s end' % (re.escape(code_name), re.escape(code_name)), re.MULTILINE | re.DOTALL)
            name = ''
            try:
                # this uses `ag` as searching across files is not something we need to reprogram
                output = subprocess.check_output(['ag', '--files-with-matches', '--silent', '--one-device', '-i', '--max-count', '1', 'code_snippet %s start' % code_name, root])
                name = output.splitlines()[0]
            except subprocess.CalledProcessError as e:
                name = ''
            print('name: %s' % name)
            if name != "":
                path = os.path.join(root, name)
                f = open(path, 'r')
                matches = regex.search(f.read())
                if matches is not None:
                    return("""```%s\n%s\n```""" % (matches.group(1), matches.group(2)))
            raise TemplateRuntimeError('could not find code snippet "%s" under repo "%s" -- please check "ag" for existance or ".gitignore"' % (code_name, repo_name))
        else:
            raise TemplateRuntimeError('dependent section "%s" not defined in mkdocs.yml' % (repo_name))


class JinjaMkDocPlugin(plugins.BasePlugin):
    config_scheme = [
        ('dependent_sections', config.config_options.OptionallyRequired(default=dict()))
    ]


    def on_page_markdown(self, markdown, page, config, files):
        env = Environment(
            loader=FileSystemLoader(config['docs_dir']),
            extensions=[CodeSnippetExtension],
            )
        env.dependent_sections=self.config['dependent_sections']
        return env.from_string(markdown).render(config=config)
