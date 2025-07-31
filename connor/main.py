import os
import shutil
from jinja2 import Environment, FileSystemLoader
from pathlib import Path

routes = {
    '/': 'home.html',
    '/portfolio': 'portfolio.html',
    '/about': 'about.html',
}

def main():
    shutil.rmtree("dist", ignore_errors=True)
    os.makedirs("dist", exist_ok=True)

    # Feature: Satellite image background
    # todo: pull satellite image
    # todo: optimize satellite image for all screen widths
    # todo: write optimized image links to template file
    # todo: write optimized images to destination

    # Feature: Static site generation
    env = Environment(loader=FileSystemLoader('templates'))
    for route, template in routes.items():
        template = env.get_template(template)
        content = template.render(path=route)
        file_path = Path("dist") / route.strip("/") / "index.html"
        file_path.parent.mkdir(parents=True, exist_ok=True)
        with open(file_path, 'w') as f:
            f.write(content)

    # copy static directory to dist
    static_dir = Path("static")
    dist_static_dir = Path("dist") / "static"
    shutil.copytree(static_dir, dist_static_dir)

    pass


if __name__ == "__main__":
    # todo: parse args
    # todo: pass args to main
    main()