import type { Plugin } from "@opencode-ai/plugin"

const WORD_LIMIT = 40

function extractPreview(text: string, wordLimit: number): string {
    // Remove code blocks, inline code, collapse whitespace
    const cleaned = text
        .replace(/```[\s\S]*?```/g, "")
        .replace(/`[^`]*`/g, "")
        .replace(/\s+/g, " ")
        .trim()

    const words = cleaned.match(/\S+/g)
    if (!words || words.length === 0) return "Task Completed"

    const truncated = words.length > wordLimit
    return words.slice(0, wordLimit).join(" ") + (truncated ? "..." : "")
}

function escapeShellArg(str: string): string {
    // Escape single quotes for safe shell usage
    return str.replace(/'/g, "'\\''")
}

async function notify(
    $: Parameters<Plugin>[0]["$"],
    title: string,
    message: string,
    icon: string = "dialog-information"
) {
    const safeMessage = escapeShellArg(message)
    await $`notify-send ${title} ${safeMessage} --icon=${icon}`
}

export const NotifyPlugin: Plugin = async ({ client, $ }) => {
    return {
        async event(input) {
            if (input.event.type !== "session.idle") return

            const sessionID = input.event.properties.sessionID

            // Check if this is a subagent session - skip notification for those
            const sessionResult = await client.session.get({
                path: { id: sessionID }
            })

            if (!sessionResult.data) {
                await notify($, "OpenCode", "Error: Failed to fetch session", "dialog-error")
                return
            }

            if (sessionResult.data.parentID) {
                return // Subagent session, skip
            }

            // Fetch messages to extract preview from last assistant response
            const messagesResult = await client.session.messages({
                path: { id: sessionID }
            })

            if (!messagesResult.data || messagesResult.data.length === 0) {
                await notify($, "OpenCode", "Error: No messages found", "dialog-error")
                return
            }

            const lastMessage = messagesResult.data[messagesResult.data.length - 1]

            if (lastMessage.info.role !== "assistant") {
                await notify($, "OpenCode", "Task Completed")
                return
            }

            // Extract text from the last text part
            const parts = lastMessage.parts as { type: string; text?: string }[]
            const textParts = parts.filter(p => p.type === "text" && p.text)
            const lastText = textParts[textParts.length - 1]?.text

            if (!lastText) {
                await notify($, "OpenCode", "Task Completed")
                return
            }

            const preview = extractPreview(lastText, WORD_LIMIT)
            await notify($, "OpenCode", preview)
        },
    }
}
