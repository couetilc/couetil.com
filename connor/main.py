import os
import logging
import shutil
import signal
import sys
import argparse
import threading
from jinja2 import Environment, FileSystemLoader
from pathlib import Path
from http.server import SimpleHTTPRequestHandler, HTTPServer
from watchdog.events import FileSystemEventHandler
from watchdog.observers.polling import PollingObserver as Observer

logging_level = getattr(logging, os.getenv("LOG_LEVEL", "INFO"), logging.INFO)
logging.basicConfig(level=logging_level)
log = logging.getLogger(__name__)
log.info(f"LOG_LEVEL={logging_level}")

routes = {
    '/': 'home.html',
    '/portfolio': 'portfolio.html',
    '/about': 'about.html',
}

def main():
    log.info('Start')

    parser = argparse.ArgumentParser(
        description="Static site generator for Connor's portfolio."
    )
    parser.add_argument(
        '--output',
        type=str,
        default='dist',
        help='Output directory for the generated site.'
    )
    parser.add_argument(
        '--dev',
        action='store_true',
        help='Enables development mode.'
    )
    args = parser.parse_args()

    output_dir = os.path.join(os.getcwd(), args.output)
    dev = args.dev
    log.info(f'Arguments output={output_dir} dev={dev}')

    # shutil.rmtree(args.output, ignore_errors=True)
    os.makedirs(output_dir, exist_ok=True)

    # Feature: Satellite image background
    # todo: pull satellite image
    # todo: optimize satellite image for all screen widths
    # todo: write optimized image links to template file
    # todo: write optimized images to destination

    init_cwd = os.getcwd()
    
    template_dir = os.path.join(init_cwd, "templates")
    static_dir = os.path.join(init_cwd, "static")

    def render_template_files():
        env = Environment(loader=FileSystemLoader(template_dir))
        for route, template in routes.items():
            template = env.get_template(template)
            content = template.render(path=route)
            file_path = Path(output_dir) / route.strip("/") / "index.html"
            file_path.parent.mkdir(parents=True, exist_ok=True)
            with open(file_path, 'w') as f:
                f.write(content)

    def copy_static_files():
        dist_static_dir = Path(output_dir) / "static"
        shutil.copytree(static_dir, dist_static_dir, dirs_exist_ok=True, )

    render_template_files()
    copy_static_files()

    # optimization: instead of threads, do processes? so fork? avoid GIL? detect child process signals and reap the process. Can use "multiprocessing" python module to do that for me.
    if dev:
        hot_reload = HotReload(
            tasks=[render_template_files, copy_static_files],
            watch_dirs=['templates', 'static']
        )
        staticd = StaticFileServer(dir=output_dir)

        def signal_handler(signum, frame):
            signal.signal(signal.SIGINT, signal.SIG_DFL)
            signal.signal(signal.SIGTERM, signal.SIG_DFL)
            hot_reload.stop()
            staticd.stop()

        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)

        hot_reload.start()
        staticd.start()

        hot_reload.join()
        staticd.join()

    log.info('Stop')


class HotReload():
    """
    Runs tasks whenever a file in a directory changes

    Usage:
        hot_reload = HotReload()
        hot_reload.start() # starts thread
        hot_reload.stop()  # stops thread
        hot_reload.join()  # waits for thread to stop
    """

    log = log.getChild('HotReload')

    class EventHandler(FileSystemEventHandler):
        def __init__(self, handler, log):
            self.handler = handler
            self.log = log.getChild('EventHandler')
        def on_any_event(self, event):
            self.log.debug(event)
            self.handler()

    def __init__(self, tasks=[], watch_dirs=[]):
        self.watch_dirs = []
        for path in watch_dirs:
            fullpath = os.path.join(os.getcwd(), path)
            self.watch_dirs.append(fullpath)

        self.observer = Observer()

        def run_tasks():
            for task in tasks:
                task()

        for dir in self.watch_dirs:
            self.observer.schedule(
                self.EventHandler(run_tasks, self.log),
                path=dir,
                recursive=True
            )

    def start(self):
        self.observer.start()
        self.log.info(f"Started watching {self.csv_watch_dirs}")

    def stop(self):
        self.observer.stop()
        self.log.info(f"Stopped watching {self.csv_watch_dirs}")

    def join(self):
        self.observer.join()

    @property
    def csv_watch_dirs(self):
        return ', '.join(self.watch_dirs)


class StaticFileServer():
    """
    Starts a static file server on another thread 

    Usage:
        httpd = StaticFileServer()
        httpd.start() # starts thread
        httpd.stop()  # stops thread
        httpd.join()  # waits for thread to stop
    """

    log = log.getChild('StaticFileServer')

    def __init__(self, dir, server_address=('', 8000)):
        self.dir = os.path.join(os.getcwd(), dir)
        self.httpd = HTTPServer(server_address, SimpleHTTPRequestHandler)
        self.thread = threading.Thread(target=self.__serve)

    @property
    def address(self):
        return self.httpd.server_address[0]

    @property
    def port(self):
        return self.httpd.server_address[1]

    def start(self):
        self.log.info(f'Starting static file server address={self.address} port={self.port} directory={self.dir}')
        self.thread.start()

    def stop(self):
        self.log.info('Shutdown started')
        self.httpd.shutdown()
        self.httpd.server_close()
        self.log.info('Shutdown complete')

    def join(self):
        self.thread.join()

    def __serve(self):
        os.chdir(self.dir)
        self.httpd.serve_forever()


if __name__ == "__main__":
    main()
