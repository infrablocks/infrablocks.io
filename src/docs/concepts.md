---
layout: docs
title: "InfraBlocks: Docs: Concepts"
short_title: "Concepts"
permalink: /docs/concepts
---
# Concepts

## Deployment Identifier
An identifier that is being use to separate deployments from each other. This could be a name of an environment name such as `development` or `production` or it can be a combination of an environment name and a label such as `devlopment-blue` and `development-green` in case you are doing blue/green deployment.

Deployment Identifier is a variable to infrablocks module to be used as postfix to the name of the resources. In addition, they are added to the resources as **tags** so that you can query the resources based on their deployment identifiers.

## Component
Usually you are adding an infrablock configuration for a particular component. We use `Component` variable infrablocks modules to identifiy which component this configuration relates to.
As an example when you are creating a *database* for an *application*, you can use the name of the application as the value for the Component variable.