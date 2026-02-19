const express = require("express");
const fs = require("fs");
const { exec } = require("child_process");
const path = require("path");

// Environment variables are passed by docker-compose from the root .env file
// No need for dotenv package when running in container

const app = express();
app.use(express.json());

const PORT = process.env.AGENT_PORT || 3000;
const API_SECRET = process.env.API_SECRET;
const XRAY_CONFIG_PATH = process.env.XRAY_CONFIG_PATH || "/xray/config.json";

if (!API_SECRET) {
  console.error("ERROR: API_SECRET environment variable is required");
  process.exit(1);
}

// Middleware to validate API secret
function validateApiSecret(req, res, next) {
  const secret = req.headers["x-api-secret"];

  if (!secret || secret !== API_SECRET) {
    return res.status(401).json({ error: "Unauthorized: Invalid API secret" });
  }

  next();
}

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "healthy", timestamp: new Date().toISOString() });
});

// Sync credentials endpoint
app.post("/api/sync-credentials", validateApiSecret, async (req, res) => {
  try {
    const { uuids } = req.body;

    if (!Array.isArray(uuids)) {
      return res.status(400).json({ error: "uuids must be an array" });
    }

    console.log(
      `[${new Date().toISOString()}] Syncing ${uuids.length} credentials...`,
    );

    // Read existing Xray config
    let config;
    try {
      const configData = fs.readFileSync(XRAY_CONFIG_PATH, "utf8");
      config = JSON.parse(configData);
    } catch (error) {
      return res.status(500).json({
        error: "Failed to read Xray config",
        details: error.message,
      });
    }

    // Update inbound clients with new UUIDs
    if (!config.inbounds || config.inbounds.length === 0) {
      return res.status(500).json({
        error: "No inbounds found in Xray config",
      });
    }

    // Find the VLESS inbound (usually the first one)
    const vlessInbound = config.inbounds.find(
      (inbound) => inbound.protocol === "vless",
    );

    if (!vlessInbound) {
      return res.status(500).json({
        error: "No VLESS inbound found in Xray config",
      });
    }

    // Replace clients array with new UUIDs
    vlessInbound.settings.clients = uuids.map((uuid) => ({
      id: uuid,
      flow: "xtls-rprx-vision",
      level: 0,
      email: `user_${uuid.substring(0, 8)}`,
    }));

    // Write updated config back to file
    try {
      fs.writeFileSync(
        XRAY_CONFIG_PATH,
        JSON.stringify(config, null, 2),
        "utf8",
      );
      console.log(
        `[${new Date().toISOString()}] Config updated with ${uuids.length} clients`,
      );
    } catch (error) {
      return res.status(500).json({
        error: "Failed to write Xray config",
        details: error.message,
      });
    }

    // Restart Xray container to apply changes
    exec(
      "docker-compose restart xray",
      { cwd: path.dirname(__dirname) },
      (error, stdout, stderr) => {
        if (error) {
          console.error(
            `[${new Date().toISOString()}] Failed to restart Xray:`,
            error.message,
          );
          // Don't fail the request - config is updated, restart might work on next attempt
        } else {
          console.log(
            `[${new Date().toISOString()}] Xray container restarted successfully`,
          );
        }
      },
    );

    res.json({
      success: true,
      clientsUpdated: uuids.length,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error(
      `[${new Date().toISOString()}] Error in sync-credentials:`,
      error,
    );
    res.status(500).json({
      error: "Internal server error",
      details: error.message,
    });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Atlas Node Agent running on port ${PORT}`);
  console.log(`Xray config path: ${XRAY_CONFIG_PATH}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});
