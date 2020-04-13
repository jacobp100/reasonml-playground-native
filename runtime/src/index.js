const requireLibFile = (file) => require(`../bs/${file.replace(/^\.\//, "")}`);

global.evalScript = (source) => {
  const fn = new Function("require", "exports", source);
  try {
    fn(requireLibFile, {});
  } catch (e) {
    console.error(e.message);
  }
};
