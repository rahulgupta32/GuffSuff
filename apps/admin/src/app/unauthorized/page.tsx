import React from "react";

export default function UnauthorizedPage() {
  return (
    <div style={{ color: "#ef4444" }}>
      <h1>403 - Access Denied</h1>
      <p>Multi-factor WebAuthn authentication is required to access administrative boundaries.</p>
    </div>
  );
}
