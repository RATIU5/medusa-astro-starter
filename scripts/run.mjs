import { spawn } from "node:child_process";
import { resolve } from "node:path";

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
      process.stderr.write(data.toString());
    });

    cmd.on("close", () => {
      resolve(output);
    });
  });
};

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

async function checkToolVersions() {
  const minNodeVersion = [20, 16];
  const minPnpmVersion = [9, 5];
  const minDockerVersion = [26, 0];

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
    (+dockerMajor === minDockerVersion[0] && +dockerMinor < minDockerVersion[1])
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

  console.log("\nProject check complete");
}

async function firstSetup() {
  // Rename all instances of "changemename" to the project name
  const filesToIgnore = ["node_modules/", ".git/", ".vscode/", "scripts/"];
}

const main = async () => {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error("No command provided");
    process.exit(1);
  }

  const command = args[0];
  switch (command) {
    case "help":
      showHelp();
      break;
    case "setup":
      await firstSetup();
      break;
    case "check":
      await checkToolVersions();
      break;
    default:
      console.error(`Unknown command: ${command}`);
      process.exit(1);
  }
};

main();
