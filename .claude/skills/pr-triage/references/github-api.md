# GitHub API Reference

## Authentication

All calls use `gh api` which handles authentication via `gh auth login`.

## REST Endpoints

### PR Metadata

```bash
gh pr view <number> --json title,state,author,baseRefName,headRefName,additions,deletions,changedFiles,url
```

### Issue Comments (top-level PR conversation)

```
GET /repos/{owner}/{repo}/issues/{number}/comments
```

- Paginated: `?per_page=100&page=N`
- Returns: `id`, `body`, `user`, `created_at`, `updated_at`, `html_url`
- These are conversation-level comments, not inline code reviews.

### Review Comments (inline code review)

```
GET /repos/{owner}/{repo}/pulls/{number}/comments
```

- Paginated: `?per_page=100&page=N`
- Returns: `id`, `body`, `user`, `path`, `line`, `side`, `diff_hunk`, `created_at`, `html_url`, `in_reply_to_id`
- `in_reply_to_id` links replies to their parent comment.

### Reply to Review Comment

```
POST /repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies
```

- Body: `{ "body": "reply text" }`
- Posts a reply in the review thread.

### Reply to Issue Comment

```
POST /repos/{owner}/{repo}/issues/{number}/comments
```

- Body: `{ "body": "reply text" }`
- Posts a new top-level comment on the PR conversation.

## GraphQL Endpoints

### Review Threads

```graphql
query($owner: String!, $name: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          resolvedBy { login }
          comments(first: 100) {
            nodes {
              id
              databaseId
              body
              author { login }
              createdAt
              url
            }
          }
        }
      }
    }
  }
}
```

- `id` — GraphQL node ID (e.g., `PRRT_kwDOABC123`). Used for `resolveReviewThread` mutation.
- `databaseId` on comments — numeric REST ID. Used for reply-to-comment via REST.
- Cursor-paginated: check `pageInfo.hasNextPage`, pass `endCursor` as `$cursor`.

### Resolve Thread Mutation

```graphql
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) {
    thread {
      id
      isResolved
      resolvedBy { login }
    }
  }
}
```

- `threadId` must be the GraphQL node ID (`PRRT_...`), not a numeric ID.

## Rate Limiting

- REST: 5000 requests/hour for authenticated users. Check `X-RateLimit-Remaining` header.
- GraphQL: 5000 points/hour. Each query costs 1 point + 1 per 100 nodes.
- Detection: HTTP 403 with `X-RateLimit-Remaining: 0`, or GraphQL response containing `"type": "RATE_LIMITED"`.
- Recovery: scripts should return partial data with a warning, not hard-exit.

## Pagination Patterns

### REST

```bash
PAGE=1
while true; do
  RESPONSE=$(gh api "/repos/$OWNER/$REPO/..." --paginate 2>&1) || break
  COUNT=$(echo "$RESPONSE" | jq 'length')
  [[ "$COUNT" -lt 100 ]] && break
  PAGE=$((PAGE + 1))
done
```

Note: `gh api --paginate` handles REST pagination automatically. Prefer it when possible.

### GraphQL

```bash
CURSOR=""
while true; do
  RESPONSE=$(gh api graphql -f query="..." -f cursor="$CURSOR" 2>&1) || break
  HAS_NEXT=$(echo "$RESPONSE" | jq -r '.data...pageInfo.hasNextPage')
  [[ "$HAS_NEXT" != "true" ]] && break
  CURSOR=$(echo "$RESPONSE" | jq -r '.data...pageInfo.endCursor')
done
```
