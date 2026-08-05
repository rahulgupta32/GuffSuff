name: Bug Report
description: Report a reproducible bug in GuffSuff
title: "[BUG]: "
labels: ["type: bug", "triage"]
body:

- type: markdown
  attributes:
  value: Thank you for reporting a bug!
- type: textarea
  id: description
  attributes:
  label: Bug Description
  description: A clear and concise description of what the bug is.
  validations:
  required: true
- type: textarea
  id: steps
  attributes:
  label: Steps to Reproduce
  description: Detailed steps to reproduce the behavior.
  validations:
  required: true
- type: input
  id: environment
  attributes:
  label: Environment Details
  description: OS version, mobile OS (Android/iOS), network status (+977 2G/3G/Wi-Fi).
  validations:
  required: false
