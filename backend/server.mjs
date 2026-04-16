import { createServer } from "node:http";
import { config as loadEnv } from "dotenv";
import { ConnectClient, StartChatContactCommand } from "@aws-sdk/client-connect";

loadEnv();

const PORT = Number.parseInt(process.env.PORT ?? "8787", 10);
const HOST = process.env.HOST ?? "127.0.0.1";
const DEFAULT_REGION = process.env.AMAZON_CONNECT_REGION ?? "us-east-1";
const DEFAULT_INSTANCE_ID = process.env.AMAZON_CONNECT_INSTANCE_ID ?? "";
const DEFAULT_CONTACT_FLOW_ID = process.env.AMAZON_CONNECT_CONTACT_FLOW_ID ?? "";
const DEFAULT_SOURCE = process.env.AMAZON_CONNECT_SOURCE ?? "ios-floating-chat-poc";

const jsonHeaders = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type"
};

createServer(async (req, res) => {
  if (!req.url) {
    respond(res, 404, { error: "Not found." });
    return;
  }

  const url = new URL(req.url, `http://${req.headers.host ?? "localhost"}`);

  if (req.method === "OPTIONS") {
    res.writeHead(204, jsonHeaders);
    res.end();
    return;
  }

  if (req.method === "GET" && url.pathname === "/health") {
    respond(res, 200, {
      ok: true,
      service: "connect-floating-chat-backend",
      timestamp: new Date().toISOString()
    });
    return;
  }

  if (req.method === "POST" && url.pathname === "/api/chat/start") {
    try {
      const body = await readJsonBody(req);
      const payload = buildStartChatPayload(body);
      const client = new ConnectClient({ region: payload.region });

      const command = new StartChatContactCommand(payload.commandInput);
      const result = await client.send(command);

      if (!result.ParticipantToken) {
        throw new Error("Amazon Connect did not return a participant token.");
      }

      respond(res, 200, {
        participantToken: result.ParticipantToken,
        participantId: result.ParticipantId ?? null,
        contactId: result.ContactId ?? null,
        region: payload.region
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown backend error.";
      const statusCode = isValidationError(message) ? 400 : 500;

      respond(res, statusCode, {
        error: message
      });
    }
    return;
  }

  respond(res, 404, { error: "Not found." });
}).listen(PORT, HOST, () => {
  console.log(`Amazon Connect bootstrap API listening on http://${HOST}:${PORT}`);
});

function respond(res, statusCode, body) {
  res.writeHead(statusCode, jsonHeaders);
  res.end(JSON.stringify(body, null, 2));
}

async function readJsonBody(req) {
  const chunks = [];

  for await (const chunk of req) {
    chunks.push(chunk);
  }

  if (chunks.length === 0) {
    return {};
  }

  const raw = Buffer.concat(chunks).toString("utf8");
  return JSON.parse(raw);
}

function buildStartChatPayload(body) {
  const region = requiredString(body.region || DEFAULT_REGION, "region");
  const instanceId = requiredString(body.instanceId || DEFAULT_INSTANCE_ID, "instanceId");
  const contactFlowId = requiredString(body.contactFlowId || DEFAULT_CONTACT_FLOW_ID, "contactFlowId");

  const customerName = coalesce(body.customerName, body.customerId, "Mobile Customer");
  const locale = coalesce(body.locale, "en-US");
  const issueType = coalesce(body.issueType, "general_support");
  const customerId = coalesce(body.customerId, "unknown-customer");
  const orderId = coalesce(body.orderId, "unknown-order");
  const membershipTier = coalesce(body.membershipTier, "Standard");

  const initialMessage = `Customer needs help with ${readableIssueType(issueType)}.`;

  return {
    region,
    commandInput: {
      InstanceId: instanceId,
      ContactFlowId: contactFlowId,
      ParticipantDetails: {
        DisplayName: customerName
      },
      Attributes: {
        customerId,
        orderId,
        membershipTier,
        locale,
        issueType,
        source: DEFAULT_SOURCE
      },
      InitialMessage: {
        ContentType: "text/plain",
        Content: initialMessage
      },
      SupportedMessagingContentTypes: [
        "text/plain",
        "text/markdown"
      ]
    }
  };
}

function requiredString(value, fieldName) {
  const trimmed = typeof value === "string" ? value.trim() : "";

  if (!trimmed) {
    throw new Error(`Missing required field: ${fieldName}`);
  }

  return trimmed;
}

function coalesce(...values) {
  for (const value of values) {
    if (typeof value === "string") {
      const trimmed = value.trim();
      if (trimmed) {
        return trimmed;
      }
    }
  }

  return "";
}

function readableIssueType(issueType) {
  return issueType
    .replace(/[_-]+/g, " ")
    .trim();
}

function isValidationError(message) {
  return message.startsWith("Missing required field:")
    || message.includes("Unexpected token");
}
