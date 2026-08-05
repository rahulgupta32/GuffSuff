import React from "react";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body
        style={{
          fontFamily: "system-ui, sans-serif",
          margin: 0,
          padding: 24,
          backgroundColor: "#0f172a",
          color: "#f8fafc"
        }}
      >
        {children}
      </body>
    </html>
  );
}
