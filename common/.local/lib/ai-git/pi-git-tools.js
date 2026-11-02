import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const mode = process.env.AI_GIT_PI_MODE;
const autoExit = process.env.AI_GIT_PI_AUTO_EXIT === "1";

if (mode !== "commit" && mode !== "review" && mode !== "diff") {
    throw new Error("AI_GIT_PI_MODE must be commit, review, or diff");
}

const emptyParameters = {
    type: "object",
    properties: {},
    additionalProperties: false,
};

const pathParameters = {
    type: "array",
    items: { type: "string", minLength: 1 },
    minItems: 1,
};

function commandOutput(stdout, stderr) {
    const output = [stdout, stderr].filter(Boolean).join("\n").trim();
    return output || "Command completed successfully.";
}

async function runGit(args, signal) {
    try {
        const { stdout, stderr } = await execFileAsync("git", args, {
            cwd: process.cwd(),
            encoding: "utf8",
            maxBuffer: 10 * 1024 * 1024,
            signal,
        });

        return {
            content: [{ type: "text", text: commandOutput(stdout, stderr) }],
            details: { args },
        };
    } catch (error) {
        const output = commandOutput(error.stdout, error.stderr);
        throw new Error(output === "Command completed successfully." ? error.message : output);
    }
}

export default function gitTools(pi) {
    pi.on("agent_settled", (_event, ctx) => {
        if (autoExit && ctx.mode === "tui") ctx.shutdown();
    });

    pi.registerTool({
        name: "git_status",
        label: "Git status",
        description: "Show the current branch and all staged, unstaged, and untracked changes.",
        promptSnippet: "Show Git status without changing the repository",
        parameters: emptyParameters,
        async execute(_toolCallId, _params, signal) {
            return runGit(["status", "--short", "--branch", "--untracked-files=all"], signal);
        },
    });

    pi.registerTool({
        name: "git_diff",
        label: "Git diff",
        description: "Show the staged or unstaged Git diff, optionally limited to paths.",
        promptSnippet: "Inspect staged or unstaged Git changes without modifying them",
        parameters: {
            type: "object",
            properties: {
                staged: {
                    type: "boolean",
                    description: "Show staged changes instead of unstaged changes.",
                    default: false,
                },
                paths: {
                    ...pathParameters,
                    description: "Optional repository-relative paths to inspect.",
                },
            },
            additionalProperties: false,
        },
        async execute(_toolCallId, params, signal) {
            const args = ["diff"];
            if (params.staged) args.push("--cached");
            args.push("--", ...(params.paths || []));
            return runGit(args, signal);
        },
    });

    pi.registerTool({
        name: "git_log",
        label: "Git log",
        description: "Show recent commit hashes and subjects.",
        promptSnippet: "Inspect recent Git commit subjects without modifying the repository",
        parameters: {
            type: "object",
            properties: {
                count: {
                    type: "integer",
                    minimum: 1,
                    maximum: 50,
                    default: 10,
                    description: "Number of recent commits to show.",
                },
            },
            additionalProperties: false,
        },
        async execute(_toolCallId, params, signal) {
            return runGit(
                ["log", `--max-count=${params.count || 10}`, "--format=%h %s"],
                signal,
            );
        },
    });

    if (mode !== "commit") return;

    pi.registerTool({
        name: "git_add",
        label: "Git add",
        description: "Stage only the specified repository paths. Git options are not accepted.",
        promptSnippet: "Stage explicit repository paths for the requested commit",
        parameters: {
            type: "object",
            properties: { paths: pathParameters },
            required: ["paths"],
            additionalProperties: false,
        },
        async execute(_toolCallId, params, signal) {
            return runGit(["add", "--", ...params.paths], signal);
        },
    });

    pi.registerTool({
        name: "git_commit",
        label: "Git commit",
        description: "Create or amend one commit with normal Git hooks enabled.",
        promptSnippet: "Create or explicitly amend one Git commit with normal hooks enabled",
        parameters: {
            type: "object",
            properties: {
                message: {
                    type: "string",
                    minLength: 1,
                    description: "The complete commit message.",
                },
                amend: {
                    type: "boolean",
                    default: false,
                    description: "Amend HEAD only when the user explicitly requested it.",
                },
            },
            required: ["message"],
            additionalProperties: false,
        },
        async execute(_toolCallId, params, signal) {
            const args = ["commit"];
            if (params.amend) args.push("--amend");
            args.push("-m", params.message);
            return runGit(args, signal);
        },
    });
}
