const express = require("express");
const client = require("prom-client");

const app = express();
const PORT = process.env.PORT ? Number(process.env.PORT) : 3000;

app.disable("x-powered-by");

// Prometheus metrics
const collectDefaultMetrics = client.collectDefaultMetrics;

collectDefaultMetrics({
  prefix: "app_",
});

const httpRequestDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status_code"],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
});

const register = client.register;

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

app.get("/metrics", async (req, res) => {
  try {
    res.set("Content-Type", register.contentType);
    res.status(200).end(await register.metrics());
  } catch (err) {
    res.status(500).end(err.toString());
  }
});

// Basic instrumentation for all routes
app.use((req, res, next) => {
  const start = process.hrtime.bigint();
  res.on("finish", () => {
    const end = process.hrtime.bigint();
    const seconds = Number(end - start) / 1e9;

    // Express doesn't expose route until matched; best-effort:
    // Use originalUrl/method for labels to keep it simple.
    const route = req.route && req.route.path ? req.route.path : req.path;

    httpRequestDuration
      .labels(req.method, route, String(res.statusCode))
      .observe(seconds);
  });
  next();
});

app.get("/", (req, res) => {
  res.status(200).send("metrics-health-service");
});

const server = app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`Service listening on port ${PORT}`);
});

// Export app for test runners / require() usage
module.exports = { app, server };
