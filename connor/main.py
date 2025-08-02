import os
import shutil
import signal
import sys
import argparse
from jinja2 import Environment, FileSystemLoader
from pathlib import Path
from http.server import SimpleHTTPRequestHandler, HTTPServer
from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer

routes = {
    '/': 'home.html',
    '/portfolio': 'portfolio.html',
    '/about': 'about.html',
}

class DevLoop(FileSystemEventHandler):
    def __init__(self, output_dir, watch_dirs=[]):
        self.output_dir = output_dir
        self.watch_dirs = watch_dirs
        self.observer = Observer()
        print(f"Watching directories: {', '.join(watch_dirs)}")
        for watch_dir in watch_dirs:
            self.observer.schedule(self, path=watch_dir, recursive=True)

    def dev_steps(self):
        print("Changes detected. Regenerating site...")
        generate_template_files(self.output_dir)
        copy_static_files(self.output_dir)

    def on_created(self, event):
        if event.is_directory:
            return
        self.dev_steps()
    def on_modified(self, event):
        if event.is_directory:
            return
        self.dev_steps()
    def on_deleted(self, event):
        if event.is_directory:
            return
        self.dev_steps()
    def on_moved(self, event):
        if event.is_directory:
            return
        self.dev_steps()

    def stop(self):
        self.observer.stop()
        self.observer.join()

def generate_template_files(outdir):
    env = Environment(loader=FileSystemLoader('templates'))
    for route, template in routes.items():
        template = env.get_template(template)
        content = template.render(path=route)
        file_path = Path(outdir) / route.strip("/") / "index.html"
        file_path.parent.mkdir(parents=True, exist_ok=True)
        with open(file_path, 'w') as f:
            f.write(content)

def copy_static_files(outdir):
    static_dir = Path("static")
    dist_static_dir = Path(outdir) / "static"
    shutil.copytree(static_dir, dist_static_dir, dirs_exist_ok=True, )

def main(args):
    # shutil.rmtree(args.output, ignore_errors=True)
    os.makedirs(args.output, exist_ok=True)

    # Feature: Satellite image background
    # todo: pull satellite image
    # todo: optimize satellite image for all screen widths
    # todo: write optimized image links to template file
    # todo: write optimized images to destination

    generate_template_files(args.output)
    copy_static_files(args.output)

    if args.dev:
        print("Development mode enabled. Serving files from 'dist' directory.")
        dev_loop = DevLoop(args.output, watch_dirs=['templates', 'static'])
        run_dev_server(args.output)
        dev_loop.stop()

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