import { spawn } from "node:child_process";
import { resolve, join, relative } from "node:path";
import fs from "node:fs";
import crypto from "node:crypto";

/**
 * Run a command and return the output
 * @param {string} command The command to run
 * @param  {...string} args The arguments to pass to the command
 * @returns {Promise<string>} The output of the command
 */
const run = async (command, ...args) => {
  const cwd = resolve();
  return new Promise((resolve) => {
    const cmd = spawn(command, args, {
      stdio: ["inherit", "pipe", "pipe"], // Inherit stdin, pipe stdout, pipe stderr
      shell: true,
      cwd,
    });

    let output = "";

    cmd.stdout.on("data", (data) => {
      // process.stdout.write(data.toString());
      output += data.toString();
    });

    cmd.stderr.on("data", (data) => {
      // process.stderr.write(data.toString());
      throw new Error(data.toString());
    });

    cmd.on("close", () => {
      resolve(output);
    });
  });
};

/**
 * Generate a random secret that is 32 bytes long
 * @returns {string} A random secret
 */
function generateSecret() {
  const buffer = crypto.randomBytes(32);
  return buffer.toString("hex");
}

/**
 * Rename all instances of `oldName` to `newName` in the file at `filePath`.
 * If a `generator` function is provided, it will be called for each match
 * and the return value will be used as the replacement.
 * @param {string} filePath
 * @param {string} oldName
 * @param {string} newName
 * @param {() => string | null} generator
 */
function renameInFile(filePath, oldName, newName, generator = null) {
  let content = fs.readFileSync(filePath, "utf8");
  content = content.replace(new RegExp(oldName, "g"), (match) => {
    if (generator && typeof generator === "function") {
      return generator();
    }
    return newName;
  });
  fs.writeFileSync(filePath, content, "utf8");
}

/**
 * Traverse the directory and call the `operation` function on each file not in the `filesToIgnore` array or the `dirsToIgnore` array
 * @param {string} dir The directory to traverse
 * @param {string} rootDir The root directory of the project
 * @param {() => void} operation The operation to perform on each file
 * @param {string[]} filesToIgnore The files to ignore
 * @param {string[]} dirsToIgnore The directories to ignore
 */
function traverseDirectory(
  dir,
  rootDir,
  operation,
  filesToIgnore = [],
  dirsToIgnore = []
) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    const relativePath = relative(rootDir, fullPath);

    if (entry.isDirectory()) {
      if (
        !dirsToIgnore.includes(entry.name) &&
        !dirsToIgnore.includes(relativePath)
      ) {
        traverseDirectory(
          fullPath,
          rootDir,
          operation,
          filesToIgnore,
          dirsToIgnore
        );
      }
    } else if (!filesToIgnore.includes(entry.name)) {
      operation(fullPath, relativePath, entry);
    }
  }
}

/**
 * Print the help message to the console
 * @returns {void}
 */
function showHelp() {
  console.log(`
Usage: node ./run.js [command]

Commands:
  help        Show this help message
  check       Check the project to verify it's setup correctly
  setup       Setup the project for the first time
  `);
}

/**
 * Check the versions of the tools required by the project
 */
