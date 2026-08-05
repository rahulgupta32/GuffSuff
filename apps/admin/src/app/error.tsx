"use client";

import React from "react";

export default function ErrorBoundary({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div style={{ color: "#ef4444" }}>
      <h2>System Exception Occurred</h2>
      <p>{error.message}</p>
      <button onClick={() => reset()} style={{ padding: "8px 16px", cursor: "pointer" }}>
        Retry
      </button>
    </div>
  );
}
