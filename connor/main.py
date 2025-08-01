import os
import shutil
import signal
import sys
import argparse
from jinja2 import Environment, FileSystemLoader
from pathlib import Path
from http.server import SimpleHTTPRequestHandler, HTTPServer

routes = {
    '/': 'home.html',
    '/portfolio': 'portfolio.html',
    '/about': 'about.html',
}

def main(args):
    shutil.rmtree("dist", ignore_errors=True)
    os.makedirs("dist", exist_ok=True)

    # Feature: Satellite image background
    # todo: pull satellite image
    # todo: optimize satellite image for all screen widths
    # todo: write optimized image links to template file
    # todo: write optimized images to destination

    # Static site generation
    env = Environment(loader=FileSystemLoader('templates'))
    for route, template in routes.items():
        template = env.get_template(template)
        content = template.render(path=route)
        file_path = Path("dist") / route.strip("/") / "index.html"
        file_path.parent.mkdir(parents=True, exist_ok=True)
        with open(file_path, 'w') as f:
            f.write(content)

    # Copy static files
    static_dir = Path("static")
    dist_static_dir = Path("dist") / "static"
    shutil.copytree(static_dir, dist_static_dir)

    if args.dev:
        print("Development mode enabled. Serving files from 'dist' directory.")
        run_dev_server(args.output)

    pass

def run_dev_server(dir):
    os.chdir(dir)
    server_address = ('', 8000)
    httpd = HTTPServer(server_address, SimpleHTTPRequestHandler)
    def shutdown_handler(signal, frame):
        print("Shutting down server...")
        httpd.server_close()
        sys.exit(0)
    signal.signal(signal.SIGINT, shutdown_handler)
    signal.signal(signal.SIGTERM, shutdown_handler)
    print("Serving on port 8000...")
    httpd.serve_forever()

def parse_args():
    parser = argparse.ArgumentParser(description="Static site generator for Connor's portfolio.")
    parser.add_argument('--output', type=str, default='dist', help='Output directory for the generated site.')
    parser.add_argument('--dev', action='store_true', help='Enables development mode.')
    return parser.parse_args()

if __name__ == "__main__":
    main(parse_args())