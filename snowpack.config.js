module.exports = {
  exclude: ['users/', 'viz/'],
  optimize: {
    bundle: true,
    minify: false,
    target: 'es2018',
  },
  mount: {
    www: '/'
  }
};
