function throttle(cb, { interval = 0, queue = true }) {
  let tid;
  let invoked = new Date().getTime();
  return (...arg) => {
    clearTimeout(tid);
    const now = new Date().getTime();
    if ((now - invoked) > interval) {
      invoked = now;
      cb(...arg);
    } else if (queue) {
      tid = setTimeout(cb, interval, ...arg);
    }
  }
}

function swingBackground (maxSkew = 0, options = {}) {
  const { selector = 'body', dirX = 1, dirY = 1 } = options;
  return (event) => {
    const width = window.innerWidth;
    const height = window.innerHeight;
    const origin = [ Math.floor(width / 2), Math.floor(height / 2)];
    const mouse_x = event.clientX;
    const mouse_y = event.clientY;
    const perc_skew_x = dirX * (mouse_x - origin[0]) / origin[0]
    const perc_skew_y = dirY * (mouse_y - origin[1]) / origin[1]
    const skew_x = maxSkew * perc_skew_x;
    const skew_y = maxSkew * perc_skew_y;
    document.querySelectorAll(selector).forEach(el => {
      el.style.transform = `translate(${skew_x}px, ${skew_y}px) scale(1.25)`;
    });
  }
}

document.addEventListener('mousemove', throttle(
  swingBackground(100, { selector: '#background img', dirX: -1, dirY: -1 }),
  { interval: 100 }
));
