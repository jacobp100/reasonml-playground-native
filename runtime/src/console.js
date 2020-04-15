const defaultConsole = global.console;

export const levels = {
  LOG: 0,
  WARN: 1,
  ERROR: 2,
};

const formatArgs = (...args) => {
  return args
    .map((arg) => {
      if (typeof arg === "function") {
        return "(function)";
      } else if (arg != null && typeof arg === "object") {
        return JSON.stringify(arg);
      } else {
        // All primitives
        return String(arg);
      }
    })
    .join(" ");
};

const stubbedConsole = () => {
  const messages = [];
  const console = {
    log: (...args) => {
      messages.push({ level: levels.LOG, message: formatArgs(...args) });
    },
    warn: (...args) => {
      messages.push({ level: levels.WARN, message: formatArgs(...args) });
    },
    error: (...args) => {
      messages.push({ level: levels.ERROR, message: formatArgs(...args) });
    },
  };
  return { messages, console };
};

export const install = () => {
  const { messages, console } = stubbedConsole();
  global.console = console;
  return messages;
};

export const restore = () => {
  global.console = defaultConsole;
};
