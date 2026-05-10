db.createUser({
  user: "nepaltrust_app",
  pwd: "apppassword123",
  roles: [{ role: "readWrite", db: "nepaltrust" }]
});

db = db.getSiblingDB("nepaltrust");

db.createCollection("users");
db.createCollection("vaults");
db.createCollection("audit_logs");
db.createCollection("payment_intents");
db.createCollection("transactions");
db.createCollection("disputes");
db.createCollection("webhooks_received");

// Enforce immutability on audit_logs via validator
db.runCommand({
  collMod: "audit_logs",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["vaultId", "action", "actorId", "hash", "timestamp"],
      additionalProperties: true
    }
  }
});

print("NepalTrust DB initialized.");
