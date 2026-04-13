# Java Agent — LangChain4J + Azure AI Foundry

A minimal AI agent that takes a user question, reads local knowledge base files via a tool call, and returns a grounded answer with citations.

## Prerequisites

- Java 17+ (`brew install openjdk@17`)
- Maven (`brew install maven`)
- Azure AI Foundry API key in `../prepwork/.env`

## Setup

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
```

If behind a corporate proxy (Netskope), create a custom truststore first:

```bash
echo | openssl s_client -connect repo.maven.apache.org:443 2>/dev/null | openssl x509 > /tmp/netskope-proxy.pem
cp "$JAVA_HOME/lib/security/cacerts" /tmp/cacerts-custom
keytool -import -trustcacerts -alias netskope-proxy -file /tmp/netskope-proxy.pem \
  -keystore /tmp/cacerts-custom -storepass changeit -noprompt
export MAVEN_OPTS="-Djavax.net.ssl.trustStore=/tmp/cacerts-custom -Djavax.net.ssl.trustStorePassword=changeit"
```

## Run

```bash
cd prepwork/java
mvn compile exec:java -Dexec.args="What is CodeLens and how much does it cost?" -q
```

## How It Works

1. Loads config from `../prepwork/.env` (Azure AI Foundry URL + API key)
2. Builds an `OpenAiChatModel` pointing at the Foundry endpoint
3. Wires up a `FileReadTool` that can read files from `../data/`
4. LangChain4J's `AiServices` creates a proxy that handles the tool-calling loop:
   - User asks a question
   - LLM decides to call `readFile("company-faq.txt")` or `readFile("product-docs.txt")`
   - Tool returns file contents
   - LLM synthesizes a cited answer
5. Prints the answer with source citations

## Data Files

Located in `../data/` (shared across Python, TypeScript, and Java implementations):

| File | Contents |
|------|----------|
| `company-faq.txt` | TechVista company background, leadership, policies |
| `product-docs.txt` | CodeLens product docs, features, pricing, API |
