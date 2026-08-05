name: Feature Request
description: Propose a feature or enhancement for GuffSuff
title: "[FEAT]: "
labels: ["type: feature"]
body:

- type: textarea
  id: problem
  attributes:
  label: Problem Statement / Context
  description: What problem does this feature solve?
  validations:
  required: true
- type: textarea
  id: solution
  attributes:
  label: Proposed Solution
  description: Describe the expected behavior and implementation approach.
  validations:
  required: true
