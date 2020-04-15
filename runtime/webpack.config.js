module.exports = {
  output: {
    libraryTarget: "var",
    library: "runtime",
  },
  node: {
    fs: "empty",
    child_process: "empty",
  },
};