async function checkToolVersions() {
  // https://docs.npmjs.com/cli/v6/using-npm/scripts#packagejson-vars
  const minNodeVersion = process.env.npm_package_engines_node
    ?.replace("~", "")
    .replace(">=", "")
    .replace("^", "")
    .split(".")
    .map((n) => Number(n)) ?? [20, 16];
  const minPnpmVersion = process.env.npm_package_packageManager
    ?.replace("pnpm@", "")
    .split(".")
    .map((n) => Number(n)) ?? [9, 5];
  const minDockerVersion = process.env.npm_package_engines_docker
    ?.replace("~", "")
    .split(".")
    .map((n) => Number(n)) ?? [26, 1];

  try {
    const nodeVersion = (await run("node", "--version"))
      .slice(1)
      .trim()
      .split(".");
    const [nodeMajor, nodeMinor] = nodeVersion;
    if (
      +nodeMajor < minNodeVersion[0] ||
      (+nodeMajor === minNodeVersion[0] && +nodeMinor < minNodeVersion[1])
    ) {
      console.error(
        `error: node version ${minNodeVersion.join(".")} or higher is required`
      );
      process.exit(1);
    } else {
      console.log(
        `found node v${nodeMajor}.${nodeMinor}.${
          nodeVersion.length > 2 ? nodeVersion[2] : 0
        }`
      );
    }

    const pnpmVersion = (await run("pnpm", "--version")).trim().split(".");
    const [pnpmMajor, pnpmMinor] = pnpmVersion;
    if (
      +pnpmMajor < minPnpmVersion[0] ||
      (+pnpmMajor === minPnpmVersion[0] && +pnpmMinor < minPnpmVersion[1])
    ) {
      console.warn(
        `warn: pnpm version ${minPnpmVersion.join(
          "."
        )} or higher is required; attempting to update`
      );
      await run("pnpm", "install", "-g", "pnpm@latest");
      console.log("notice: updated pnpm to the latest version");
    } else {
      console.log(
        `found pnpm v${pnpmMajor}.${pnpmMinor}.${
          pnpmVersion.length > 2 ? pnpmVersion[2] : 0
        }`
      );
    }

    const dockerVersion = (await run("docker", "--version"))
      .trim()
      .split(" ")[2]
      .split(".");
    const [dockerMajor, dockerMinor] = dockerVersion;
    if (
      +dockerMajor < minDockerVersion[0] ||
      (+dockerMajor === minDockerVersion[0] &&
        +dockerMinor < minDockerVersion[1])
    ) {
      console.error("error: docker version 26.0.0 or higher is required");
      process.exit(1);
    } else {
      console.log(
        `found docker v${dockerMajor}.${dockerMinor}.${
          dockerVersion.length > 2 ? dockerVersion[2].replace(",", "") : 0
        }`
      );
    }
  } catch (error) {
    if (error instanceof Error) {
      console.error(error.message);
    } else {
      console.error("error: unknown error occurred");
    }
    process.exit(1);
  }
}

/**
 * Setup the project for the first time
 * This will rename all instances of "changemename" to the new project name
 * and create the .env and .env.production files
 * @param {string} newProjectName
 */
async function firstSetup(newProjectName) {
  const namePattern =
    /^(?:(?:@(?:[a-z0-9-*~][a-z0-9-*._~]*)?\/[a-z0-9-._~])|[a-z0-9-~])[a-z0-9-._~]*$/;
  if (!namePattern.test(newProjectName)) {
    console.error(
      `error: invalid project name: "${newProjectName}"

A valid name must follow these rules:
- Start with a lowercase letter, number, or @
- Can contain lowercase letters, numbers, hyphens, underscores, and periods
- If it starts with @, it must be followed by a scope (e.g., @myscope/mypackage)
- Cannot have uppercase letters
- Cannot have spaces
- Cannot end with a period

Examples of valid names:
- my-project
- @myscope/my-project
- my_project123
- @org/project-name\n`
    );
    process.exit(1);
  }

  const filesToIgnore = [
    "pnpm-lock.yaml",
    ".env.example",
    ".gitignore",
    "pnpm-workspace.yaml",
    "yarn.lock",
    "tsconfig.json",
  ];
  const dirsToIgnore = [
    "node_modules",
    "packages",
    "dist",
    "build",
    ".git",
    ".vscode",
    ".docker",
    "scripts",
  ];

  const rootDir = process.cwd();

  try {
    // Rename all instances of "changemename" to the new project name
    traverseDirectory(
      rootDir,
      rootDir,
      (filePath) => {
        renameInFile(filePath, "changemename", newProjectName);
      },
      filesToIgnore,
      dirsToIgnore
    );

    const envExamplePath = join(rootDir, ".env.example");
    const envPath = join(rootDir, ".env");
    const envProdPath = join(rootDir, ".env.production");
    if (fs.existsSync(envExamplePath)) {
      if (!fs.existsSync(envPath)) {
        fs.copyFileSync(envExamplePath, envPath);
        renameInFile(envPath, "changemesecret", "", generateSecret);
        console.log(
          "created .env file; please update it with your configurations"
        );
      }
      if (!fs.existsSync(envProdPath)) {
        fs.copyFileSync(envExamplePath, envProdPath);
        renameInFile(envProdPath, "changemesecret", "", generateSecret);
        console.log(
          "created .env.production file; please update it with your configurations"
        );
      }
    }
  } catch (err) {
    console.error("Error:", err);
  }

  console.log("project setup complete");
}

const main = async () => {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error("error: no command provided");
    process.exit(1);
  }

  const command = args[0];
  switch (command) {
    case "help":
      showHelp();
      break;
    case "check":
      await checkToolVersions();
      break;
    case "setup": {
      const newProjectName = args[1];
      if (!newProjectName) {
        console.error("error: no project name provided\n");
        process.exit(1);
      }
      await firstSetup(newProjectName);
      break;
    }
    default:
      console.error(`error: unknown command: ${command}`);
      process.exit(1);
  }
};

main();
