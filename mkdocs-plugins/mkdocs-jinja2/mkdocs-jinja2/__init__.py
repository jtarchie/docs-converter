__version__ = '0.0.0'

from mkdocs.plugins import BasePlugin
from jinja2 import Environment, FileSystemLoader

class JinjaMkDocPlugin(BasePlugin):
    def on_page_markdown(self, markdown, page, config, _):
        env = Environment(loader=FileSystemLoader(config['docs_dir']))
        return env.from_string(markdown).render(config=config)
