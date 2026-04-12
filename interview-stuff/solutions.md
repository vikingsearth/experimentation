# solutions

## S1: Let's use what exists

There are pre-existing harnesses we can use to achieve the same goal with minimal code, such as claude code cli

- grab claude code cli
- put it behind an express server with a single route acting as a wrapper around the cli
- put the server in a container
- test it manually

## S2: build it ourselves - MINIMAL

Maybe we'd like to have more control, and then opt for a basic implementation of langchain deepagents.

## S3: build it ourselves - MINIMAL CLI

Let's stick with what we have, but let's add a CLI interface to it, so we can run it from the command line and pass in different questions or configurations without having to change the code.

## S4: build it ourselves - STANDARDS

Let's upgrade our current work

- split up the core code into different files based on SOC groupings and layers
  - e.g. harness stuff, runtime stuff needs a split
  - then agent, prompt, tool configurations can be split up as well
- add logging and error handling + retry logic where needed

CLI upgrade needed?

- increase flags and options ORRR
- make it more generalized\

## S5: build it ourselves - PERIPHERALS

It's time to D-D-D-Dockerize!

- configure two stage dockerfile build
- add health checks and logging
- extract configuration via environment variables and/or config files

Unit tests? Integration tests?

- plan a strat
- decide on the best tools and frameworks to use for testing
- gen some tests

## S5: Build it ourselves from scratch

Why?
You would either do this because you want to learn how to build an agent framework, or because you have very specific requirements that existing frameworks don't meet. This does not seem to be the case here, so we're not doing this.