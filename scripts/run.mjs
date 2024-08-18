import { spawn } from "node:child_process";
import { resolve, join, relative, dirname, basename } from "node:path";
import fs from "node:fs";
import crypto from "node:crypto";
import readline from "node:readline/promises";
import dotenv from "dotenv";

dotenv.config();

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

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
 * Determine whether the setup is complete by checking for the presence of a .env file
 * @returns {boolean} Whether the setup is complete
 */
function isSetupComplete() {
  const envPath = join(process.cwd(), ".env");
  return fs.existsSync(envPath);
}

/**
 * Get Docker volumes
 * @param {string} [prefix=''] - Optional prefix for volume names
 * @returns {Promise<string[]>} List of volume names
 */
async function getVolumes(prefix = "") {
  const cmd = prefix
    ? `docker volume ls -q -f name=${prefix}_`
    : "docker volume ls -q";
  const output = await run(cmd);
  return output.trim().split("\n").filter(Boolean);
}

/**
 * Get project-specific Docker images
 * @param {string} projectName - The project name
 * @returns {Promise<string[]>} List of image names
 */
async function getProjectImages(projectName) {
  const output = await run(
    "docker",
    "images",
    "--format",
    "{{.Repository}}:{{.Tag}}"
  );
  return output
    .trim()
    .split("\n")
    .filter((img) => img.startsWith(projectName));
}

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
  clean []    Clean up containers, volumes, and images (development)
              [--preserve-db]  Preserve the database volume
  clean:all   Clean up everything (including all volumes)
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
  } catch (error) {
    console.error("error: node is not installed");
    process.exit(1);
  }

  try {
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
  } catch (error) {
    console.error("error: pnpm is not installed");
    process.exit(1);
  }

  try {
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
    console.error("error: docker is not installed");
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
    ".gitignore",
    "pnpm-workspace.yaml",
    "yarn.lock",
    "tsconfig.json",
    "run.mjs",
    ".env.example",
  ];
  const dirsToIgnore = [
    "node_modules",
    "dist",
    "build",
    ".git",
    ".vscode",
    ".docker",
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

    // Find all .env.example files and create corresponding .env and .env.production files
    traverseDirectory(
      rootDir,
      rootDir,
      (filePath, relativePath) => {
        if (basename(filePath) === ".env.example") {
          const dirPath = dirname(filePath);
          const envPath = join(dirPath, ".env");
          const envProdPath = join(dirPath, ".env.production");

          if (!fs.existsSync(envPath)) {
            fs.copyFileSync(filePath, envPath);
            renameInFile(envPath, "changemename", newProjectName);
            renameInFile(envPath, "changemesecret", "", generateSecret);
            console.log(`Created .env file in ${relativePath}`);
          }

          if (!fs.existsSync(envProdPath)) {
            fs.copyFileSync(filePath, envProdPath);
            renameInFile(envProdPath, "changemename", newProjectName);
            renameInFile(envProdPath, "changemesecret", "", generateSecret);
            console.log(`Created .env.production file in ${relativePath}`);
          }
        }
      },
      filesToIgnore,
      dirsToIgnore
    );
  } catch (err) {
    console.error("Error:", err);
  }

  console.log("Project setup complete");
}

/**
 * Clean up containers, volumes, and images (development)
 * @param {boolean} preserveDb - Whether to preserve the database volume
 */
async function clean(preserveDb = false) {
  const ans = await rl.question(
    "Are you sure you want to remove project-related containers, images, and volumes? [y/N] "
  );

  if (ans.toLowerCase() === "y") {
    try {
      // Stop and remove containers
      await run("docker", "compose", "down", "--remove-orphans");

      // Identify the postgres volume
      const composeProjectName = process.env.COMPOSE_PROJECT_NAME;
      const postgresVolume = `${composeProjectName}_postgres_data`;

      // Remove volumes
      if (preserveDb) {
        console.log(
          `preserving PostgreSQL volume (${postgresVolume}) and removing other volumes`
        );
        const volumes = await getVolumes();
        const volumesToRemove = volumes.filter((v) => v !== postgresVolume);
        if (volumesToRemove.length > 0) {
          await run("docker", "volume", "rm", ...volumesToRemove);
        }
      } else {
        console.log("removing all volumes");
        const volumes = await getVolumes();
        if (volumes.length > 0) {
          await run("docker", "volume", "rm", ...volumes);
        }
      }

      // Remove all project-specific images
      console.log("removing all project-specific images");
      const images = await getProjectImages(composeProjectName);
      if (images.length > 0) {
        await run("docker", "rmi", ...images);
      }

      console.log("cleanup completed");
    } catch (error) {
      console.error("error during cleanup:", error);
    } finally {
      rl.close();
    }
  }
}

/**
 * Clean up everything (including all volumes)
 */
async function cleanAll() {
  const ans = await rl.question(
    "This will remove ALL containers, images, and volumes. Are you really sure? [y/N] "
  );

  if (ans.toLowerCase() === "y") {
    try {
      await run("docker", "compose", "down", "-v", "--rmi", "all");
      await run("docker", "container", "prune", "-f");

      const composeProjectName = process.env.COMPOSE_PROJECT_NAME;
      const projectVolumes = await getVolumes(composeProjectName);
      if (projectVolumes.length > 0) {
        await run("docker", "volume", "rm", ...projectVolumes);
      }

      const allVolumes = await getVolumes();
      if (allVolumes.length > 0) {
        await run("docker", "volume", "rm", ...allVolumes);
      }

      await run("docker", "system", "prune", "-af", "--volumes");

      console.log("full cleanup completed");
    } catch (error) {
      console.error("error during full cleanup:", error);
    } finally {
      rl.close();
    }
  }
}

const main = async () => {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error("error: no command provided");
    process.exit(1);
  }

  try {
    const command = args[0];

    if (!["help", "check", "setup"].includes(command) && !isSetupComplete()) {
      console.error(
        "Error: Project setup has not been completed. Please run 'pnpm run:setup <project-name>' first."
      );
      process.exit(1);
    }

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
      case "clean":
        await clean(args[1] === "--preserve-db");
        break;
      case "clean:all":
        await cleanAll();
        break;
      default:
        console.error(`error: unknown command: ${command}`);
        process.exit(1);
    }
  } catch (error) {
    console.error("error:", error);
    process.exit(1);
  } finally {
    process.exit(0);
  }
};

main();
